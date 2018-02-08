import UIKit
import WMF

fileprivate let headerReuseIdentifier = "org.wikimedia.history_header"

@objc(WMFHistoryViewController)
class HistoryViewController: ArticleFetchedResultsViewController {
    var headerLayoutEstimate: WMFLayoutEstimate?

    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(key: "viewedDateWithoutTime", ascending: false), NSSortDescriptor(key: "viewedDate", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "viewedDateWithoutTime", cacheName: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.historyTabTitle
        register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, addPlaceholder: true)
        
        deleteAllButtonText = WMFLocalizedString("history-clear-all", value: "Clear", comment: "Text of the button shown at the top of history which deletes all history\n{{Identical|Clear}}")
        deleteAllConfirmationText =  WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
        deleteAllCancelText = WMFLocalizedString("history-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action\n{{Identical|Cancel}}")
        deleteAllText = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")
        isDeleteAllVisible = true
    }
    
    override var analyticsName: String {
        return "Recent"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())

    
    
    
    
    
    
        // EnableReadingListSyncPanelViewController
        // EnableLocationPanelViewController
        // AddSavedArticlesToReadingListPanelViewController
        // LoginToSyncSavedArticlesToReadingListPanelViewController
        // KeepSavedArticlesOnDevicePanelViewController
        let panelVC = EnableLocationPanelViewController(showCloseButton: true, primaryButtonTapHandler: { sender in
            print("PRIMARY")
            sender.dismiss(animated: true, completion: nil)
        }, secondaryButtonTapHandler: { sender in
            print("SECONDARY")
            sender.dismiss(animated: true, completion: nil)
        }, dismissHandler: { sender in
            print("CLOSE")
        })
        
        panelVC.apply(theme: theme)
        
        present(panelVC, animated: true, completion: nil)
        
        // wmf_showEnableReadingListSyncPanelOnce(theme: theme)

    
    
    
    
    
    
    
    
    
    }
    
    override var emptyViewType: WMFEmptyViewType {
        return .noHistory
    }
    
    override func deleteAll() {
        dataStore.historyList.removeAllEntries()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerLayoutEstimate = nil
    }

    func titleForHeaderInSection(_ section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return nil
        }
        let sectionInfo = sections[section]
        guard let article = sectionInfo.objects?.first as? WMFArticle, let date = article.viewedDateWithoutTime else {
            return nil
        }
        
        return ((date as NSDate).wmf_midnightUTCDateFromLocal as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath)
        guard let headerView = view as? CollectionViewHeader else {
            return view
        }
        headerView.text = titleForHeaderInSection(indexPath.section)
        headerView.apply(theme: theme)
        headerView.layoutMargins = layout.readableMargins
        return headerView
    }

    override func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        super.collectionViewUpdater(updater, didUpdate: collectionView)
        updateVisibleHeaders()
    }

    func updateVisibleHeaders() {
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionHeader) {
            guard let headerView = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: indexPath) as? CollectionViewHeader else {
                continue
            }
            headerView.text = titleForHeaderInSection(indexPath.section)
        }
    }

}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension HistoryViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        if let estimate = headerLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 67)
        guard let placeholder = placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier) as? CollectionViewHeader else {
            return estimate
        }
        let title = titleForHeaderInSection(section)
        placeholder.prepareForReuse()
        placeholder.text = title
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric)).height
        estimate.precalculated = true
        headerLayoutEstimate = estimate
        return estimate
    }
}
