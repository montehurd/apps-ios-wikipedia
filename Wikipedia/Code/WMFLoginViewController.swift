
import UIKit

class WMFLoginViewController: UIViewController, UITextFieldDelegate, WMFCaptchaViewControllerDelegate {
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var createAccountButton: UILabel!
    @IBOutlet fileprivate var forgotPasswordButton: UILabel!
    @IBOutlet fileprivate var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var captchaTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet fileprivate var spaceBeneathCaptchaContainer: NSLayoutConstraint!

    @IBOutlet fileprivate var loginContainerView: UIView!
    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?

    fileprivate var captchaViewController: WMFCaptchaViewController?
//    fileprivate var captchaSolution: String?
//    fileprivate var captcha: WMFCaptcha?
    fileprivate let captchaResetter = WMFCaptchaResetter()
    private let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    let tokenFetcher = WMFAuthTokenFetcher()

    func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func doneButtonPushed(_ : UIBarButtonItem) {
        save()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))

        doneButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("main-menu-account-login"), style: .plain, target: self, action: #selector(doneButtonPushed(_:)))
        
        navigationItem.rightBarButtonItem = doneButton
        
        createAccountButton.textColor = UIColor.wmf_blueTint()
        forgotPasswordButton.textColor = UIColor.wmf_blueTint()

        createAccountButton.text = localizedStringForKeyFallingBackOnEnglish("login-account-creation")
        createAccountButton.isUserInteractionEnabled = true
        
        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(createAccountButtonPushed(_:))))

        forgotPasswordButton.text = localizedStringForKeyFallingBackOnEnglish("login-forgot-password")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-password-placeholder-text")

        scrollView.keyboardDismissMode = .interactive

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-login")
        captchaTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")

        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = 1.0 / UIScreen.main.scale
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButtonIfNecessary()
    }
    
    fileprivate func enableProgressiveButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = shouldProgressiveButtonBeEnabled()
    }
    
    fileprivate func disableProgressiveButton() {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {

return true
        
        
        var shouldEnable = areRequiredFieldsPopulated()
if shouldEnable && captchaViewController?.captcha != nil {
    shouldEnable = hasUserEnteredCaptchaText()
}

// 2FA acct: acct_creation_test_002 test1234
        
//        if showCaptchaContainer && shouldEnable {
//            shouldEnable = hasUserEnteredCaptchaText()
//        }
        return shouldEnable
    }
    
fileprivate func hasUserEnteredCaptchaText() -> Bool {
    guard let text = captchaViewController?.solution else {
        return false
    }
    return (text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count > 0)
}

    
    
    
    fileprivate func requiredInputFields() -> [UITextField] {
        assert(isViewLoaded, "This method is only intended to be called when view is loaded, since they'll all be nil otherwise")
        return [usernameField, passwordField]
    }

    fileprivate func areRequiredFieldsPopulated() -> Bool {
        return requiredInputFields().wmf_allFieldsFilled()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        
captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
captchaViewController?.captchaDelegate = self
wmf_addChildController(captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)


// Check if captcha is required right away. Things could be configured so captcha is required at all times.
getCaptcha()

        
        
        
        

        
        
        
        
        
        
        enableProgressiveButtonIfNecessary()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == usernameField) {
            passwordField.becomeFirstResponder()
        } else if (textField == passwordField) {
            save()
        }
        return true
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        disableProgressiveButton()
        WMFAlertManager.sharedInstance.dismissAlert()
        WMFAuthenticationManager.sharedInstance.login(username: usernameField.text!, password: passwordField.text!, retypePassword:nil, oathToken:nil, captchaID: captchaViewController?.captcha?.captchaID, captchaWord: captchaViewController?.solution, success: { _ in
            let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
            WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            self.dismiss(animated: true, completion: nil)
            self.funnel?.logSuccess()
        }, failure: { error in

// Capcha's appear to be one-time, so always try to get a new one on failure.
self.getCaptcha()

            
            if let error = error as? WMFAccountLoginError {
                switch error {
                case .temporaryPasswordNeedsChange:
                    self.showChangeTempPasswordViewController()
                    return
                case .needsOathTokenFor2FA:
                    self.showTwoFactorViewController()
                    return
// TODO: document why this doesn't work (ie the server returns "login-failed" not "captcha-createaccount-fail" if login doesn't succeed even if it didn't succeed because a captcha is now needed.
// have to re-fetch info in fail cases to see if captcha is now needed)
//                case .needsCaptcha:
//                    
//                    self.getCaptcha()

// test 2FA login w capcha.
// 2FA fails atm if you enter incorrect pwd for a 2FA acct 3 times to get catpcha to show, then enter incorrect pwd or captcha once, then enter everything correctly (the 2fa vc isn't shown and just fails login) 
                    
                    
                case .statusNotPass:
                    self.passwordField.text = nil
                    self.passwordField.becomeFirstResponder()
                default: break
                }
            }

            
            
//if self.captchaViewController?.captcha == nil {
//    self.getCaptcha()
//}
            
            self.enableProgressiveButtonIfNecessary()
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        })
    }

    func showChangeTempPasswordViewController() {
        guard let presenter = presentingViewController else {
            return
        }
        dismiss(animated: true, completion: {
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            changePasswordVC?.userName = self.usernameField!.text
            let navigationController = UINavigationController.init(rootViewController: changePasswordVC!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func showTwoFactorViewController() {
        guard
            let presenter = presentingViewController,
            let twoFactorViewController = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
//TODO: ? wrap userName, password, captchID and captchaWord into WMFCredentials model obj?
            twoFactorViewController.userName = self.usernameField!.text
            twoFactorViewController.password = self.passwordField!.text
            twoFactorViewController.captchaID = self.captchaViewController?.captcha?.captchaID
            twoFactorViewController.captchaWord = self.captchaViewController?.solution
            let navigationController = UINavigationController.init(rootViewController: twoFactorViewController)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func forgotPasswordButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let forgotPasswordVC = WMFForgotPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            let navigationController = UINavigationController.init(rootViewController: forgotPasswordVC)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func createAccountButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let createAcctVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        funnel?.logCreateAccountAttempt()
        dismiss(animated: true, completion: {
            createAcctVC.funnel = CreateAccountFunnel()
            createAcctVC.funnel?.logStart(fromLogin: self.funnel?.loginSessionToken)
            let navigationController = UINavigationController.init(rootViewController: createAcctVC)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
// add comments explaining how info needs to be called 'cause it's the thing that tells us if captcha is required, but
// we cant call it each time we try to login because if we already have a captcha id calling info again invalidates that old id and issues a new one,
// so info needs to be called before 1st login attempt and after failed login attempts
// rename the method too to somehow better reflect this.
    fileprivate func getCaptcha() {
        
        
        
//        let failure: WMFErrorHandler = {error in }
//        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
//        //self.tokenFetcher.fetchToken(ofType: .createAccount, siteURL: siteURL!, success: { token in
//        self.loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: { info in
//            //if(self.captchaViewController?.captcha != nil){
//            self.captchaViewController?.captcha = info.captcha
//            //}
//            //            self.showCaptchaContainer = (info.captcha != nil)
//        }, failure:failure)
//        //}, failure:failure)

        
        
        
        let captchaFailure: WMFErrorHandler = {error in
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        }
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: { info in

/*

REMINDER: (??? is this right?) token of matching type must be fetched when refreshing captcha (otherwise it wont be associated on server with last requested token of that type)
- make pass token explicitly to the captcha VC when (if) we move captcha refreshing into it?
*/
//            self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL!,
//                                         success: { token in
//                                            let warningMessage = self.hasUserEnteredCaptchaText() ? localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-retry") : localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-required")
//                                            WMFAlertManager.sharedInstance.showWarningAlert(warningMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)

            
print("ID \(info.captcha?.captchaID) URL \(info.captcha?.captchaURL)")
            
                                            self.captchaViewController?.captcha = info.captcha
//                                            self.showCaptchaContainer = true
//                                            self.captcha = info.captcha
self.enableProgressiveButtonIfNecessary()
            
//            }, failure: captchaFailure)
        }, failure: captchaFailure)
    }

    
    
    func captchaReloadPushed(_ sender: AnyObject) {
return;
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-obtaining"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        //        getCaptcha()
    
    
        

//THE LAST THING I CHANGED SEEMED TO MAKE LOGIN WITH CAPTCHA NO LONGER WORD - RE-pull from pre-change from github?
        
// if login, acct creation and editing can look at captchaVC's "captcha" and "captchaSolution" prop instead of storing own (for captchaID), we could then move captcha refreshing inside the captcha VC
// try here 1st?

// switch acct creation to only show captcha based on info fetch, like here in login.
// that way if captcha requirement ever goes away the interface wont break!
        
        
        
        
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        self.captchaResetter.resetCaptcha(siteURL: siteURL!, success: { result in

            guard let previousCaptcha = self.captchaViewController?.captcha else {
//TODO: add assert here 
                return
            }
            
            let previousCaptchaURL = previousCaptcha.captchaURL
            let previousCaptchaNSURL = previousCaptchaURL as NSURL
            
            // Resetter only fetches captchaID, so use previous captchaURL changing its wpCaptchaId.
            let newCaptchaURL = previousCaptchaNSURL.wmf_url(withValue: result.index, forQueryKey:"wpCaptchaId")
            let newCaptcha = WMFCaptcha.init(captchaID: previousCaptcha.captchaID, captchaURL: newCaptchaURL)
            self.captchaViewController?.captcha = newCaptcha
//            self.captcha = newCaptcha
        
        }, failure: {error in
//TODO: assert here
        })
    
        
/*
         make a note that you can enter an incorrect captcha and it will appear to work if you wait more than 3 min or so before submitting.
         this is because, i think, the captcha requirement is recinded after so much time... a few min
         
         
         
         are number stripped out of captcha solutions? would this aid mechanized solving?
         isn't that just like providing a hint to mechanized solvers that our captchas don't contain numbers?
         
         */
        
        
        
        
    
    
    
    
    
    
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
//        captchaSolution = solutionText
        enableProgressiveButtonIfNecessary()
    }
    
    func captchaDomain() -> String {
        guard let appLang = MWKLanguageLinkController.sharedInstance().appLanguage else {
            assert(false, "Could not determine language")
        }
        let siteURL = appLang.siteURL() as NSURL
        guard let domain = siteURL.wmf_domain else {
            assert(false, "Could not determine domain")
        }
        return domain
    }
    
    func captchaLanguageCode() -> String {
        guard let appLang = MWKLanguageLinkController.sharedInstance().appLanguage else {
            assert(false, "Could not determine appLanguage")
        }
        return appLang.languageCode
    }
}
