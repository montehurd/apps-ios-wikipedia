//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ArticleFetcher.h"
#import "WMFNetworkUtilities.h"
#import "Defines.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"
#import "AFHTTPRequestOperationManager.h"
#import "ReadingActionFunnel.h"
#import "NSString+Extras.h"
#import "NSObject+Extras.h"
#import "MWNetworkActivityIndicatorManager.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "WMFArticleParsing.h"
#import "ZeroConfigState.h"
#import "MediaWikiKit.h"

// Reminder: For caching reasons, don't do "(scale * 320)" here.
#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@interface ArticleFetcher ()

@property (nonatomic, assign, readwrite) BOOL sendUsageReports;
@property (nonatomic, assign, readwrite) BOOL fetchLeadSectionOnly;

@end

@implementation ArticleFetcher

- (AFHTTPRequestOperation*)fetchSectionsForTitle:(MWKTitle*)title
                                     inDataStore:(MWKDataStore*)store
                            fetchLeadSectionOnly:(BOOL)fetchLeadSectionOnly
                                     withManager:(AFHTTPRequestOperationManager*)manager
                                   progressBlock:(WMFProgressHandler)progress
                                 completionBlock:(WMFArticleHandler)completion
                                      errorBlock:(WMFErrorHandler)errorHandler {
    NSAssert(title.text != nil, @"Title text nil");
    NSAssert(store != nil, @"Store nil");
    NSAssert(manager != nil, @"Manager nil");

    self.fetchLeadSectionOnly = fetchLeadSectionOnly;
    if (!title.text) {
        return nil;
    }
    if (!title.site.language) {
        return nil;
    }

    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:title.site.language];

    NSDictionary* params = [self getParamsForTitle:title];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [self addMCCMNCHeaderToRequestSerializer:manager.requestSerializer ifAppropriateForURL:url];

    AFHTTPRequestOperation* operation = [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        __block NSData* localResponseObject = responseObject;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            //NSLog(@"JSON: %@", responseObject);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            MWKArticle* article = [store articleWithTitle:title];
            // Convert the raw NSData response to a dictionary.
            NSDictionary* responseDictionary = [self dictionaryFromDataResponse:localResponseObject];

            @try {
                [article importMobileViewJSON:responseDictionary[@"mobileview"]];
                [article save];
            }@catch (NSException* e) {
                NSLog(@"%@", e);
                NSError* error = [NSError errorWithDomain:@"ArticleFetcher" code:666 userInfo:@{ @"exception": e }];
                if (errorHandler) {
                    errorHandler(error);
                }
                return;
            }

            for (int section = 0; section < [article.sections count]; section++) {
                (void)article.sections[section].images;             // hack
                WMFInjectArticleWithImagesFromSection(article, article.sections[section].text, section);
            }

            // Update article and section image data.
            // Reminder: don't recall article save here as it expensively re-writes all section html.
            [article saveWithoutSavingSectionText];

            if (completion) {
                completion(article);
            }
        });
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        NSLog(@"Error: %@", error);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        if (errorHandler) {
            errorHandler(error);
        }
    }];

    __block CGFloat downloadProgress = 0.0;

    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead > 0) {
            downloadProgress = (CGFloat)(totalBytesRead / totalBytesExpectedToRead);
        } else {
            downloadProgress += 0.05;
        }

        if (progress) {
            progress(downloadProgress);
        }
    }];

    return operation;
}

- (NSDictionary*)getParamsForTitle:(MWKTitle*)title {
    NSMutableDictionary* params = @{
        @"format": @"json",
        @"action": @"mobileview",
        @"sectionprop": WMFJoinedPropertyParameters(@[@"toclevel", @"line", @"anchor", @"level", @"number",
                                                      @"fromtitle", @"index"]),
        @"noheadings": @"true",
        @"sections": @"all",
        @"page": title.text,
        @"thumbwidth": @(LEAD_IMAGE_WIDTH),
        @"prop": WMFJoinedPropertyParameters(@[@"sections", @"text", @"lastmodified", @"lastmodifiedby",
                                               @"languagecount", @"id", @"protection", @"editable", @"displaytitle",
                                               @"thumb", @"description", @"image"])
    }.mutableCopy;

    if (self.fetchLeadSectionOnly) {
        params[@"sections"] = @0;
    }

    return params;
}

// Add the MCC-MNC code asn HTTP (protocol) header once per session when user using cellular data connection.
// Logging will be done in its own file with specific fields. See the following URL for details.
// http://lists.wikimedia.org/pipermail/wikimedia-l/2014-April/071131.html

- (void)addMCCMNCHeaderToRequestSerializer:(AFHTTPRequestSerializer*)requestSerializer
                       ifAppropriateForURL:(NSURL*)url {
    /* MCC-MNC logging is only turned with an API hook */
    if (
        ![SessionSingleton sharedInstance].shouldSendUsageReports
        ||
        [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC
        ||
        ([url.host rangeOfString:@".m.wikipedia.org"].location == NSNotFound)
        ||
        ([url.relativePath rangeOfString:@"/w/api.php"].location == NSNotFound)
        ) {
        [requestSerializer setValue:nil forHTTPHeaderField:@"X-MCCMNC"];

        return;
    } else {
        CTCarrier* mno = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
        if (mno) {
            SCNetworkReachabilityRef reachabilityRef =
                SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
            SCNetworkReachabilityFlags reachabilityFlags;
            SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);

            // The following is a good functioning mask in practice for the case where
            // cellular is being used, with wifi not on / there are no known wifi APs.
            // When wifi is on with a known wifi AP connection, kSCNetworkReachabilityFlagsReachable
            // is present, but kSCNetworkReachabilityFlagsIsWWAN is not present.
            if (reachabilityFlags == (
                    kSCNetworkReachabilityFlagsIsWWAN
                    |
                    kSCNetworkReachabilityFlagsReachable
                    |
                    kSCNetworkReachabilityFlagsTransientConnection
                    )
                ) {
                // In iOS disentangling network MCC-MNC from SIM MCC-MNC not in API yet.
                // So let's use the same value for both parts of the field.
                NSString* mcc    = mno.mobileCountryCode ? mno.mobileCountryCode : @"000";
                NSString* mnc    = mno.mobileNetworkCode ? mno.mobileNetworkCode : @"000";
                NSString* mccMnc = [[NSString alloc] initWithFormat:@"%@-%@,%@-%@", mcc, mnc, mcc, mnc];

                [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC = true;

                [requestSerializer setValue:mccMnc forHTTPHeaderField:@"X-MCCMNC"];
            }
        }
    }
}

@end
