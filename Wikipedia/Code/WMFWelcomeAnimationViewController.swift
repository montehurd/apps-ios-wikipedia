
class WMFWelcomeAnimationViewController: UIViewController {
    var welcomePageType:WMFWelcomePageType = .intro

    lazy var animationView: WelcomeAnimationView = {
        switch self.welcomePageType {
        case .intro:
            return WelcomeIntroAnimationView()
        case .languages:
            return WelcomeLanguagesAnimationView()
        case .analytics:
            return WelcomeAnalyticsAnimationView()
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        animationView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        // Fix for: http://stackoverflow.com/a/39614714
        view.superview?.layoutIfNeeded()

        animationView.layoutIfNeeded()
        animationView.addAnimationElementsScaledToCurrentFrame()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        animationView.beginAnimations()
    }
}
