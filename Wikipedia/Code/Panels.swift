
class EnableReadingListSyncPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-syncing")
        heading = WMFLocalizedString("reading-list-sync-enable-title", value:"Turn on reading list syncing?", comment:"Title describing reading list syncing.")
        subheading = WMFLocalizedString("reading-list-sync-enable-subtitle", value:"Your saved articles and reading lists can now be saved to your Wikipedia account and synced across devices.", comment:"Subtitle describing reading list syncing.")
        primaryButtonTitle = WMFLocalizedString("reading-list-sync-enable-button-title", value:"Enable syncing", comment:"Title for button enabling reading list syncing.")
    }
}

extension UIViewController {
    @objc func wmf_showEnableReadingListSyncPanelOnce(theme: Theme) {
        guard !UserDefaults.wmf_userDefaults().wmf_didShowEnableReadingListSyncPanel() else {
            return
        }
        let panelVC = EnableReadingListSyncPanelViewController(showCloseButton: true, primaryButtonTapHandler: { sender in
            SessionSingleton.sharedInstance().dataStore.readingListsController.isSyncEnabled = true
            sender.dismiss(animated: true, completion: nil)
        }, secondaryButtonTapHandler: nil, dismissHandler:nil)
        panelVC.apply(theme: theme)
        present(panelVC, animated: true, completion: {
            UserDefaults.wmf_userDefaults().wmf_setDidShowEnableReadingListSyncPanel(true)
        })
    }
}

class AddSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-add-saved-title", value:"Saved articles found", comment:"Title explaining saved articles were found.")
        subheading = WMFLocalizedString("reading-list-add-saved-subtitle", value:"There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?", comment:"Subtitle explaining that saved articles can be added to reading lists.")
        primaryButtonTitle = WMFLocalizedString("reading-list-add-saved-button-title", value:"Yes, add them to my reading lists", comment:"Title for button to add saved articles to reading list.")
        secondaryButtonTitle = WMFLocalizedString("reading-list-do-not-add-saved-button-title", value:"No, delete articles saved on the app", comment:"Title for button to not add saved articles to reading lists.")
    }
}

class LoginToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-login")
        heading = WMFLocalizedString("reading-list-login-title", value:"Sync your saved articles?", comment:"Title for syncing save articles.")
        subheading = WMFLocalizedString("reading-list-login-subtitle", value:"Log in or create an account to allow your saved articles and reading lists to be synced across devices and saved to your user preferences.", comment:"Subtitle explaining that saved articles and reading lists can be synced across devices.")
        primaryButtonTitle = WMFLocalizedString("reading-list-login-button-title", value:"Log in to sync your saved articles", comment:"Title for button to login to sync saved articles and reading lists.")
    }
}

class KeepSavedArticlesOnDevicePanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-keep-title", value:"Keep saved articles on device?", comment:"Title for keeping save articles on device.")
        subheading = WMFLocalizedString("reading-list-keep-subtitle", value:"There are articles synced to your Wikipedia account. Would you like to keep them on this device after you log out?", comment:"Subtitle asking if synced articles should be kept on device after logout.")
        primaryButtonTitle = WMFLocalizedString("reading-list-keep-button-title", value:"Yes, keep articles on device", comment:"Title for button to keep synced articles on device.")
        secondaryButtonTitle = WMFLocalizedString("reading-list-keep-button-subtitle", value:"No, delete articles from device", comment:"Title for button to remove saved articles from device.")
    }
}

class EnableLocationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage.init(named: "places-auth-arrow")
        heading = CommonStrings.localizedEnableLocationTitle
        primaryButtonTitle = CommonStrings.localizedEnableLocationButtonTitle
//        footer = CommonStrings.localizedEnableLocationDescription
        footer = "\(CommonStrings.localizedEnableLocationDescription) \(CommonStrings.localizedEnableLocationDescription) \(CommonStrings.localizedEnableLocationDescription) \(CommonStrings.localizedEnableLocationDescription) \(CommonStrings.localizedEnableLocationDescription) \(CommonStrings.localizedEnableLocationDescription) "

    }
}
