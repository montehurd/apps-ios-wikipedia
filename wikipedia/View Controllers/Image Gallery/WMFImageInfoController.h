//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKArticle;
@class MWKImage;
@class MWKImageInfo;
@class MWKImageInfoFetcher;
@class AFHTTPRequestOperationManager;
@protocol MWKImageInfoRequest;

@class WMFImageInfoController;
@protocol WMFImageInfoControllerDelegate <NSObject>

- (void)imageInfoControllerDidFetchInfo:(WMFImageInfoController*)controller;

- (void)imageInfoControllerFetchFailed:(WMFImageInfoController*)controller error:(NSError*)error;

@end

@interface WMFImageInfoController : NSObject

@property (nonatomic, strong, readonly) MWKArticle* article;

@property (nonatomic, weak) id<WMFImageInfoControllerDelegate> delegate;

/// Number of image info titles to request at once.
@property (nonatomic, readonly) NSUInteger infoBatchSize;

/// Lazily calculated snapshot of the uniqued images in the receiver's @c article.
/// @warning Only write to this property during tests.
@property (nonatomic, readwrite) NSArray* uniqueArticleImages;

///
/// @name Initialization
///

/// Initialize with @c article, letting the receiver create the default @c fetcher and @c imageFetcher.
- (instancetype)initWithArticle:(MWKArticle*)article batchSize:(NSUInteger)batchSize;

/// Designated initializer.
- (instancetype)initWithArticle:(MWKArticle*)article
                      batchSize:(NSUInteger)batchSize
                    infoFetcher:(MWKImageInfoFetcher*)fetcher;

///
/// @name Fetching
///

/// Fetch the next batch of image info, if @c index is within @c threshold of the next batch.
- (id<MWKImageInfoRequest>)fetchNextBatchIfIndex:(NSInteger)index isWithinDistanceOfNextBatch:(NSInteger)threshold;

/// Attempt to fetch image info for the batch which contains @c index.
- (id<MWKImageInfoRequest>)fetchBatchContainingIndex:(NSInteger)index;

///
/// @name Getters
///

/// @return The @c MWKImageInfo object which is associated with @c image, or @c nil if none exists.
- (MWKImageInfo*)infoForImage:(MWKImage*)image;

@end
