//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikidataDescriptionUploader.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

#define WIKIDATA_ENDPOINT @"https://www.wikidata.org/w/api.php"

@interface WikidataDescriptionUploader ()

@property (strong, nonatomic) NSString* desc;
@property (strong, nonatomic) MWKTitle* title;
@property (strong, nonatomic) NSString* wikidataEditToken;
@property (strong, nonatomic) NSString* centralAuthToken;

@end

@implementation WikidataDescriptionUploader

- (instancetype)initAndUploadWikidataDescription:(NSString*)desc
                                    forPageTitle:(MWKTitle*)title
                               wikidataEditToken:(NSString*)wikidataEditToken
                                centralAuthToken:(NSString*)centralAuthToken
                                     withManager:(AFHTTPRequestOperationManager*)manager
                              thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.desc              = desc ? desc : @"";
        self.title             = title;
        self.wikidataEditToken = wikidataEditToken ? wikidataEditToken : @"";
        self.centralAuthToken  = centralAuthToken ? centralAuthToken : @"";

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
            error = [NSError errorWithDomain:@"Wikidata Description Uploader"
                                        code:WIKIDATA_UPLOAD_ERROR_SERVER
                                    userInfo:errorDict];
        }

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
        @"action": @"wbsetdescription",
        @"token": self.wikidataEditToken,
        @"value": self.desc,
        @"site": [self.title.site.language stringByAppendingString:@"wiki"],
        @"language": self.title.site.language,
        @"title": self.title.prefixedDBKey,
        @"format": @"json"
    }.mutableCopy;

    if (self.centralAuthToken && (self.centralAuthToken.length > 0)) {
        params[@"centralauthtoken"] = self.centralAuthToken;
    }
    return params;
}

@end
