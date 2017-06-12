#import <XCTest/XCTest.h>
#import "WMFArticleFetcher.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKArticle.h"
#import "WMFTestFixtureUtilities.h"
#import "SessionSingleton.h"
#import <Nocilla/Nocilla.h>
#import "Wikipedia-Swift.h"
#import "WMFArticleBaseFetcher_Testing.h"
#import "WMFRandomFileUtilities.h"
#import "WMFAsyncTestCase.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface ArticleFetcherTests : XCTestCase

@property (strong, nonatomic) MWKDataStore *tempDataStore;
@property (strong, nonatomic) WMFArticleFetcher *articleFetcher;

@end

@implementation ArticleFetcherTests

- (void)setUp {
    [super setUp];
    self.tempDataStore = [MWKDataStore temporaryDataStore];

    self.articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.tempDataStore];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [self.tempDataStore removeFolderAtBasePath];
    self.tempDataStore = nil;
    self.articleFetcher = nil;
    [super tearDown];
}

+ (NSArray<NSInvocation *> *)testInvocations {
    return [[NSProcessInfo processInfo] wmf_isTravis] ? @[] : [super testInvocations];
}

- (void)testSuccessfulFetchWritesArticleToDataStoreWithoutDuplicatingData {
    NSURL *siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    NSURL *dummyArticleURL = [siteURL wmf_URLWithTitle:@"Foo"];
    NSURL *url = [NSURL wmf_desktopAPIURLForURL:siteURL];

    NSData *json = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"Obama" ofType:@"json"];

    // TODO: refactor into convenience method
    NSRegularExpression *anyRequestFromTestSite =
        [NSRegularExpression regularExpressionWithPattern:
                                 [NSString stringWithFormat:@"%@.*", [url absoluteString]]
                                                  options:0
                                                    error:nil];

    stubRequest(@"GET", anyRequestFromTestSite)
        .andReturn(200)
        .withHeaders(@{ @"Content-Type": @"application/json" })
        .withBody(json);

    NSRegularExpression *anySummaryRequest =
        [NSRegularExpression regularExpressionWithPattern:
                                 [NSString stringWithFormat:@"%@/api/rest_v1/page/summary/.*", [siteURL absoluteString]]
                                                  options:0
                                                    error:nil];
    stubRequest(@"GET", anySummaryRequest).andReturn(200);

    __block MWKArticle *firstFetchResult;

    __block MWKArticle *secondFetchResult;

    __block MWKArticle *savedArticleAfterFirstFetch;

    WMFArticleFetcher *fetcher = self.articleFetcher;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetching article"];

    [fetcher fetchArticleForURL:dummyArticleURL
        saveToDisk:YES
        progress:NULL
        failure:^(NSError *erorr) {
            XCTFail(@"Recieved error");
            [expectation fulfill];
        }
        success:^(MWKArticle *article) {
            firstFetchResult = article;
            [self.tempDataStore asynchronouslyCacheArticle:article
                                                    toDisk:YES
                                                completion:^{
                                                    savedArticleAfterFirstFetch = [self.tempDataStore articleWithURL:dummyArticleURL];

                                                    assertThat(@([firstFetchResult isDeeplyEqualToArticle:savedArticleAfterFirstFetch]), isTrue());
                                                }];

            [fetcher fetchArticleForURL:dummyArticleURL
                saveToDisk:YES
                progress:NULL
                failure:^(NSError *erorr) {
                    XCTFail(@"Recieved error");
                    [expectation fulfill];
                }
                success:^(MWKArticle *article) {
                    secondFetchResult = article;

                    XCTAssertTrue(secondFetchResult != firstFetchResult,
                                  @"Expected object returned from 2nd fetch to not be identical to 1st.");
                    assertThat(@([secondFetchResult isDeeplyEqualToArticle:firstFetchResult]), isTrue());

                    [self.tempDataStore asynchronouslyCacheArticle:article
                                                            toDisk:YES
                                                        completion:^{
                                                            MWKArticle *savedArticleAfterSecondFetch = [self.tempDataStore articleFromDiskWithURL:dummyArticleURL];
                                                            assertThat(@([savedArticleAfterSecondFetch isDeeplyEqualToArticle:firstFetchResult]), isTrue());
                                                            [expectation fulfill];
                                                        }];
                }];
        }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (NSDictionary *)requestHeaders {
    return self.articleFetcher.operationManager.requestSerializer.HTTPRequestHeaders;
}

- (void)testRequestHeadersForWikipediaAppUserAgent {
    NSString *userAgent = [self requestHeaders][@"User-Agent"];
    assertThat(@([userAgent hasPrefix:@"WikipediaApp/"]), isTrue());
}

- (void)testRequestHeadersForGZIPAcceptEncoding {
    NSString *acceptEncoding = [self requestHeaders][@"Accept-Encoding"];
    assertThat(acceptEncoding, is(equalTo(@"gzip")));
}

- (void)testRequestHeadersForOptInUUID {
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        assertThat(@([self requestHeaders][@"X-WMF-UUID"] != nil), isTrue());
    } else {
        assertThat(@([self requestHeaders][@"X-WMF-UUID"] == nil), isTrue());
    }
}

@end
