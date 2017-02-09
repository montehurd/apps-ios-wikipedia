#import "WMFAuthenticationManager.h"
#import "KeychainCredentials.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"
#import "NSHTTPCookieStorage+WMFCloneCookie.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthenticationManager ()

@property (strong, nonatomic) KeychainCredentials *keychainCredentials;

@property (strong, nonatomic, nullable) WMFAuthLoginInfoFetcher* authLoginInfoFetcher;
@property (strong, nonatomic, nullable) WMFAuthAccountCreationInfoFetcher* authAccountCreationInfoFetcher;
@property (strong, nonatomic, nullable) WMFAuthTokenFetcher *loginTokenFetcher;
@property (strong, nonatomic, nullable) WMFAccountLogin *accountLogin;
@property (strong, nonatomic, nullable) WMFAuthTokenFetcher *accountCreationTokenFetcher;
@property (strong, nonatomic, nullable) WMFAccountCreator *accountCreator;
@property (strong, nonatomic, nullable) WMFCurrentlyLoggedInUserFetcher *currentlyLoggedInUserFetcher;


@property (strong, nonatomic, readwrite, nullable) NSString *loggedInUsername;


@end

@implementation WMFAuthenticationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keychainCredentials = [[KeychainCredentials alloc] init];
    }
    return self;
}

#pragma mark - Account Creation

- (void)getAccountCreationCaptchaWithSuccess:(WMFCaptchaHandler)success failure:(WMFErrorHandler)failure {

    self.authAccountCreationInfoFetcher = [[WMFAuthAccountCreationInfoFetcher alloc] init];
    @weakify(self)
    [self.authAccountCreationInfoFetcher fetchAccountCreationInfoForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL
                                                                    success:^(WMFAuthAccountCreationInfo* info){
                                                                        @strongify(self)
                                                                        
                                                                        NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
                                                                        self.accountCreationTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
                                                                        [self.accountCreationTokenFetcher fetchTokenOfType:WMFAuthTokenTypeCreateAccount siteURL:siteURL success:^(WMFAuthToken* result){

                                                                            success([info captchaImageURL], info.captchaID);
                                                                            
                                                                        } failure:failure];
                                                                    } failure:failure];
}

- (void)createAccountWithUsername:(NSString *)username password:(NSString *)password retypePassword:(NSString*)retypePassword email:(nullable NSString *)email captchaID:(nullable NSString *)captchaID captchaText:(nullable NSString *)captchaText success:(nullable dispatch_block_t)success failure:(WMFErrorHandler)failure {

    NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
    
    self.accountCreationTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
    [self.accountCreationTokenFetcher fetchTokenOfType:WMFAuthTokenTypeCreateAccount siteURL:siteURL success:^(WMFAuthToken* result){
        
        self.accountCreator = [[WMFAccountCreator alloc] init];
        [self.accountCreator createAccountWithUsername:username
                                              password:password
                                        retypePassword:retypePassword
                                                 email:email
                                             captchaID:captchaID
                                           captchaWord:captchaText
                                                 token:result.token
                                               siteURL:siteURL
                                               success:^(WMFAccountCreatorResult* result){
                                                   if(success){
                                                       success();
                                                   }
                                               } failure:failure];
        
    } failure:failure];
}

#pragma mark - Login

- (BOOL)isLoggedIn {
    return self.loggedInUsername != nil;
}

- (void)loginWithSavedCredentialsWithSuccess:(nullable dispatch_block_t)success
                      userWasAlreadyLoggedIn:(nullable void (^)(WMFCurrentlyLoggedInUser *))loggedInUserHandler
                                     failure:(nullable WMFErrorHandler)failure {
    
    if (self.keychainCredentials.userName.length == 0 || self.keychainCredentials.password.length == 0) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }
    
    NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
    
    self.currentlyLoggedInUserFetcher = [[WMFCurrentlyLoggedInUserFetcher alloc] init];
    @weakify(self);
    [self.currentlyLoggedInUserFetcher fetchWithSiteURL:siteURL
                                             success:^(WMFCurrentlyLoggedInUser * _Nonnull currentlyLoggedInUser) {
                                                 @strongify(self);
                                                 
                                                 self.loggedInUsername = currentlyLoggedInUser.name;
                                                 
                                                 if(loggedInUserHandler){
                                                     loggedInUserHandler(currentlyLoggedInUser);
                                                 }
                                                 
                                             } failure:^(NSError * _Nonnull error) {
                                                 @strongify(self);
                                                 
                                                 self.loggedInUsername = nil;
                                                 
                                                 [self loginWithUsername:self.keychainCredentials.userName
                                                                password:self.keychainCredentials.password
                                                          retypePassword:nil
                                                               oathToken:nil
                                                                 success:success
                                                                 failure:^(NSError *error) {
                                                                     @strongify(self);
                                                                     
                                                                     if(error.code != kCFURLErrorNotConnectedToInternet){
                                                                         [self logout];
                                                                     }
                                                                     
                                                                     if (failure) {
                                                                         failure(error);
                                                                     }
                                                                 }];
                                             }];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password retypePassword:(nullable NSString*)retypePassword oathToken:(nullable NSString*)oathToken success:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    
    if (username.length == 0 || password.length == 0) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }
    
    self.authLoginInfoFetcher = [[WMFAuthLoginInfoFetcher alloc] init];
    @weakify(self)
    [self.authLoginInfoFetcher fetchLoginInfoForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL
                                                success:^(WMFAuthLoginInfo* info){
                                                    @strongify(self)
                                                    
                                                    NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
                                                    
                                                    self.loginTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
                                                    [self.loginTokenFetcher fetchTokenOfType:WMFAuthTokenTypeLogin siteURL:siteURL success:^(WMFAuthToken* result){
                                                        
                                                        @strongify(self)
                                                        self.accountLogin = [[WMFAccountLogin alloc] init];
                                                        [self.accountLogin loginWithUsername:username
                                                                                    password:password
                                                                              retypePassword:retypePassword
                                                                                  loginToken:result.token
                                                                                   oathToken:oathToken
                                                                                     siteURL:siteURL
                                                                                     success:^(WMFAccountLoginResult* result){
                                                                                         @strongify(self)
                                                                                         NSString *normalizedUserName = result.username;
                                                                                         self.loggedInUsername = normalizedUserName;
                                                                                         self.keychainCredentials.userName = normalizedUserName;
                                                                                         self.keychainCredentials.password = password;
                                                                                         [self cloneSessionCookies];
                                                                                         if (success){
                                                                                             success();
                                                                                         }
                                                                                     } failure:failure];
                                                    } failure:failure];
                                                } failure:failure];
}

#pragma mark - Logout

- (void)logout {
    self.keychainCredentials.userName = nil;
    self.keychainCredentials.password = nil;
    self.loggedInUsername = nil;
    // Clear session cookies too.
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - Cookie Sync

- (void)cloneSessionCookies {
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString *domain = [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode;

    NSString *cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString *cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:cookie1Name
                                                usingCookieAsTemplate:cookie2Name];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:@"centralauth_Session"
                                                usingCookieAsTemplate:@"centralauth_User"];
}

@end

NS_ASSUME_NONNULL_END
