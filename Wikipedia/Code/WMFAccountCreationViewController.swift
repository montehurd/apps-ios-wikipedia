
import UIKit

class WMFAccountCreationViewController: UIViewController, WMFCaptchaViewControllerRefresh, UITextFieldDelegate, UIScrollViewDelegate {
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var passwordRepeatField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var captchaContainer: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var loginButton: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var passwordConfirmUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var emailUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var spaceBeneathCaptchaContainer: NSLayoutConstraint!
    @IBOutlet var createAccountContainerView: UIView!

//    fileprivate var captchaId: NSString? = ""
    fileprivate var rightButton: UIBarButtonItem?
    public var funnel: CreateAccountFunnel?
    fileprivate var captchaViewController: WMFCaptchaViewController?
        
    fileprivate func adjustScrollLimitForCaptchaVisiblity() {
        // Reminder: spaceBeneathCaptchaContainer constraint is space *below* captcha container -
        // that's why below for the show case we don't have to "convertPoint".
        spaceBeneathCaptchaContainer.constant = (showCaptchaContainer)
            ? (view.frame.size.height - (captchaContainer.frame.size.height / 2))
            : (view.frame.size.height - loginButton.convert(CGPoint.zero, to:scrollView).y)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            // Ensure adjustScrollLimitForCaptchaVisiblity gets called again after rotating.
            self.view.setNeedsUpdateConstraints()
            if self.showCaptchaContainer {
                self.scrollView.scrollSubView(toTop: self.captchaContainer, animated:false)
            }
        })
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        if (showCaptchaContainer) {
            showCaptchaContainer = false
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func loginButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = self.presentingViewController else {
                return
        }
        dismiss(animated: true, completion: {
            let navigationController = UINavigationController.init(rootViewController: WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard()!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))

        rightButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("button-next"), style: .plain, target: self, action: #selector(self.doneButtonPushed(_:)))
        
        navigationItem.rightBarButtonItem = rightButton
        
        scrollView.delegate = self
        
        usernameField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        passwordRepeatField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        emailField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        captchaContainer.alpha = 0
        
        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-password-placeholder-text")
        passwordRepeatField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-password-confirm-placeholder-text")
        emailField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-email-placeholder-text")

        scrollView.keyboardDismissMode = .interactive
        
        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = usernameUnderlineHeight.constant;
        passwordConfirmUnderlineHeight.constant = usernameUnderlineHeight.constant;
        emailUnderlineHeight.constant = usernameUnderlineHeight.constant;

        loginButton.textColor = UIColor.wmf_blueTint()
        loginButton.text = localizedStringForKeyFallingBackOnEnglish("account-creation-login")
        loginButton.isUserInteractionEnabled = true
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.loginButtonPushed(_:))))
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-create-account")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
        wmf_addChildController(captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        showCaptchaContainer = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.textFieldDidChange(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: captchaViewController?.captchaTextBox)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }

    func textFieldDidChange(_ sender: Any?) {
        var shouldHighlight = areRequiredFieldsPopulated() && (passwordField.text == passwordRepeatField.text)
        // Override shouldHighlight if the text changed was the captcha field.
        if let notification = sender as? Notification {
            if notification.object as AnyObject? === captchaViewController?.captchaTextBox {
                shouldHighlight = hasUserEnteredCaptchaText()
            }
        }
        enableProgressiveButton(shouldHighlight)
    }

    fileprivate func hasUserEnteredCaptchaText() -> Bool {
        let trimmedCaptchaText = captchaViewController?.captchaTextBox.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return ((trimmedCaptchaText?.characters.count)! > 0)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == usernameField) {
            passwordField.becomeFirstResponder()
        } else if (textField == passwordField) {
            passwordRepeatField.becomeFirstResponder()
        } else if (textField == passwordRepeatField) {
            emailField.becomeFirstResponder()
        } else {
            assert(((textField == emailField) || (textField == captchaViewController?.captchaTextBox)), "Received -textFieldShouldReturn for unexpected text field: \(textField)")
            save()
        }
        return true
    }

    fileprivate func enableProgressiveButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        enableProgressiveButton(false)
        WMFAlertManager.sharedInstance.dismissAlert()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextFieldTextDidChange, object: captchaViewController?.captchaTextBox)
        super.viewWillDisappear(animated)
    }
    
    fileprivate var showCaptchaContainer: Bool = false {
        didSet {
            rightButton?.title = showCaptchaContainer ? localizedStringForKeyFallingBackOnEnglish("button-done") : localizedStringForKeyFallingBackOnEnglish("button-next")
            let duration: TimeInterval = 0.5
            view.setNeedsUpdateConstraints()
            
            if showCaptchaContainer {
                captchaViewController?.captchaTextBox.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.4)
                funnel?.logCaptchaShown()
                DispatchQueue.main.async(execute: {
                    UIView.animate(withDuration: duration, animations: {
                        self.captchaContainer.alpha = 1
                        self.scrollView.scrollSubView(toTop: self.captchaContainer, animated:false)
                    }, completion: {(completed: Bool) -> Void in
                        self.enableProgressiveButton(false)
                    })
                })
            }else{
                DispatchQueue.main.async(execute: {
                    WMFAlertManager.sharedInstance.dismissAlert()
                    UIView.animate(withDuration: duration, animations: {
                        self.captchaContainer.alpha = 0
                        self.scrollView.setContentOffset(CGPoint.zero, animated: false)
                    }, completion: {(completed: Bool) -> Void in
                        self.captchaViewController?.captchaTextBox.text = ""
                        self.captchaViewController?.captchaImageView.image = nil
                        // Pretent a text field changed so the progressive button state gets updated.
                        self.textFieldDidChange(nil)
                    })
                })
            }
        }
    }
    
    fileprivate var captchaID: String?
    fileprivate var captchaURL: URL? {
        didSet {
            guard captchaURL != nil else {
                return;
            }
            refreshCaptchaImage()
        }
    }
    
    fileprivate func refreshCaptchaImage() {
        captchaViewController?.captchaTextBox.text = ""
        captchaViewController?.captchaImageView.sd_setImage(with: captchaURL)
        showCaptchaContainer = true
    }

    func reloadCaptchaPushed(_ sender: AnyObject) {
        captchaViewController?.captchaTextBox.text = ""
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-obtaining"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        getCaptcha()
    }
    
    fileprivate func login() {
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-logging-in"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        WMFAuthenticationManager.sharedInstance().login(
            withUsername: usernameField.text!,
            password: passwordField.text!,
            retypePassword: nil,
            oathToken: nil,
            success: {
                let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            self.enableProgressiveButton(true)
            // WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        })
    }
    
    fileprivate func requiredInputFields() -> [UITextField] {
        assert(isViewLoaded, "This method is only intended to be called when view is loaded, since they'll all be nil otherwise")
        return [usernameField, passwordField, passwordRepeatField]
    }

    fileprivate func isPasswordConfirmationCorrect() -> Bool {
        return passwordField.text == passwordRepeatField.text
    }
    
    fileprivate func areRequiredFieldsPopulated() -> Bool {
        let firstRequiredFieldWithNoText = requiredInputFields().first(where:{ $0.text?.characters.count == 0 })
        return firstRequiredFieldWithNoText == nil
    }
    
    func doneButtonPushed(_ tap: UITapGestureRecognizer) {
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-saving"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        save()
    }
    
    override func updateViewConstraints() {
        adjustScrollLimitForCaptchaVisiblity()
        super.updateViewConstraints()
    }

    fileprivate func save() {
        guard areRequiredFieldsPopulated() == true else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-missing-fields"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        guard isPasswordConfirmationCorrect() == true else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-passwords-mismatched"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        createAccount(withCaptcha: captchaViewController?.captchaTextBox.text)
    }
    
    fileprivate func getCaptcha() {
        WMFAuthenticationManager.sharedInstance().getAccountCreationCaptcha(success: {(captchaURL, captchaID) in
            
            let warningMessage = self.hasUserEnteredCaptchaText() ? localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-retry") : localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-required")
            
            WMFAlertManager.sharedInstance.showWarningAlert(warningMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            
            self.captchaID = captchaID
            self.captchaURL = captchaURL
        }, failure: {error in
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        })
    }
    
    fileprivate func createAccount(withCaptcha captcha:String?) {
        WMFAuthenticationManager.sharedInstance().createAccount(withUsername: usernameField.text!, password: passwordField.text!, retypePassword: passwordRepeatField.text!, email: emailField.text!, captchaID:captchaID, captchaText: captcha, success: {

            WMFAuthenticationManager.sharedInstance().login(withUsername: self.usernameField.text!, password: self.passwordField.text!, retypePassword: nil, oathToken: nil, success: {
                let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.dismiss(animated: true, completion: nil)
            }, failure: { error in
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.enableProgressiveButton(true)
            })
            
        }, failure: {error in
            self.funnel?.logError(error.localizedDescription)
            self.enableProgressiveButton(true)

            if let accountCreatorError = error as? WMFAccountCreatorError {
                switch accountCreatorError.type {
                case .needsCaptcha:
                    self.getCaptcha()
                    return
                default:
                    break
                }
            }

            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        })
    }
}
