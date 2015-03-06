//
//  ChromeBrowserURLProtocol.m
//  Wikipedia
//
//  Created by Monte Hurd on 3/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "ChromeBrowserURLProtocol.h"

@interface ChromeBrowserURLProtocol ()
@property (nonatomic, strong) NSURLConnection* connection;

@end

@implementation ChromeBrowserURLProtocol

//+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
//
//NSLog(@"loading request %@", a);
//
//    return [super requestIsCacheEquivalent:a toRequest:b];
//}
+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
//NSLog(@"loading request %@", request);


    if ([NSURLProtocol propertyForKey:@"UserAgentSet" inRequest:request] != nil) {
        return NO;
    }

    return YES;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest* newRequest = [self.request mutableCopy];





//NSLog(@"newRequest.URL.pathExtension = %@", newRequest.URL.pathExtension);

    if ([newRequest.URL.pathExtension isEqualToString:@"jpg"]) {
        NSURLResponse* response = [[NSURLResponse alloc] initWithURL:[newRequest URL]
                                                            MIMEType:@"image/png"
                                               expectedContentLength:-1
                                                    textEncodingName:nil];

        NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"lead-default" ofType:@"png"];
        NSData* data        = [NSData dataWithContentsOfFile:imagePath];

        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }





//return;

//   // Here we set the User Agent
//   [newRequest setValue:@"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.2 Safari/537.36 Kifi/1.0f" forHTTPHeaderField:@"User-Agent"];
//




    [NSURLProtocol setProperty:@YES forKey:@"UserAgentSet" inRequest:newRequest];

    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}

@end