#import <WMF/MWKSiteInfoFetcher.h>
#import <WMF/MWNetworkActivityIndicatorManager.h>
#import <WMF/AFHTTPSessionManager+WMFDesktopRetry.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/WMFNetworkUtilities.h>
#import <WMF/WMFApiJsonResponseSerializer.h>
#import <WMF/MWKSiteInfo.h>

@interface MWKSiteInfoFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager *operationManager;
@end

@implementation MWKSiteInfoFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFApiJsonResponseSerializer serializer];
        self.operationManager = manager;
    }
    return self;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchSiteInfoForSiteURL:(NSURL *)siteURL completion:(void (^)(MWKSiteInfo *data))completion failure:(void (^)(NSError *error))failure {

    NSDictionary *params = @{
        @"action": @"query",
        @"meta": @"siteinfo",
        @"format": @"json",
        @"siprop": @"general"
    };

    [self.operationManager wmf_GETAndRetryWithURL:siteURL
        parameters:params
        retry:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            NSDictionary *generalProps = [responseObject valueForKeyPath:@"query.general"];
            MWKSiteInfo *info = [[MWKSiteInfo alloc] initWithSiteURL:siteURL mainPageTitleText:generalProps[@"mainpage"]];
            completion(info);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            failure(error);
        }];
}

@end
