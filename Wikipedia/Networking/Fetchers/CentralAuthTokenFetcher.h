//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM (NSInteger, CentralAuthTokenErrorType) {
    AUTH_TOKEN_ERROR_UNKNOWN = 0,
    AUTH_TOKEN_ERROR_API     = 1
};

@class AFHTTPRequestOperationManager;

@interface CentralAuthTokenFetcher : FetcherBase

@property (strong, nonatomic, readonly) NSString* token;
@property (strong, nonatomic, readonly) MWKSite* site;
@property (strong, nonatomic, readonly) id userData;

- (instancetype)initAndFetchCentralAuthTokenForSite:(MWKSite*)site
                                           userData:(id)userData
                                        withManager:(AFHTTPRequestOperationManager*)manager
                                 thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;

@end
