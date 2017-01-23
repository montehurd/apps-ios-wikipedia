
import UIKit

/*
 - hook up networking
 
    Send a password reset email to user Example.
        api.php?action=resetpassword&user=Example&token=123ABC [open in sandbox]
    Send a password reset email for all users with email address user@example.com.
        api.php?action=resetpassword&user=user@example.com&token=123ABC [open in sandbox]
 
 NSURLSESSION
    base it on MWKSiteInfoFetcher?
    See pagehistoryfetcher.swift and http://sroze.io/2014/07/25/ios-swift-and-afnetworking-get-response-data-and-status-code-in-case-of-failure/
 
 - layout tweaking
 - dynamic type
 - test on tablet and ios 9
 
    https://en.wikipedia.org/w/api.php?action=help&modules=resetpassword
 
TODO:
 - get rid of WMFPasswordResetterResponse and instead use and return real errors like the token fetcher now does
 - add documentation to each bit - "command option /"
 - i18n
 - make clear in response serializer docs that only precise 'success' won't throw error
 - tests
 
*/

class ForgotPasswordViewController: UIViewController {
    let tokenFetcher = WMFCSRFTokenFetcher()
    let passwordResetter = WMFPasswordResetter()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

//TODO: actually hook sendPasswordResetEmail up and delete didReceiveMemoryWarning
    override func didReceiveMemoryWarning() {
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        sendPasswordResetEmail(siteURL: siteURL!, userName: "acct_creation_test_911", email: nil)
    }
    
    
    func sendPasswordResetEmail(siteURL: URL, userName: String?, email: String?) {

        let failureHandler: WMFURLSessionDataTaskFailureHandler = {
            (_, error: Error) in
            WMFAlertManager.sharedInstance.showAlert(error.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }

        let passwordResetterSuccessHandler: WMFURLSessionDataTaskSuccessHandler = {
            (_, response: Any?) in
//TODO: decide if we just show this message or show it then pop this vc...
            WMFAlertManager.sharedInstance.showAlert("Password reset email was sent", sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }
        
        let tokenFetcherSuccessHandler: WMFURLSessionDataTaskSuccessHandler = {
            (_, token: Any?) in
            self.passwordResetter.resetPassword(
                siteURL: siteURL,
                token: token as! String,
                userName: userName,
                email: email,
                completion: passwordResetterSuccessHandler,
                failure: failureHandler
            )
        }
        
        tokenFetcher.fetchCSRFToken(
            siteURL: siteURL,
            completion: tokenFetcherSuccessHandler,
            failure: failureHandler
        )
    
    }
}
