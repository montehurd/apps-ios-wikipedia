//
//  WMFImageInfoControllerTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#define HC_SHORTHAND 1
#define MOCKITO_SHORTHAND 1

#import <UIKit/UIKit.h>
#import <BlocksKit/BlocksKit.h>
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

#import "MWKImage+AssociationTestUtils.h"
#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"
#import "WMFAsyncTestCase.h"
#import "WMFImageInfoController_Private.h"
#import "MWKImageList.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKTitle.h"
#import "MWKSite.h"
#import "NSArray+WMFShuffle.h"
#import "WMFRangeUtils.h"

static NSValue* WMFBoxedRangeMake(NSUInteger loc, NSUInteger len) {
    return [NSValue valueWithRange:NSMakeRange(loc, len)];
}

@interface WMFImageInfoControllerTests : WMFAsyncTestCase <WMFImageInfoControllerDelegate>
@property WMFImageInfoController* controller;
@property MWKArticle* testArticle;
@property MWKImageInfoFetcher* mockInfoFetcher;
@property id<WMFImageInfoControllerDelegate> mockDelegate;
@property MWKDataStore* tmpDataStore;
@end

@implementation WMFImageInfoControllerTests

- (void)setUp {
    [super setUp];

    self.mockInfoFetcher = mock([MWKImageInfoFetcher class]);
    self.tmpDataStore    = [MWKDataStore temporaryDataStore];
    MWKTitle* testTitle =
        [MWKTitle titleWithString:@"foo"
                             site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
    self.testArticle =
        [[MWKArticle alloc] initWithTitle:testTitle dataStore:self.tmpDataStore];

    self.mockDelegate = mockProtocol(@protocol(WMFImageInfoControllerDelegate));
    self.controller = [[WMFImageInfoController alloc] initWithArticle:self.testArticle
                                                            batchSize:2
                                                          infoFetcher:self.mockInfoFetcher];
    self.controller.delegate = self;
    }

- (void)tearDown {
    [self.tmpDataStore removeFolderAtBasePath];
    [super tearDown];
}

#pragma mark - Tests

- (void)testReadsFromDataStoreLazilyAndPopulatesFetchedIndices {
    MWKImageList* mockImageList = mock([MWKImageList class]);
    MWKDataStore* mockDataStore = mock([MWKDataStore class]);
    MWKArticle* mockArticle     = mock([MWKArticle class]);
    NSArray* testImages         = [self generateImages:5];
    NSRange preFetchedRange     = NSMakeRange(0, 2);
    NSArray* expectedImageInfo  = [[MWKImageInfo mappedFromImages:testImages] subarrayWithRange:preFetchedRange];

    [given([mockArticle dataStore]) willReturn:mockDataStore];
    [given([mockArticle images]) willReturn:mockImageList];
    [given([mockImageList uniqueLargestVariants]) willReturn:testImages];
    [given([mockDataStore imageInfoForArticle:mockArticle]) willReturn:expectedImageInfo];

    WMFImageInfoController* controller = [[WMFImageInfoController alloc] initWithArticle:mockArticle
                                                                               batchSize:2
                                                                             infoFetcher:self.mockInfoFetcher];

    assertThat(controller.indexedImageInfo.allValues, containsItemsInCollectionInAnyOrder(expectedImageInfo));
    assertThat(controller.uniqueArticleImages, is(testImages));
    assertThat(controller.fetchedIndices, is(equalTo([NSIndexSet indexSetWithIndexesInRange:preFetchedRange])));
}

- (void)testBatchRange {
    [self populateControllerWithNumberOfImages:10];
    for (int i = 0; i < 10; i++) {
        NSRange batchRange = [self.controller batchRangeForTargetIndex:i];
        assertThat(@(batchRange.length), is(equalToInt(self.controller.infoBatchSize)));
        assertThat(@(batchRange.location), is(lessThanOrEqualTo(@(i))));
        assertThat(@(batchRange.location + batchRange.length), is(greaterThanOrEqualTo(@(i))));
    }
}

- (void)testBatchRangeWithThreshold {
    [self populateControllerWithNumberOfImages:10];
    for (int i = 1; i < 9; i+=2) {
        NSRange batchRange = [self.controller batchRangeForTargetIndex:i];
        NSRange nextRange = [self.controller batchRangeForTargetIndex:WMFRangeGetMaxIndex(batchRange) + 1];
        NSRange rangeWithThreshold = [self.controller nextBatchRangeForTargetIndex:i withThreshold:1];
        assertThat(@(rangeWithThreshold.location), is(equalToInt(nextRange.location)));
        assertThat(@(rangeWithThreshold.length), is(equalToInt(nextRange.length)));
    }

    for (int i = 0; i < 9; i+=2) {
        assertThat(@(WMFRangeIsNotFoundOrEmpty([self.controller nextBatchRangeForTargetIndex:i withThreshold:1])),
                   describedAs(@"nextBatchRange returns NotFound when target index is outside threshold",
                   isTrue(), nil));
    }

    assertThat(@(WMFRangeIsNotFoundOrEmpty([self.controller nextBatchRangeForTargetIndex:9 withThreshold:1])),
               describedAs(@"nextBatchRange returns NotFound when the next range is out of bounds", isTrue(), nil));
}

- (void)testIterativeFetchOfAllItems {
    [self verifySuccessfulFetchesForRanges:[self createNumBatches:10]];
}

- (void)testOutOfOrderFetchOfAllItems {
    [self verifySuccessfulFetchesForRanges:[[self createNumBatches:10] wmf_shuffledCopy]];
}

- (void)testFetchingItemsThatWereAlreadyFetchedHasNoEffect {
    NSArray* fetchedBatches = [self createNumBatches:10];
    [self verifySuccessfulFetchesForRanges:fetchedBatches];

    for (NSValue* boxedRange in fetchedBatches) {
        NSRange range = [boxedRange rangeValue];
        [self.controller fetchBatchContainingIndex:range.location];
    }

    [MKTVerifyCount(self.mockInfoFetcher, times(10)) fetchInfoForPageTitles:anything()
                                                                   fromSite:anything()
                                                                    success:anything()
                                                                    failure:anything()];
}

- (void)testErrorHandling {
    [self populateControllerWithNumberOfImages:5];
    NSRange attemptedBatch = [self.controller batchRangeForTargetIndex:0];

    [self.controller fetchBatchContainingIndex:0];

    assertThat(@([self.controller.fetchedIndices containsIndexesInRange:attemptedBatch]),
               describedAs(@"batch range to be optimistically marked as 'fetched'",
                           isTrue(), nil));

    PushExpectation();

    NSError* dummyError = [NSError new];
    [self mockInfoFetcherFailure:dummyError forTitlesInRange:attemptedBatch];

    WaitForExpectations();

    assertThat(@([self.controller.fetchedIndices containsIndexesInRange:attemptedBatch]),
               describedAs(@"batch to be reset after error handling, allowing it to be fetched again",
                           isFalse(), nil));

    [MKTVerify(self.mockDelegate) imageInfoControllerFetchFailed:self.controller error:dummyError];
}

#pragma mark - Range test utils

- (void)verifySuccessfulFetchesForRanges:(NSArray*)ranges {
    NSUInteger numImages = [ranges count] * self.controller.infoBatchSize;
    NSArray* testImages  = [self populateControllerWithNumberOfImages:numImages];

    NSMutableArray* accumulatedFetchedImageInfos = [NSMutableArray arrayWithCapacity:numImages];

    void (^ verifyDataStoreAndControllerData)() = ^{
        assertThat(self.controller.indexedImageInfo.allValues,
                   containsItemsInCollectionInAnyOrder(accumulatedFetchedImageInfos));

        assertThat([self.tmpDataStore imageInfoForArticle:self.testArticle],
                   containsItemsInCollectionInAnyOrder(accumulatedFetchedImageInfos));
    };

    for (NSValue* boxedRange in ranges) {
        assertThat(@([self.controller hasFetchedAllItems]), isFalse());
        [self fetchRangeSuccessfully:boxedRange.rangeValue fromImages:testImages withAccumulator:accumulatedFetchedImageInfos];
        verifyDataStoreAndControllerData();
    }

    assertThat(@([self.controller hasFetchedAllItems]), isTrue());

    NSUInteger expectedSuccessCallbacks = ranges.count;
    [MKTVerifyCount(self.mockDelegate, times(expectedSuccessCallbacks))
     imageInfoControllerDidFetchInfo:self.controller];

    assertThat(accumulatedFetchedImageInfos, hasCountOf(testImages.count));

    verifyDataStoreAndControllerData();
}

- (void)fetchRangeSuccessfully:(NSRange)range
                    fromImages:(NSArray*)testImages
               withAccumulator:(NSMutableArray*)accumulatedInfos {
    [self.controller fetchBatchContainingIndex:range.location];

    assertThat(@([self.controller.fetchedIndices containsIndexesInRange:range]),
               describedAs(@"Ranges should be marked as fetched the first time they're requested", isTrue(), nil));

    PushExpectation();

    NSArray* imageInfoForCurrentBatch = [MWKImageInfo mappedFromImages:[testImages subarrayWithRange:range]];
    [accumulatedInfos addObjectsFromArray:imageInfoForCurrentBatch];

    [self mockInfoFetcherSuccess:range];

    WaitForExpectations();
}

#pragma mark - WMFImageInfoControllerDelegate

- (void)imageInfoControllerFetchFailed:(WMFImageInfoController*)controller error:(NSError*)error {
    [self popExpectationAfter:^{
        [self.mockDelegate imageInfoControllerFetchFailed:controller error:error];
    }];
}

- (void)imageInfoControllerDidFetchInfo:(WMFImageInfoController*)controller {
    [self popExpectationAfter:^{
        [self.mockDelegate imageInfoControllerDidFetchInfo:controller];
    }];
}

#pragma mark - Test Utils

- (NSArray*)createNumBatches:(NSUInteger)n {
    NSMutableArray* ranges = [NSMutableArray arrayWithCapacity:n];
    for (int i = 0; i < n; i++) {
        [ranges addObject:WMFBoxedRangeMake(i * self.controller.infoBatchSize, self.controller.infoBatchSize)];
    }
    return [ranges copy];
}

- (void)mockInfoFetcherSuccess:(NSRange)range {
    MKTArgumentCaptor* successBlockCaptor = [MKTArgumentCaptor new];
    NSArray* expectedTitles               = [self.controller.imageFilePageTitles subarrayWithRange:range];
    [MKTVerify(self.mockInfoFetcher) fetchInfoForPageTitles:expectedTitles
                                                   fromSite:anything()
                                                    success:[successBlockCaptor capture]
                                                    failure:anything()];
    void (^ successBlock)(NSArray*) = [successBlockCaptor value];
    successBlock([MWKImageInfo mappedFromImages:[self.controller.uniqueArticleImages subarrayWithRange:range]]);
}

- (void)mockInfoFetcherFailure:(NSError*)error forTitlesInRange:(NSRange)range {
    MKTArgumentCaptor* errorBlockCaptor = [MKTArgumentCaptor new];
    NSArray* expectedTitles             = [self.controller.imageFilePageTitles subarrayWithRange:range];
    [MKTVerify(self.mockInfoFetcher) fetchInfoForPageTitles:expectedTitles
                                                   fromSite:anything()
                                                    success:anything()
                                                    failure:[errorBlockCaptor capture]];
    void (^ errorBlock)(NSError*) = [errorBlockCaptor value];
    errorBlock(error);
}

- (NSArray*)populateControllerWithNumberOfImages:(NSUInteger)count {
    NSArray* images = [self generateImages:count];
    [self populateControllerWithImages:images];
    return images;
}

- (NSArray*)generateImages:(NSUInteger)count {
    NSMutableArray* names = [NSMutableArray new];
    for (NSUInteger i = 0; i < count; i++) {
        [names addObject:[NSString stringWithFormat:@"foo%lu", i]];
    }
    return [self generateImagesWithFiles:names];
}

- (NSArray*)generateImagesWithFiles:(NSArray*)files {
    return [files bk_map:^id (NSString* filename) {
        NSString* sourceURL =
            [NSString stringWithFormat:@"//foobar/%@.jpg/440px-%@.jpg", filename, filename];
        return [[MWKImage alloc] initWithArticle:self.testArticle sourceURL:sourceURL];
    }];
}

- (void)populateControllerWithImages:(NSArray*)uniqueImages {
    [self.controller setUniqueArticleImages:uniqueImages];
}

@end
