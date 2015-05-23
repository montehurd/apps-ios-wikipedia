//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM (NSInteger, WikidataEditTokenErrors) {
    WIKIDATA_EDIT_TOKEN_ERROR_UNKNOWN = 0,
    WIKIDATA_EDIT_TOKEN_ERROR_API     = 1
};

@class AFHTTPRequestOperationManager;

@interface WikidataEditTokenFetcher : FetcherBase

@property (strong, nonatomic, readonly) NSString* editToken;
@property (strong, nonatomic, readonly) NSString* centralAuthToken;

- (instancetype)initAndFetchEditTokenWithCentralAuthToken:(NSString*)centralAuthToken
                                              withManager:(AFHTTPRequestOperationManager*)manager
                                       thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;
@end
