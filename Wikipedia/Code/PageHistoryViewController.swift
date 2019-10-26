import UIKit
import WMF

@objc(WMFPageHistoryViewControllerDelegate)
protocol PageHistoryViewControllerDelegate: AnyObject {
    func pageHistoryViewControllerDidDisappear(_ pageHistoryViewController: PageHistoryViewController)
}

typealias PageHistoryCollectionViewCellSelectionThemeModel = PageHistoryViewController.SelectionThemeModel

@objc(WMFPageHistoryViewController)
class PageHistoryViewController: ColumnarCollectionViewController {
    private let pageTitle: String
    private let pageURL: URL

    private let pageHistoryFetcher = PageHistoryFetcher()
    private var pageHistoryFetcherParams: PageHistoryRequestParameters

    private var batchComplete = false
    private var isLoadingData = false

    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?

    var shouldLoadNewData: Bool {
        if batchComplete || isLoadingData {
            return false
        }
        let maxY = collectionView.contentOffset.y + collectionView.frame.size.height + 200.0;
        if (maxY >= collectionView.contentSize.height) {
            return true
        }
        return false;
    }

    @objc public weak var delegate: PageHistoryViewControllerDelegate?

    private lazy var countsViewController = PageHistoryCountsViewController(pageTitle: pageTitle, locale: NSLocale.wmf_locale(for: pageURL.wmf_language))

    @objc init(pageTitle: String, pageURL: URL) {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
        self.pageHistoryFetcherParams = PageHistoryRequestParameters(title: pageTitle)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pageHistorySections: [PageHistorySection] = []

    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }

    private lazy var compareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.compareTitle, style: .plain, target: self, action: #selector(compare(_:)))
        button.accessibilityHint = WMFLocalizedString("page-history-compare-accessibility-hint", value: "Tap to select two revisions to compare", comment: "Accessibility hint describing the role of the Compare button")
        return button
    }()

    private lazy var cancelComparisonButton = UIBarButtonItem(title: CommonStrings.cancelActionTitle, style: .done, target: self, action: #selector(cancelComparison(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        hintController = PageHistoryHintController()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("article-title", value: "Article", comment: "Generic article title"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = compareButton
        title = CommonStrings.historyTabTitle

        addChild(countsViewController)
        navigationBar.addUnderNavigationBarView(countsViewController.view)
        navigationBar.shadowColorKeyPath = \Theme.colors.border
        countsViewController.didMove(toParent: self)


        navigationBar.isUnderBarViewHidingEnabled = true

        layoutManager.register(PageHistoryCollectionViewCell.self, forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier, addPlaceholder: true)
        collectionView.dataSource = self
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

        apply(theme: theme)

        // TODO: Move networking

        pageHistoryFetcher.fetchPageCreationDate(for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let firstEditDate):
                self.pageHistoryFetcher.fetchEditCounts(.edits, for: self.pageTitle, pageURL: self.pageURL) { result in
                    switch result {
                    case .failure(let error):
                        // TODO: Handle error
                        print(error)
                    case .success(let editCounts):
                        if case let totalEditCount?? = editCounts[.edits] {
                            DispatchQueue.main.async {
                                self.countsViewController.set(totalEditCount: totalEditCount, firstEditDate: firstEditDate)
                            }
                        }
                    }
                }
            }
        }

        pageHistoryFetcher.fetchEditCounts(.edits, .anonEdits, .botEdits, .revertedEdits, for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let editCountsGroupedByType):
                DispatchQueue.main.async {
                    self.countsViewController.editCountsGroupedByType = editCountsGroupedByType
                }
            }
        }

        pageHistoryFetcher.fetchEditMetrics(for: pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
                self.countsViewController.timeseriesOfEditsCounts = []
            case .success(let timeseriesOfEditCounts):
                DispatchQueue.main.async {
                    self.countsViewController.timeseriesOfEditsCounts = timeseriesOfEditCounts
                }
            }
        }

        getPageHistory()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelComparison(nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.pageHistoryViewControllerDidDisappear(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }

    private func getPageHistory() {
        isLoadingData = true

        pageHistoryFetcher.fetchRevisionInfo(pageURL, requestParams: pageHistoryFetcherParams, failure: { error in
            print(error)
            self.isLoadingData = false
        }) { results in
            self.pageHistorySections.append(contentsOf: results.items())
            self.pageHistoryFetcherParams = results.getPageHistoryRequestParameters(self.pageURL)
            self.batchComplete = results.batchComplete()
            self.isLoadingData = false
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard shouldLoadNewData else {
            return
        }
        getPageHistory()
    }

    private enum State {
        case idle
        case editing
    }

    private var maxNumberOfRevisionsSelected: Bool {
        assert((0...2).contains(selectedCellsCount))
        return selectedCellsCount == 2
    }
    private var selectedCellsCount = 0

    private var pageHistoryHintController: PageHistoryHintController? {
        return hintController as? PageHistoryHintController
    }

    private var state: State = .idle {
        didSet {
            switch state {
            case .idle:
                selectedCellsCount = 0
                pageHistoryHintController?.hide(true, presenter: self, theme: theme)
                openSelectionIndex = 0

                NSLayoutConstraint.deactivate(comparisonSelectionButtonWidthConstraints)
                navigationItem.rightBarButtonItem = compareButton

                indexPathsSelectedForComparison.removeAll(keepingCapacity: true)
                forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                    self.updateSelectionThemeModel(nil, for: cell, at: indexPath)
                    self.updateSelectionIndex(nil, for: cell, at: indexPath)
                    cell.enableEditing(true) // confusing, have a reset method
                    cell.setEditing(false)
                    cell.apply(theme: self.theme)
                }

                resetComparisonSelectionButtons()
                navigationController?.setToolbarHidden(true, animated: true)
            case .editing:
                navigationItem.rightBarButtonItem = cancelComparisonButton
                collectionView.allowsMultipleSelection = true
                forEachVisibleCell { $1.setEditing(true, animated: true) }
                compareToolbarButton.isEnabled = false
                comparisonSelectionButtonWidthConstraints = [firstComparisonSelectionButton.widthAnchor.constraint(equalToConstant: 90), secondComparisonSelectionButton.widthAnchor.constraint(equalToConstant: 90)]
                NSLayoutConstraint.activate(comparisonSelectionButtonWidthConstraints)
                setToolbarItems([UIBarButtonItem(customView: firstComparisonSelectionButton), UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 10), UIBarButtonItem(customView: secondComparisonSelectionButton), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),  compareToolbarButton], animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
            }
            layoutCache.reset()
            layout.invalidateLayout(with: layout.invalidationContextForDataChange())
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        }
    }

    private lazy var compareToolbarButton = UIBarButtonItem(title: CommonStrings.compareTitle, style: .plain, target: self, action: #selector(tappedCompare(_:)))
    private lazy var firstComparisonSelectionButton: AlignedImageButton = {
        let button = makeComparisonSelectionButton()
        button.tag = 0
        return button
    }()
    private lazy var secondComparisonSelectionButton: AlignedImageButton = {
        let button = makeComparisonSelectionButton()
        button.tag = 1
        return button
    }()
    private var comparisonSelectionButtonWidthConstraints = [NSLayoutConstraint]()

    private func makeComparisonSelectionButton() -> AlignedImageButton {
        let button = AlignedImageButton(frame: .zero)
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = theme.colors.paperBackground
        button.imageView?.tintColor = theme.colors.link
        button.setTitleColor(theme.colors.link, for: .normal)
        button.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        button.horizontalSpacing = 10
        button.contentHorizontalAlignment = .leading
        button.leftPadding = 10
        button.rightPadding = 10
        button.addTarget(self, action: #selector(scrollToComparisonSelection(_:)), for: .touchUpInside)
        return button
    }

    @objc private func compare(_ sender: UIBarButtonItem) {
        state = .editing
    }

    private func forEachVisibleCell(_ block: (IndexPath, PageHistoryCollectionViewCell) -> Void) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let pageHistoryCollectionViewCell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
                continue
            }
            block(indexPath, pageHistoryCollectionViewCell)
        }
    }

    @objc private func cancelComparison(_ sender: UIBarButtonItem?) {
        state = .idle
    }

    private func resetComparisonSelectionButtons() {
        firstComparisonSelectionButton.setTitle(nil, for: .normal)
        firstComparisonSelectionButton.setImage(nil, for: .normal)
        secondComparisonSelectionButton.setTitle(nil, for: .normal)
        secondComparisonSelectionButton.setImage(nil, for: .normal)
        firstComparisonSelectionButton.backgroundColor = theme.colors.paperBackground
        secondComparisonSelectionButton.backgroundColor = theme.colors.paperBackground
    }

    @objc private func tappedCompare(_ sender: UIBarButtonItem) {
        guard let firstIndexPath = indexPathsSelectedForComparison[0], let secondIndexPath = indexPathsSelectedForComparison[1] else {
            return
        }
        let fromRevision = pageHistorySections[firstIndexPath.section].items[firstIndexPath.item]
        let toRevision = pageHistorySections[secondIndexPath.section].items[secondIndexPath.item]
        
        //tonitodo: remove intermediate counts here and fetch from diff screen
        showDiff(from: fromRevision, to: toRevision, type: .compare(articleTitle: pageTitle, numberOfIntermediateRevisions: 5, numberOfIntermediateUsers: 3))
    }
    
    private func showDiff(from: WMFPageHistoryRevision, to: WMFPageHistoryRevision, type: DiffContainerViewModel.DiffType) {
        
        if let siteURL = pageURL.wmf_site {
            let diffContainerVC = DiffContainerViewController(articleTitle: pageTitle, siteURL: siteURL, type: type, fromModel: from, toModel: to, theme: theme)
            wmf_push(diffContainerVC, animated: true)
        }
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationItem.leftBarButtonItem?.tintColor = theme.colors.primaryText
        countsViewController.apply(theme: theme)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.tintColor = theme.colors.midBackground
        navigationController?.toolbar.barTintColor = theme.colors.midBackground
        compareToolbarButton.tintColor = theme.colors.link
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pageHistorySections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageHistorySections[section].items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageHistoryCollectionViewCell.identifier, for: indexPath) as? PageHistoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        configure(cell: cell, at: indexPath)
        return cell
    }

    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        let section = pageHistorySections[sectionIndex]
        let sectionTitle: String?

        if sectionIndex == 0, let date = section.items.first?.revisionDate {
            sectionTitle = (date as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
        } else {
            sectionTitle = section.sectionTitle
        }
        header.style = .pageHistory
        header.title = sectionTitle
        header.titleTextColorKeyPath = \Theme.colors.secondaryText
        header.layoutMargins = .zero
        header.apply(theme: theme)
    }

    // MARK: Layout

    // Reset on refresh
    private var cellContentCache = NSCache<NSNumber, CellContent>()

    private class CellContent: NSObject {
        let time: String?
        let displayTime: String?
        let author: String?
        let authorImage: UIImage?
        let sizeDiff: Int?
        let comment: String?
        var selectionThemeModel: SelectionThemeModel?
        var selectionIndex: Int?

        init(time: String?, displayTime: String?, author: String?, authorImage: UIImage?, sizeDiff: Int?, comment: String?, selectionThemeModel: SelectionThemeModel?, selectionIndex: Int?) {
            self.time = time
            self.displayTime = displayTime
            self.author = author
            self.authorImage = authorImage
            self.sizeDiff = sizeDiff
            self.comment = comment
            self.selectionThemeModel = selectionThemeModel
            self.selectionIndex = selectionIndex
            super.init()
        }
    }

    private func configure(cell: PageHistoryCollectionViewCell, for item: WMFPageHistoryRevision? = nil, at indexPath: IndexPath) {
        let item = item ?? pageHistorySections[indexPath.section].items[indexPath.item]
        let revisionID = NSNumber(value: item.revisionID)
        defer {
            cell.setEditing(state == .editing, animated: false)
            cell.enableEditing(!maxNumberOfRevisionsSelected, animated: false)
            cell.apply(theme: theme)
        }
        if let cachedCellContent = cellContentCache.object(forKey: revisionID) {
            cell.time = cachedCellContent.time
            cell.displayTime = cachedCellContent.displayTime
            cell.authorImage = cachedCellContent.authorImage
            cell.author = cachedCellContent.author
            cell.sizeDiff = cachedCellContent.sizeDiff
            cell.comment = cachedCellContent.comment
            if state == .editing {
                if cachedCellContent.selectionIndex != nil {
                    cell.isSelected = true
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
                if cell.isSelected {
                    cell.selectionThemeModel = cachedCellContent.selectionThemeModel
                } else {
                    cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
                }
                cell.selectionIndex = cachedCellContent.selectionIndex
            } else {
                cell.selectionIndex = nil
                cell.selectionThemeModel = nil
            }
        } else {
            if let date = item.revisionDate {
                if indexPath.section == 0, (date as NSDate).wmf_isTodayUTC() {
                    let dateStrings = (date as NSDate).wmf_localizedRelativeDateStringFromLocalDateToNowAbbreviated()
                    cell.time = dateStrings[WMFAbbreviatedRelativeDate]
                    cell.displayTime = dateStrings[WMFAbbreviatedRelativeDateAgo]
                } else {
                    cell.time = DateFormatter.wmf_24hshortTime()?.string(from: date)
                    cell.displayTime = DateFormatter.wmf_24hshortTimeWithUTCTimeZone()?.string(from: date)
                }
            }
            cell.authorImage = item.isAnon ? UIImage(named: "anon") : UIImage(named: "user-edit")
            cell.author = item.user
            cell.sizeDiff = item.revisionSize
            cell.comment = item.parsedComment?.removingHTML
            if !cell.isSelected {
                cell.selectionThemeModel = maxNumberOfRevisionsSelected ? disabledSelectionThemeModel : nil
            }
        }

        cell.layoutMargins = layout.itemLayoutMargins

        cellContentCache.setObject(CellContent(time: cell.time, displayTime: cell.displayTime, author: cell.author, authorImage: cell.authorImage, sizeDiff: cell.sizeDiff, comment: cell.comment, selectionThemeModel: cell.selectionThemeModel, selectionIndex: cell.selectionIndex), forKey: revisionID)

        cell.apply(theme: theme)
    }

    private func revisionID(forItemAtIndexPath indexPath: IndexPath) -> NSNumber {
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        return NSNumber(value: item.revisionID)
    }

    override func contentSizeCategoryDidChange(_ notification: Notification?) {
        layoutCache.reset()
        super.contentSizeCategoryDidChange(notification)
    }

    private func updateSelectionThemeModel(_ selectionThemeModel: SelectionThemeModel?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionThemeModel = selectionThemeModel
        cellContentCache.object(forKey: revisionID(forItemAtIndexPath: indexPath))?.selectionThemeModel = selectionThemeModel
    }

    private func updateSelectionIndex(_ selectionIndex: Int?, for cell: PageHistoryCollectionViewCell, at indexPath: IndexPath) {
        cell.selectionIndex = selectionIndex
        cellContentCache.object(forKey: revisionID(forItemAtIndexPath: indexPath))?.selectionIndex = selectionIndex
    }

    public class SelectionThemeModel {
        let selectedImage: UIImage?
        let borderColor: UIColor
        let backgroundColor: UIColor
        let authorColor: UIColor
        let commentColor: UIColor
        let timeColor: UIColor
        let sizeDiffAdditionColor: UIColor
        let sizeDiffSubtractionColor: UIColor
        let sizeDiffNoDifferenceColor: UIColor

        init(selectedImage: UIImage?, borderColor: UIColor, backgroundColor: UIColor, authorColor: UIColor, commentColor: UIColor, timeColor: UIColor, sizeDiffAdditionColor: UIColor, sizeDiffSubtractionColor: UIColor, sizeDiffNoDifferenceColor: UIColor) {
            self.selectedImage = selectedImage
            self.borderColor = borderColor
            self.backgroundColor = backgroundColor
            self.authorColor = authorColor
            self.commentColor = commentColor
            self.timeColor = timeColor
            self.sizeDiffAdditionColor = sizeDiffAdditionColor
            self.sizeDiffSubtractionColor = sizeDiffSubtractionColor
            self.sizeDiffNoDifferenceColor = sizeDiffNoDifferenceColor
        }
    }

    private lazy var firstSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: UIImage(named: "selected-accent"), borderColor: UIColor.osage, backgroundColor: UIColor("FEF9E7"), authorColor: UIColor.osage, commentColor: .abbey, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var secondSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.link.withAlphaComponent(0.3), backgroundColor: UIColor.lightBlue, authorColor: theme.colors.link, commentColor: .abbey, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.accent, sizeDiffSubtractionColor: theme.colors.destructive, sizeDiffNoDifferenceColor: theme.colors.link)
    }()

    private lazy var disabledSelectionThemeModel: SelectionThemeModel = {
        return SelectionThemeModel(selectedImage: nil, borderColor: theme.colors.border, backgroundColor: theme.colors.paperBackground, authorColor: theme.colors.secondaryText, commentColor: theme.colors.secondaryText, timeColor: .battleshipGray, sizeDiffAdditionColor: theme.colors.secondaryText, sizeDiffSubtractionColor: theme.colors.secondaryText, sizeDiffNoDifferenceColor: theme.colors.secondaryText)
    }()

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let identifier = PageHistoryCollectionViewCell.identifier
        let item = pageHistorySections[indexPath.section].items[indexPath.item]
        let userInfo = "phc-cell-\(item.revisionID)"
        if let cachedHeight = layoutCache.cachedHeightForCellWithIdentifier(identifier, columnWidth: columnWidth, userInfo: userInfo) {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: cachedHeight)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 80)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier) as? PageHistoryCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, for: item, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: identifier, columnWidth: columnWidth, userInfo: userInfo)
        return estimate
    }

    override func metrics(with boundsSize: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: boundsSize, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 0, interItemSpacing: 20)
    }

    private var postedMaxRevisionsSelectedAccessibilityNotification = false

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        switch state {
        case .editing:
            if maxNumberOfRevisionsSelected {
                pageHistoryHintController?.hide(false, presenter: self, theme: theme)
                if !postedMaxRevisionsSelectedAccessibilityNotification {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.maxRevisionsSelectedWarningTitle)
                    postedMaxRevisionsSelectedAccessibilityNotification = true
                }
                return false
            } else {
                return true
            }
        case .idle:
            return true
        }
    }
    
    private func pushToSingleRevisionDiff(indexPath: IndexPath) {
        
        guard let section = pageHistorySections[safeIndex: indexPath.section] else {
            return
        }
        
        if let toRevision = section.items[safeIndex: indexPath.item] {

            var sectionOffset = 0
            var fromItemIndex = indexPath.item + 1
            //if last revision in section, go to next section for selecting second
            let isLastInSection = indexPath.item == section.items.count - 1
            
            if isLastInSection {
                sectionOffset = 1
                fromItemIndex = 0
            }
            
            guard let fromRevision = pageHistorySections[safeIndex: indexPath.section + sectionOffset]?.items[safeIndex: fromItemIndex] else {
                //maybe they selected the first item in history?
                return
            }
            
            showDiff(from: fromRevision, to: toRevision, type: .single(byteDifference: toRevision.revisionSize))
        }
    }

    var openSelectionIndex = 0

    private var indexPathsSelectedForComparison = [Int: IndexPath]()

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if state == .editing {
            selectedCellsCount += 1

            defer {
                compareToolbarButton.isEnabled = maxNumberOfRevisionsSelected
            }

            guard let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell else {
                return
            }

            let button: UIButton?
            let themeModel: SelectionThemeModel?
            if maxNumberOfRevisionsSelected {
                forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                    if !cell.isSelected {
                        self.updateSelectionThemeModel(self.disabledSelectionThemeModel, for: cell, at: indexPath)
                    }
                    cell.enableEditing(false)
                }
            }
            switch openSelectionIndex {
            case 0:
                button = firstComparisonSelectionButton
                themeModel = firstSelectionThemeModel
            case 1:
                button = secondComparisonSelectionButton
                themeModel = secondSelectionThemeModel
            default:
                button = nil
                themeModel = nil
            }
            if let button = button, let themeModel = themeModel {
                button.backgroundColor = themeModel.backgroundColor
                button.setImage(cell.authorImage, for: .normal)
                button.setTitle(cell.time, for: .normal)
                button.imageView?.tintColor = themeModel.authorColor
                button.setTitleColor(themeModel.authorColor, for: .normal)
                button.tintColor = themeModel.authorColor
                indexPathsSelectedForComparison[button.tag] = indexPath
            }
            updateSelectionIndex(openSelectionIndex, for: cell, at: indexPath)
            updateSelectionThemeModel(themeModel, for: cell, at: indexPath)
            cell.apply(theme: theme)

            openSelectionIndex += 1

            collectionView.reloadData()
        } else {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.isSelected = false
            pushToSingleRevisionDiff(indexPath: indexPath)
        }
    }

    @objc private func scrollToComparisonSelection(_ sender: UIButton) {
        guard let indexPath = indexPathsSelectedForComparison[sender.tag] else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedCellsCount -= 1
        pageHistoryHintController?.hide(true, presenter: self, theme: theme)

        if let cell = collectionView.cellForItem(at: indexPath) as? PageHistoryCollectionViewCell, let selectionIndex = cell.selectionIndex {
            indexPathsSelectedForComparison.removeValue(forKey: selectionIndex)
            openSelectionIndex = selectionIndex

            forEachVisibleCell { (indexPath: IndexPath, cell: PageHistoryCollectionViewCell) in
                if !cell.isSelected {
                    self.updateSelectionThemeModel(nil, for: cell, at: indexPath)
                    cell.enableEditing(true, animated: false)
                }
            }
            let button: UIButton?
            switch selectionIndex {
            case 0:
                button = firstComparisonSelectionButton
            case 1:
                button = secondComparisonSelectionButton
            default:
                button = nil
            }
            button?.backgroundColor = theme.colors.paperBackground
            button?.setImage(nil, for: .normal)
            button?.setTitle(nil, for: .normal)
            updateSelectionIndex(nil, for: cell, at: indexPath)
            updateSelectionThemeModel(nil, for: cell, at: indexPath)
            cell.apply(theme: theme)
            collectionView.reloadData()
        }
        compareToolbarButton.isEnabled = collectionView.indexPathsForSelectedItems?.count ?? 0 == 2
    }
}