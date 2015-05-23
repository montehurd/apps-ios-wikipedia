//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CentralAuthTokenFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface CentralAuthTokenFetcher ()

@property (strong, nonatomic) NSString* token;
@property (strong, nonatomic) MWKSite* site;
@property (strong, nonatomic) id userData;

@end

@implementation CentralAuthTokenFetcher

- (instancetype)initAndFetchCentralAuthTokenForSite:(MWKSite*)site
                                           userData:(id)userData
                                        withManager:(AFHTTPRequestOperationManager*)manager
                                 thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.token                 = @"";
        self.site                  = site;
        self.userData              = userData;
        self.fetchFinishedDelegate = delegate;
        [self fetchTokenWithManager:manager];
    }
    return self;
}

- (void)fetchTokenWithManager:(AFHTTPRequestOperationManager*)manager {
    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:self.site.language];

    NSDictionary* params = [self getParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        NSDictionary* responseDictionary = [self dictionaryFromDataResponse:responseObject];

        if (![responseDictionary isDict]) {
            responseDictionary = @{@"error": @{@"info": @"Central Auth token not found."}};
        }

        NSError* error = nil;
        if (responseDictionary[@"error"]) {
            NSMutableDictionary* errorDict = [responseDictionary[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Central Auth Token Fetcher"
                                        code:AUTH_TOKEN_ERROR_API
                                    userInfo:errorDict];
        }

        NSDictionary* output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseDictionary];
        }

        self.token = output[@"token"] ? output[@"token"] : @"";

        [self finishWithError:error
                  fetchedData:output];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSMutableDictionary*)getParams {
    return @{
               @"action": @"centralauthtoken",
               @"format": @"json"
    }.mutableCopy;
}

- (NSDictionary*)getSanitizedResponse:(NSDictionary*)rawResponse {
    if ([rawResponse isDict]) {
        id centralauthtokenDict = rawResponse[@"centralauthtoken"];
        if ([centralauthtokenDict isDict]) {
            id token = centralauthtokenDict[@"centralauthtoken"];
            if (token) {
                return @{@"token": token};
            }
        }
    }
    return @{};
}

@end
