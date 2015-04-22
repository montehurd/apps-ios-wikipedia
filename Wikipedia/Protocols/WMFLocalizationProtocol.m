//  Created by Monte Hurd on 4/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFLocalizationProtocol.h"
#import "WikipediaAppUtils.h"
#import "NSURL+WMFRest.h"

__attribute__((constructor)) static void WMFRegisterLocalizationProtocol() {
  [NSURLProtocol registerClass:[WMFLocalizationProtocol class]];
}

@interface WMFLocalizationProtocol () <NSURLConnectionDelegate>

@end

@implementation WMFLocalizationProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [[request URL] wmf_conformsToScheme:@"wmf" andHasKey:@"localize"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// Some handling below based on http://devmonologue.com/ios/tutorials/nsurlprotocol-tutorial/

- (void)startLoading {
    NSString *key = [self getKeyFromURL:self.request.URL];
    NSString *translation = [self getTranslationForKey:key];

    NSData* localizationStringData = [translation dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendResponseWithData:localizationStringData];
}

-(NSString *)getKeyFromURL:(NSURL *)url {
    if (self.request.URL.path.length > 1) {
        return [self.request.URL.path substringFromIndex:1];
    }else{
        NSString *msg = [NSString stringWithFormat:@"Not able to extract translation key from url: '%@'", url.absoluteString];
        NSAssert(nil, msg);
        return nil;
    }
}

-(NSString *)getTranslationForKey:(NSString *)key {
    return MWLocalizedString(key, nil);
}

- (void)sendResponseWithData:(NSData*)data{
    [self handleResponse:data];
    [self handleResponseData:data];
    [self handleRequestFinished];
}

- (void)handleResponse:(NSData*)data{
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:@"text/plain"
                                           expectedContentLength:data.length
                                                textEncodingName:@"utf-8"];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)handleResponseData:(NSData*)data{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)handleRequestFinished{
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {

}

@end
