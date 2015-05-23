//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikidataDescriptionUploader.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

#define WIKIDATA_ENDPOINT @"https://www.wikidata.org/w/api.php"

@interface WikidataDescriptionUploader ()

@property (strong, nonatomic) NSString* desc;
@property (strong, nonatomic) MWKTitle* title;
@property (strong, nonatomic) NSString* token;

@end

@implementation WikidataDescriptionUploader

- (instancetype)initAndUploadWikidataDescription:(NSString*)desc
                                    forPageTitle:(MWKTitle*)title
                                           token:(NSString*)token
                                     withManager:(AFHTTPRequestOperationManager*)manager
                              thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.desc  = desc ? desc : @"";
        self.title = title;
        self.token = token ? token : @"";

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
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];


        // Convert the raw NSData response to a dictionary.
        NSDictionary* responseDictionary = [self dictionaryFromDataResponse:responseObject];


        // Fake out an error if non-dictionary response received.
        if (![responseDictionary isDict]) {
            responseDictionary = @{@"error": @{@"info": @"Wikidata description not uploaded."}};
        }

        //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseDictionary);

        // Handle case where response is received, but API reports error.
        NSError* error = nil;
        if (responseDictionary[@"error"]) {
            NSMutableDictionary* errorDict = [responseDictionary[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Wikidata Description Uploader"
                                        code:WIKIDATA_UPLOAD_ERROR_SERVER
                                    userInfo:errorDict];
        }


        NSNumber* successVal = responseDictionary[@"success"];

        if (!successVal || (successVal.integerValue != 1)) {
            NSMutableDictionary* errorDict = [@{} mutableCopy];
//            errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"wikitext-upload-result-unknown", nil);
//TODO: i18n
            errorDict[NSLocalizedDescriptionKey] = @"Description upload failed";

            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Wikidata Description Uploader" code:WIKIDATA_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
        }

        [self finishWithError:error
                  fetchedData:responseDictionary];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        //NSLog(@"FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSMutableDictionary*)getParams {
    NSString* tokenToUse = @"+\\";
    if (self.token && (self.token.length > 0)) {
        tokenToUse = self.token;
    }

    //?action=wbsetdescription&site=enwiki&title=Wikipedia&language=en&value=An%20encyclopedia%20that%20everyone%20can%20edit
    //  ...or...
    //?api.php?action=wbsetdescription&id=Q42&language=en&value=An%20encyclopedia%20that%20everyone%20can%20edit

// do we want to just use wikibase id's & second query above? if so add wikibase prop to search query and article loading query
// and have it get routed to data store.

// need to try passing along token! see if my login gets credited

    NSMutableDictionary* params =
        @{
        @"action": @"wbsetdescription",
        @"token": tokenToUse,
        @"value": self.desc,
        @"site": [self.title.site.language stringByAppendingString:@"wiki"],
        @"language": self.title.site.language,
        @"title": self.title.prefixedURL,
        @"format": @"json"
    }.mutableCopy;

    return params;
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
   }
 */

@end
