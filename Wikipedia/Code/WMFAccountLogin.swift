
public enum WMFAccountLoginError: LocalizedError {
    case cannotExtractLoginStatus
    case statusNotPass(String?)
    case temporaryPasswordNeedsChange(String?)
    case needsOathTokenFor2FA(String?)
    public var errorDescription: String? {
        switch self {
        case .cannotExtractLoginStatus:
            return "Could not extract login status"
        case .statusNotPass(let message?):
            return message
        case .temporaryPasswordNeedsChange(let message?):
            return message
        case .needsOathTokenFor2FA(let message?):
            return message
        default:
            return "Unable to login: Reason unknown"
        }
    }
}

typealias WMFAccountLoginResultBlock = (WMFAccountLoginResult) -> Void

class WMFAccountLoginResult: NSObject {
    var status: String
    var username: String
    var message: String?
    init(status: String, username: String, message: String?) {
        self.status = status
        self.username = username
        self.message = message
    }
}

class WMFAccountLogin {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func login(username: String, password: String, retypePassword: String?, loginToken: String, oathToken: String?, siteURL: URL, success: @escaping WMFAccountLoginResultBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        
        var parameters = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "logintoken": loginToken,
            "rememberMe": "1",
            "format": "json"
        ]
        
        if let retypePassword = retypePassword {
            parameters["retype"] = retypePassword
            parameters["logincontinue"] = "1"
        }

        if let oathToken = oathToken {
            parameters["OATHToken"] = oathToken
            parameters["logincontinue"] = "1"
        }
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
            guard
                let response = response as? [String : AnyObject],
                let clientlogin = response["clientlogin"] as? [String : AnyObject],
                let status = clientlogin["status"] as? String
                else {
                    failure(WMFAccountLoginError.cannotExtractLoginStatus)
                    return
            }
            let message = clientlogin["message"] as? String ?? nil
            guard status == "PASS" else {
                
                if
                    status == "UI",
                    let requests = clientlogin["requests"] as? [AnyObject]
                {
                    if let passwordAuthRequest = requests.first(where:{$0["id"]! as! String == "MediaWiki\\Auth\\PasswordAuthenticationRequest"}),
                        let fields = passwordAuthRequest["fields"] as? [String : AnyObject],
                        let _ = fields["password"] as? [String : AnyObject],
                        let _ = fields["retype"] as? [String : AnyObject]
                    {
                        failure(WMFAccountLoginError.temporaryPasswordNeedsChange(message))
                        return
                    }
                    if let OATHTokenRequest = requests.first(where:{$0["id"]! as! String == "TOTPAuthenticationRequest"}),
                        let fields = OATHTokenRequest["fields"] as? [String : AnyObject],
                        let _ = fields["OATHToken"] as? [String : AnyObject]
                    {
                        failure(WMFAccountLoginError.needsOathTokenFor2FA(message))
                        return
                    }
                }
                
                failure(WMFAccountLoginError.statusNotPass(message))
                return
            }
            let normalizedUsername = clientlogin["username"] as? String ?? username
            success(WMFAccountLoginResult.init(status: status, username: normalizedUsername, message: message))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
