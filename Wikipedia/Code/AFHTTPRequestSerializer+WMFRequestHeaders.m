#import <WMF/AFHTTPRequestSerializer+WMFRequestHeaders.h>
#import <WMF/SessionSingleton.h>
#import <WMF/ReadingActionFunnel.h>
#import <WMF/WikipediaAppUtils.h>
#import <WMF/WMF-Swift.h>

@implementation AFHTTPRequestSerializer (WMFRequestHeaders)

- (void)wmf_applyAppRequestHeaders {
    [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // Add the app install ID to the header, but only if the user has not opted out of logging
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        ReadingActionFunnel *funnel = [[ReadingActionFunnel alloc] init];
        [self setValue:funnel.appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
    }

    [self setValue:[NSLocale wmf_acceptLanguageHeaderForPreferredLanguages] forHTTPHeaderField:@"Accept-Language"];
}

@end
