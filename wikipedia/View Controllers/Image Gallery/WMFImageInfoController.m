//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageInfoController_Private.h"

#import <BlocksKit/BlocksKit.h>
#import "WMFRangeUtils.h"
#import "NSArray+BKIndex.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"

#if 1 && DEBUG
#define IICLog(...) NSLog(__VA_ARGS__)
#else
#define IICLog(...)
#endif

@implementation WMFImageInfoController
@synthesize imageInfoFetcher    = _imageInfoFetcher;
@synthesize indexedImageInfo    = _indexedImageInfo;
@synthesize uniqueArticleImages = _uniqueArticleImages;
@synthesize imageFilePageTitles = _imageFilePageTitles;
@synthesize fetchedIndices      = _fetchedIndices;

- (instancetype)initWithArticle:(MWKArticle*)article batchSize:(NSUInteger)batchSize {
    return [self initWithArticle:article batchSize:batchSize infoFetcher:[[MWKImageInfoFetcher alloc] initWithDelegate:nil]];
}

- (instancetype)initWithArticle:(MWKArticle*)article
                      batchSize:(NSUInteger)batchSize
                    infoFetcher:(MWKImageInfoFetcher*)fetcher {
    self = [super init];
    if (self) {
        _article          = article;
        _dataStore        = article.dataStore;
        _imageInfoFetcher = fetcher;
        _infoBatchSize    = batchSize;
    }
    return self;
}

#pragma mark - Setters

- (void)setInfoBatchSize:(NSUInteger)infoBatchSize {
    NSAssert(infoBatchSize <= 50, @"Only up to 50 titles can be retrieved at a time.");
    _infoBatchSize = infoBatchSize;
}

#pragma mark - Accessors

- (NSArray*)uniqueArticleImages {
    if (!_uniqueArticleImages) {
        _uniqueArticleImages = [WikipediaAppUtils isDeviceLanguageRTL] ?
                               [[[self.article.images uniqueLargestVariants] reverseObjectEnumerator] allObjects]
                               : [self.article.images uniqueLargestVariants];
    }
    return _uniqueArticleImages;
}

- (NSDictionary*)indexedImageInfo {
    if (!_indexedImageInfo) {
        _indexedImageInfo = WMFIndexImageInfo([self.dataStore imageInfoForArticle:self.article])
                            ? : [NSMutableDictionary new];
    }
    return _indexedImageInfo;
}

- (NSArray*)imageFilePageTitles {
    if (!_imageFilePageTitles) {
        _imageFilePageTitles = [[self uniqueArticleImages] bk_map:^NSString*(MWKImage* image) {
            NSAssert(image.canonicalFilename.length,
                     @"Unable to form canonical filename from image: %@",
                     image.sourceURL);
            return [@"File:" stringByAppendingString:image.canonicalFilename];
        }];
    }
    return _imageFilePageTitles;
}

- (NSMutableIndexSet*)fetchedIndices {
    if (!_fetchedIndices) {
        if ([self.indexedImageInfo count]) {
            _fetchedIndices =
                [[self.indexedImageInfo allValues] bk_reduce:[NSMutableIndexSet new]
                                                   withBlock:^NSMutableIndexSet*(NSMutableIndexSet* idxs,
                                                                                 MWKImageInfo* info) {
                NSInteger infoIndex =
                    [self.uniqueArticleImages indexOfObjectPassingTest:^BOOL (MWKImage* img,
                                                                              NSUInteger idx,
                                                                              BOOL* stop) {
                    if ([img isAssociatedWithInfo:info]) {
                        *stop = YES;
                        return YES;
                    } else {
                        return NO;
                    }
                }];
                if (infoIndex != NSNotFound) {
                    [idxs addIndex:infoIndex];
                }
                return idxs;
            }];
        } else {
            _fetchedIndices = [NSMutableIndexSet new];
        }
    }
    return _fetchedIndices;
}

- (BOOL)hasFetchedAllItems {
    return [self.fetchedIndices containsIndexesInRange:NSMakeRange(0, self.uniqueArticleImages.count)];
}

- (MWKImageInfo*)infoForImage:(MWKImage*)image {
    return self.indexedImageInfo[image.infoAssociationValue];
}

#pragma mark - Public Fetch

- (id<MWKImageInfoRequest>)fetchNextBatchIfIndex:(NSInteger)index isWithinDistanceOfNextBatch:(NSInteger)threshold {
    return [self fetchBatch:[self nextBatchRangeForTargetIndex:index withThreshold:threshold]];
}

- (id<MWKImageInfoRequest>)fetchBatchContainingIndex:(NSInteger)index {
    return [self fetchBatch:[self batchRangeForTargetIndex:index]];
}

#pragma mark - Private Fetch

- (NSRange)nextBatchRangeForTargetIndex:(NSUInteger)index withThreshold:(NSUInteger)threshold {
    NSRange const testRange = [self batchRangeForTargetIndex:index];
    if (!WMFRangeIsNotFoundOrEmpty(testRange)) {
        NSUInteger const testMaxIndex = WMFRangeGetMaxIndex(testRange);
        NSParameterAssert(testMaxIndex != NSNotFound);
        NSUInteger nextRangeLoc = testMaxIndex + 1;
        if (nextRangeLoc < self.uniqueArticleImages.count) {
            NSRange const nextRange = [self batchRangeForTargetIndex:nextRangeLoc];
            if (!WMFRangeIsNotFoundOrEmpty(nextRange)) {
                if (index >= (nextRange.location - threshold)) {
                    return nextRange;
                } else {
                    IICLog(@"Index '%lu' is not within %lu of next batch %@",
                           index,
                           threshold,
                           NSStringFromRange(nextRange));
                }
            }
        } else {
            IICLog(@"Reached end of images when asking for batch after '%lu' with threshold '%lu'",
                   index, threshold);
        }
    }
    return WMFRangeMakeNotFound();
}

- (NSRange)batchRangeForTargetIndex:(NSUInteger)index {
    NSParameterAssert(index < self.uniqueArticleImages.count);
    NSUInteger const start = floorf(index / (float)self.infoBatchSize) * self.infoBatchSize;
    NSRange const range    = NSMakeRange(start, MIN(self.infoBatchSize, self.uniqueArticleImages.count - start));
    NSParameterAssert(range.location <= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) >= index);
    NSParameterAssert(WMFRangeGetMaxIndex(range) <= self.uniqueArticleImages.count);
    return range;
}

- (id<MWKImageInfoRequest>)fetchBatch:(NSRange)batch {
    if (WMFRangeIsNotFoundOrEmpty(batch)) {
        return nil;
    } else if ([self.fetchedIndices containsIndexesInRange:batch]) {
        IICLog(@"Batch %@ has already been fetched.", NSStringFromRange(batch));
        return nil;
    }
    NSParameterAssert(batch.length <= self.infoBatchSize);
    IICLog(@"Fetching batch: %@", NSStringFromRange(batch));

    // optimistically add batch to fetched indices, then remove it if the request fails
    [self.fetchedIndices addIndexesInRange:batch];

    NSArray* titlesToFetch = [self.imageFilePageTitles subarrayWithRange:batch];
    NSParameterAssert(titlesToFetch.count > 0);

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    __weak __typeof__((self)) weakSelf = self;
    return [self.imageInfoFetcher fetchInfoForPageTitles:titlesToFetch
                                                fromSite:self.article.site
                                                 success:^(NSArray* infoObjects) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        __typeof__((weakSelf)) strSelf = weakSelf;
        if (!strSelf) {
            return;
        }
        NSDictionary* indexedInfo = WMFIndexImageInfo(infoObjects);
        dispatch_async(dispatch_get_main_queue(), ^{
            [strSelf.indexedImageInfo setValuesForKeysWithDictionary:indexedInfo];
            // !!!: we should have already read any pre-existing image info from the data store
            [[strSelf dataStore] saveImageInfo:strSelf.indexedImageInfo.allValues forArticle:strSelf.article];
            [strSelf.delegate imageInfoControllerDidFetchInfo:strSelf];
        });
    }
                                                 failure:^(NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        __typeof__((weakSelf)) strSelf = weakSelf;
        BOOL wasCancelled = [error.domain isEqualToString:NSURLErrorDomain]
                            && error.code == NSURLErrorCancelled;
        if (strSelf) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strSelf.fetchedIndices removeIndexesInRange:batch];
                if (!wasCancelled) {
                    [strSelf.delegate imageInfoControllerFetchFailed:strSelf error:error];
                }
            });
        }
    }];
}

@end
