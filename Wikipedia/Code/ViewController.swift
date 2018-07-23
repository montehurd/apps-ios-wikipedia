import UIKit
import WMF

class ViewController: PreviewingViewController, Themeable, NavigationBarHiderDelegate {
    var theme: Theme = Theme.standard
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // keep objc until WMFAppViewController is rewritten in Swift
    // it checks at run time for VCs that respond to navigationBar
    @objc lazy var navigationBar: NavigationBar = {
        return NavigationBar()
    }()
    
    lazy var navigationBarHider: NavigationBarHider = {
        return NavigationBarHider()
    }()

    var keyboardFrame: CGRect?
    open var showsNavigationBar: Bool = false
    var ownsNavigationBar: Bool = true
    
    public enum NavigationMode {
        case bar
        case detail
    }
    
    var navigationMode: NavigationMode = .bar {
        didSet {
            switch navigationMode {
            case .detail:
                showsNavigationBar = false
                ownsNavigationBar = false
                hidesBottomBarWhenPushed = true
                addCloseButton()
                addScrollToTopButton()
            default:
                hidesBottomBarWhenPushed = false
                removeCloseButton()
                removeScrollToTopButton()
                break
            }
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK - Close Button
    
    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }
    
    private var closeButton: UIButton?
   
    private func addCloseButton() {
        guard closeButton == nil else {
            return
        }
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "close-inverse"), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        view.addSubview(button)
        let height = button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        let width = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 32)
        button.addConstraints([height, width])
        let top = button.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
        let trailing = button.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        view.addConstraints([top, trailing])
        closeButton = button
        applyThemeToCloseButton()
    }
    
    private func applyThemeToCloseButton() {
        closeButton?.tintColor = theme.colors.tertiaryText
    }
    
    private func removeCloseButton() {
        guard closeButton != nil else {
            return
        }
        closeButton?.removeFromSuperview()
        closeButton = nil
    }
    
    private var scrollToTopButton: UIButton?
    
    private func addScrollToTopButton() {
        guard scrollToTopButton == nil else {
            return
        }
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
        view.addSubview(button)
        let top = button.topAnchor.constraint(equalTo: view.topAnchor)
        let bottom = button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
        let leading = button.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        view.addConstraints([top, bottom, leading, trailing])
        button.accessibilityTraits = UIAccessibilityTraitNone
        scrollToTopButton = button
    }
    
    private func removeScrollToTopButton() {
        scrollToTopButton?.removeFromSuperview()
        scrollToTopButton = nil
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationMode == .detail
    }
    
    open var scrollView: UIScrollView? {
        didSet {
            updateScrollViewInsets()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        apply(theme: theme)
        automaticallyAdjustsScrollViewInsets = false
        if #available(iOS 11.0, *) {
            scrollView?.contentInsetAdjustmentBehavior = .never
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil, using: { [weak self] notification in
            if let window = self?.view.window, let endFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                let windowFrame = window.convert(endFrame, from: nil)
                self?.keyboardFrame = window.convert(windowFrame, to: self?.view)
            }
            self?.updateScrollViewInsets()
        })
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardDidHide, object: nil, queue: nil, using: { [weak self] notification in
            self?.keyboardFrame = nil
            self?.updateScrollViewInsets()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard navigationMode == .bar else {
            return
        }
        
        if let parentVC = parent as? ViewController {
            showsNavigationBar = true
            ownsNavigationBar = false
            navigationBar = parentVC.navigationBar
        }  else if let navigationController = navigationController {
            ownsNavigationBar = true
            showsNavigationBar = parent == navigationController && navigationController.isNavigationBarHidden
            navigationBar.updateNavigationItems()
        } else {
            showsNavigationBar = false
        }
    
        navigationBarHider.navigationBar = navigationBar
        navigationBarHider.delegate = self
        
        guard ownsNavigationBar else {
            return
        }

        if showsNavigationBar {
            if navigationBar.superview == nil {

                navigationBar.delegate = self
                navigationBar.translatesAutoresizingMaskIntoConstraints = false

                view.addSubview(navigationBar)
                let navTopConstraint = view.topAnchor.constraint(equalTo: navigationBar.topAnchor)
                let navLeadingConstraint = view.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor)
                let navTrailingConstraint = view.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor)
                view.addConstraints([navTopConstraint, navLeadingConstraint, navTrailingConstraint])
            }
            
            navigationBar.navigationBarPercentHidden = 0
            if navigationBar.shouldTransformUnderBarViewWithBar {
                navigationBar.underBarViewPercentHidden = 0
            }
            updateNavigationBarStatusBarHeight()
        } else {
            if navigationBar.superview != nil {
                navigationBar.removeFromSuperview()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewInsets()
    }
    
    // MARK - Scroll View Insets
    
    fileprivate func updateNavigationBarStatusBarHeight() {
        guard showsNavigationBar else {
            return
        }
        
        if #available(iOS 11.0, *) {
        } else {
            let newHeight = navigationController?.topLayoutGuide.length ?? topLayoutGuide.length
            if newHeight != navigationBar.statusBarHeight {
                navigationBar.statusBarHeight = newHeight
                view.setNeedsLayout()
            }
        }
        
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
        }
        self.updateScrollViewInsets()
    }
    
    var useNavigationBarVisibleHeightForScrollViewInsets: Bool = false
    
    public final func updateScrollViewInsets() {
        guard let scrollView = scrollView, !automaticallyAdjustsScrollViewInsets else {
            return
        }
        
        var top: CGFloat
        if showsNavigationBar {
            if useNavigationBarVisibleHeightForScrollViewInsets {
                top = navigationBar.visibleHeight
            } else {
                top = navigationBar.frame.maxY
            }
        } else if let navigationController = navigationController {
            let navBarMaxY = navigationController.view.convert(navigationController.navigationBar.frame, to: view).maxY
            top = max(navBarMaxY, view.layoutMargins.top)
        } else {
            top = view.layoutMargins.top
        }
        
        var safeInsets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: min(44, bottomLayoutGuide.length), right: 0) // MIN 44 is a workaround for an iOS 10 only issue where the bottom layout guide is too tall when pushing from explore
        }
        
        var bottom = safeInsets.bottom
        if let keyboardFrame = keyboardFrame {
            let adjustedKeyboardFrame = view.convert(keyboardFrame, to: scrollView)
            let keyboardIntersection = adjustedKeyboardFrame.intersection(scrollView.bounds)
            bottom = max(bottom, keyboardIntersection.height)
        }
        
        let scrollIndicatorInsets = UIEdgeInsets(top: top, left: safeInsets.left, bottom: bottom, right: safeInsets.right)
        if let rc = scrollView.refreshControl, rc.isRefreshing {
            top += rc.frame.height
        }
        let contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        if scrollView.wmf_setContentInsetPreservingTopAndBottomOffset(contentInset, scrollIndicatorInsets: scrollIndicatorInsets, withNavigationBar: navigationBar) {
            scrollViewInsetsDidChange()
        }
    }

    open func scrollViewInsetsDidChange() {
        if showsNavigationBar && ownsNavigationBar {
            for child in childViewControllers {
                guard let vc = child as? ViewController, !vc.ownsNavigationBar else {
                    continue
                }
                vc.scrollViewInsetsDidChange()
            }
        }
    }
    
    // MARK: - Scrolling
    
    @objc func scrollToTop() {
        guard let scrollView = scrollView else {
            return
        }
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0 - scrollView.contentInset.top), animated: true)
    }
    
    // MARK: - WMFNavigationBarHiderDelegate
    
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool) {
        //
    }

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        navigationBar.apply(theme: theme)
        applyThemeToCloseButton()
    }
}


extension ViewController: WMFEmptyViewContainer {
    func addEmpty(_ emptyView: UIView) {
        if navigationBar.superview === view {
            view.insertSubview(emptyView, belowSubview: navigationBar)
        } else {
            view.addSubview(emptyView)
        }
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        navigationBarHider.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    #if UI_TEST
    // Needed because XCUIApplication's `pressforDuration:thenDragTo:` method causes inertial scrolling if the
    // distance scrolled exceeds a certain amount. When we use `pressforDuration:thenDragTo:` to scroll an
    // element to the top of the screen this can be problematic because the extra inertia can cause the element
    // to be scrolled beyond the top of the screen.
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }
    #endif
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidEndScrollingAnimation(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        navigationBarHider.scrollViewWillScrollToTop(scrollView)
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        navigationBarHider.scrollViewDidScrollToTop(scrollView)
    }
}
