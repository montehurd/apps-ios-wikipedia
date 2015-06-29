
#import "WMFArticleReadMoreProtocol.h"
#import "SessionSingleton.h"
#import "NSURL+WMFRest.h"
#import "SearchResultFetcher.h"
#import "QueuesSingleton.h"

/*
   todo to button this up:
    - make tapping on results load tapped article (add div w click handler around each article)
    - adjust size of image (in img tag)
    - ensure results which have special characters (single quotes etc) in title display properly
 */

__attribute__((constructor)) static void WMFRegisterArticleProtocol() {
    [NSURLProtocol registerClass:[WMFArticleReadMoreProtocol class]];
}

@interface WMFArticleReadMoreProtocol () <FetchFinishedDelegate>

@end

@implementation WMFArticleReadMoreProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    return [[request URL] wmf_conformsToScheme:@"wmf" andHasHost:@"readmore"];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

- (void)startLoading {
    NSString* value = [self.request.URL wmf_getValue];

    (void)[[SearchResultFetcher alloc] initAndSearchForTerm:[SessionSingleton sharedInstance].currentArticle.title.text
                                                 searchType:SEARCH_TYPE_TITLES
                                               searchReason:SEARCH_REASON_SEARCH_STRING_CHANGED
                                                   language:[SessionSingleton sharedInstance].currentArticleSite.language
                                                 maxResults:[value integerValue]
                                                withManager:[QueuesSingleton sharedInstance].searchResultsFetchManager
                                         thenNotifyDelegate:self];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error;
{
    if ([sender isKindOfClass:[SearchResultFetcher class]]) {
        SearchResultFetcher* searchResultFetcher = (SearchResultFetcher*)sender;

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
//NSArray* searchResults = [self removeExcludedArticlesFromSearchResults:searchResultFetcher.searchResults];

                NSArray* searchResults = searchResultFetcher.searchResults;

                NSMutableArray* resultsHTMLArray = @[].mutableCopy;
                for (NSDictionary* result in searchResults) {
                    [resultsHTMLArray addObject:@"<div style=\"padding:3px;background-color:#eee;margin-bottom:20px;\">"];

                    NSString* title = result[@"title"];
                    if (title) {
                        [resultsHTMLArray addObject:[NSString stringWithFormat:@"<div><b>%@</b></div>", title]];
                    }

                    NSString* description = result[@"description"];
                    if (description) {
                        [resultsHTMLArray addObject:[NSString stringWithFormat:@"<div><i>%@</i></div>", description]];
                    }

                    NSString* thumbUrl = result[@"thumbnail"][@"source"];
                    if (thumbUrl) {
                        [resultsHTMLArray addObject:[NSString stringWithFormat:@"<div><img style=\"margin-left:auto; margin-right:auto; display:block;\" src=\"%@\"></div>", thumbUrl]];
                    }

                    [resultsHTMLArray addObject:@"</div>"];
                }

                NSString* resultsHTMLString = [NSString stringWithFormat:@"document.write('%@')", [resultsHTMLArray componentsJoinedByString:@""]];

                [self sendResponseWithData:[resultsHTMLString dataUsingEncoding:NSUTF8StringEncoding]];
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                break;
            case FETCH_FINAL_STATUS_FAILED:

                [self sendResponseWithData:[error.description dataUsingEncoding:NSUTF8StringEncoding]];

                //
                //if (error.code == SEARCH_RESULT_ERROR_NO_MATCHES) {
                //
                //} else {
                //
                //}

                break;
        }
    }
}

- (void)sendResponseWithData:(NSData*)data {
    [self handleResponse:data];
    [self handleResponseData:data];
    [self handleRequestFinished];
}

- (void)handleResponse:(NSData*)data {
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:@"text/plain"
                                           expectedContentLength:data.length
                                                textEncodingName:@"utf-8"];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)handleResponseData:(NSData*)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)handleRequestFinished {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
