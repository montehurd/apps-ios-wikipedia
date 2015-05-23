//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM (NSInteger, WikidataDescriptionUploaderErrors) {
    WIKIDATA_UPLOAD_ERROR_UNKNOWN = 0,
    WIKIDATA_UPLOAD_ERROR_SERVER  = 1,
    WIKIDATA_UPLOAD_ERROR_FAILURE = 2
};

@class AFHTTPRequestOperationManager;

@interface WikidataDescriptionUploader : FetcherBase

@property (strong, nonatomic, readonly) NSString* desc;
@property (strong, nonatomic, readonly) MWKTitle* title;
@property (strong, nonatomic, readonly) NSString* wikidataEditToken;
@property (strong, nonatomic, readonly) NSString* centralAuthToken;

- (instancetype)initAndUploadWikidataDescription:(NSString*)desc
                                    forPageTitle:(MWKTitle*)title
                               wikidataEditToken:(NSString*)wikidataEditToken
                                centralAuthToken:(NSString*)centralAuthToken
                                     withManager:(AFHTTPRequestOperationManager*)manager
                              thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;
@end
