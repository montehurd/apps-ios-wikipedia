//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, WikidataDescriptionUploaderErrors) {
    WIKIDATA_UPLOAD_ERROR_UNKNOWN = 0,
    WIKIDATA_UPLOAD_ERROR_SERVER = 1,
    WIKIDATA_UPLOAD_ERROR_FAILURE = 2
};

@class AFHTTPRequestOperationManager;

@interface WikidataDescriptionUploader : FetcherBase

@property (strong, nonatomic, readonly) NSString *desc;
@property (strong, nonatomic, readonly) MWKTitle *title;
@property (strong, nonatomic, readonly) NSString *token;

// Kick-off method. Results are reported to "delegate" via the
// FetchFinishedDelegate protocol method.

-(instancetype)initAndUploadWikidataDescription: (NSString *)desc
                                   forPageTitle: (MWKTitle *)title
                                          token: (NSString *)token
                                    withManager: (AFHTTPRequestOperationManager *)manager
                             thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
