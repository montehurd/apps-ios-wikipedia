//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFURLCache.h"
#import "SessionSingleton.h"
#import "FBTweak+WikipediaZero.h"
#import "MWKArticle.h"
#import "MWKImage.h"
#import "Wikipedia-Swift.h"
#import "WMFURLCacheStrings.h"

@implementation WMFURLCache

- (void)permanentlyCacheImagesForArticle:(MWKArticle*)article {
    NSArray *imageURLsForSaving = [article imageURLsForSaving];
    for (NSURL* url in imageURLsForSaving) {
        @autoreleasepool {
            NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
            
            NSCachedURLResponse* response = [self cachedResponseForRequest:request];
            
            if (response.data.length > 0) {
                [[WMFImageController sharedInstance] cacheImageData:response.data url:url MIMEType:response.response.MIMEType];
            }
        }
    };
}

- (UIImage*)cachedImageForURL:(NSURL*)url {
    if (!url) {
        return nil;
    }

    NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

    NSCachedURLResponse* response = [self cachedResponseForRequest:request];

    if (response.data.length > 0) {
        return [UIImage imageWithData:response.data];
    } else if ([url wmf_isSchemeless]) {
        return [self cachedImageForURL:[url wmf_urlByPrependingSchemeIfSchemeless]];
    } else {
        return nil;
    }
}

- (BOOL)isMIMETypeImage:(NSString*)type {
    return [type hasPrefix:@"image"];
}

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request {
    NSString* mimeType = [request.URL wmf_mimeTypeForExtension];
    if ([self isMIMETypeImage:mimeType] && [[WMFImageController sharedInstance] hasDataOnDiskForImageWithURL:request.URL]) {
        WMFTypedImageData* typedData = [[WMFImageController sharedInstance] typedDiskDataForImageWithURL:request.URL];
        NSData* data                 = typedData.data;
        NSString* mimeType           = typedData.MIMEType;

        if (data.length > 0) {
            NSURLResponse* response             = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:data.length textEncodingName:nil];
            NSCachedURLResponse* cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            return cachedResponse;
        }
    }

    return [super cachedResponseForRequest:request];
}

- (void)storeCachedResponse:(NSCachedURLResponse*)cachedResponse forRequest:(NSURLRequest*)request {
    [super storeCachedResponse:cachedResponse forRequest:request];

    if ([self isJsonResponse:cachedResponse fromWikipediaAPIRequest:request]) {
        //NSLog(@"Processing zero headers for cached repsonse from %@", request);
//TODO: should refactor a lot of this into ZeroConfigState itself and make it thread safe so we can do its work off the main thread.
        [self processZeroHeaders:cachedResponse.response];
    }
}

- (BOOL)isJsonResponse:(NSCachedURLResponse*)cachedResponse fromWikipediaAPIRequest:(NSURLRequest*)request  {
    return ([[request URL].host hasSuffix:WMFURLCacheWikipediaHost] && [cachedResponse.response.MIMEType isEqualToString:WMFURLCacheJsonMIMEType]);
}

- (void)processZeroHeaders:(NSURLResponse*)response {
    NSHTTPURLResponse* httpUrlResponse = (NSHTTPURLResponse*)response;
    NSDictionary* headers              = httpUrlResponse.allHeaderFields;
    
//Fix me: re-name xZeroRatedHeader

    /*
    NSString* xCarrierFromHeader         = [headers objectForKey:WMFURLCacheXCarrier];
    
    NSString* xCarrierMetaFromHeader             = [headers objectForKey:WMFURLCacheXCarrierMeta];
    
    
    BOOL zeroRatedHeaderPresent        = xCarrierFromHeader != nil;
    NSString* xcs                      = [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier;
    BOOL zeroProviderChanged           = zeroRatedHeaderPresent && ![xCarrierFromHeader isEqualToString:xcs];
    BOOL zeroDisposition               = [SessionSingleton sharedInstance].zeroConfigState.disposition;

    // enable this tweak to make the cache pretend it found W0 headers in the response
    if ([FBTweak wmf_shouldMockWikipediaZeroHeaders]) {
        zeroRatedHeaderPresent = YES;
        xCarrierFromHeader       = WMFURLCache00000;
    }

    if (zeroRatedHeaderPresent && (!zeroDisposition || zeroProviderChanged)) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier  = xCarrierFromHeader;
    } else if (!zeroRatedHeaderPresent && zeroDisposition) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier  = nil;
    }
*/
    
    
    
    
    
    
    
    
    
    /*
     TODO:
     - look at disposition setter chain of events
     - double check the hasChangeHappenedToCarrier with nil
     */
    
    
    bool zeroEnabled = [SessionSingleton sharedInstance].zeroConfigState.disposition;
    
    NSString* xCarrierFromHeader = [headers objectForKey:WMFURLCacheXCarrier];
    bool hasZeroHeader = (xCarrierFromHeader != nil);
    if (hasZeroHeader) {
        NSString* xCarrierMetaFromHeader = [headers objectForKey:WMFURLCacheXCarrierMeta];
//        if (xCarrierMetaFromHeader == nil) {
//            xCarrierMetaFromHeader = @"";
//        }
        if ([self hasChangeHappenedToCarrier:xCarrierFromHeader orMeta:xCarrierMetaFromHeader]) {
//            identifyZeroCarrier(xCarrierFromHeader, xCarrierMetaFromHeader);
            
            [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier  = xCarrierFromHeader;
            [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrierMeta  = xCarrierMetaFromHeader;
            [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
            
        }

    }else if(zeroEnabled) {
//        zeroOff();
        [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier  = nil;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXCarrierMeta  = nil;
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;

    }
    
    /*
    boolean hasZeroHeader = result.getHeaders().containsKey("X-Carrier");
    if (hasZeroHeader) {
        String xCarrierFromHeader = result.getHeaders().get("X-Carrier").get(0);
        String xCarrierMetaFromHeader = "";
        if (result.getHeaders().containsKey("X-Carrier-Meta")) {
            xCarrierMetaFromHeader = result.getHeaders().get("X-Carrier-Meta").get(0);
        }
        if (eitherChanged(xCarrierFromHeader, xCarrierMetaFromHeader)) {
            identifyZeroCarrier(xCarrierFromHeader, xCarrierMetaFromHeader);
        }
    } else if (zeroEnabled) {
        zeroOff();
    }
    */
}

- (BOOL) hasChangeHappenedToCarrier:(NSString*)xCarrier orMeta:(NSString*)xCarrierMeta {
    return !(
             [[SessionSingleton sharedInstance].zeroConfigState.partnerXCarrier isEqualToString:xCarrier]
             &&
             [[SessionSingleton sharedInstance].zeroConfigState.partnerXCarrierMeta isEqualToString:xCarrierMeta]
             );
}

@end
