//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikidataEditTokenFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

#define WIKIDATA_ENDPOINT @"https://www.wikidata.org/w/api.php"

@interface WikidataEditTokenFetcher ()

@property (strong, nonatomic) NSString* editToken;
@property (strong, nonatomic) NSString* centralAuthToken;

@end

@implementation WikidataEditTokenFetcher

- (instancetype)initAndFetchEditTokenWithCentralAuthToken:(NSString*)centralAuthToken
                                              withManager:(AFHTTPRequestOperationManager*)manager
                                       thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.editToken             = @"";
        self.centralAuthToken      = centralAuthToken ? centralAuthToken : @"";
        self.fetchFinishedDelegate = delegate;
        [self uploadWithManager:manager];
    }
    return self;
}

- (void)uploadWithManager:(AFHTTPRequestOperationManager*)manager {
    NSString* url = WIKIDATA_ENDPOINT;

    NSDictionary* params = [self getParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        NSDictionary* responseDictionary = [self dictionaryFromDataResponse:responseObject];

        if (![responseDictionary isDict]) {
            responseDictionary = @{@"error": @{@"info": @"Wikidata description not uploaded."}};
        }

        NSError* error = nil;
        if (responseDictionary[@"error"]) {
            NSMutableDictionary* errorDict = [responseDictionary[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Wikidata Edit Token Fetcher"
                                        code:WIKIDATA_EDIT_TOKEN_ERROR_API
                                    userInfo:errorDict];
        }

        NSDictionary* query = responseDictionary[@"query"];

        if (!query || !query[@"tokens"] || !query[@"tokens"][@"csrftoken"]) {
            NSMutableDictionary* errorDict = [@{} mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = @"Wikidata Edit Token Fetcher failed";
            error = [NSError errorWithDomain:@"Wikidata Edit Token Fetcher" code:WIKIDATA_EDIT_TOKEN_ERROR_UNKNOWN userInfo:errorDict];
        }

        self.editToken = query[@"tokens"][@"csrftoken"];

        [self finishWithError:error
                  fetchedData:responseDictionary];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSMutableDictionary*)getParams {
    NSMutableDictionary* params =
        @{
        @"action": @"query",
        @"meta": @"tokens",
        @"centralauthtoken": self.centralAuthToken,
        @"format": @"json"
    }.mutableCopy;
    return params;
}

@end
