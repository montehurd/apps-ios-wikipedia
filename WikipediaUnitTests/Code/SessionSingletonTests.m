@import Quick;
@import Nimble;

#import "MWKDataStore+TempDataStoreForEach.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "PostNotificationMatcherShorthand.h"

#import "SessionSingleton.h"
#import "QueuesSingleton+AllManagers.h"
#import "NSUserDefaults+WMFReset.h"
#import "ReadingActionFunnel.h"

QuickSpecBegin(SessionSingletonTests)

    __block SessionSingleton *testSession;

configureTempDataStoreForEach(tempDataStore, ^{
    [[NSUserDefaults wmf_userDefaults] wmf_resetToDefaultValues];

    testSession = [[SessionSingleton alloc] initWithDataStore:tempDataStore];
    WMF_TECH_DEBT_TODO(refactor sendUsageReports to use a notification to make it easier to test)
    /*
       ^ this only works now because the queues singleton grabs its values directly from the shared instance
       AND the shared instance doesn't "cache" the sendUsageReports value in memory, so setting it from a different
       "SessionSingleton" is fine
     */

    [[QueuesSingleton sharedInstance] reset];
});

afterSuite(^{
    [[NSUserDefaults wmf_userDefaults] wmf_resetToDefaultValues];
    [[QueuesSingleton sharedInstance] reset];
});

describe(@"send usage reports", ^{
    itBehavesLike(@"a persistent property", ^{
        return @{ @"session": testSession,
                  @"key": WMF_SAFE_KEYPATH(testSession, shouldSendUsageReports),
                  // set to different value by
                  @"value": @(!testSession.shouldSendUsageReports) };
    });

    void (^expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue)(NSArray *managers) =
        ^(NSArray *managers) {
            NSString *expectedHeaderValue = [[ReadingActionFunnel new] appInstallID];
            NSArray *headerValues =
                [managers valueForKeyPath:@"requestSerializer.HTTPRequestHeaders.X-WMF-UUID"];
            id<NMBMatcher> allEqualExpectedValueOrNull =
                allPass(equal(testSession.shouldSendUsageReports ? expectedHeaderValue : [NSNull null]));

            expect(headerValues).to(allEqualExpectedValueOrNull);
        };

    WMF_TECH_DEBT_TODO(shared example for all non - global fetchers to ensure they honor current & future values of this prop)
    it(@"should reset the global request managers", ^{
        NSArray *oldManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(oldManagers).toNot(beEmpty());
        expect(oldManagers).to(allPass(beAKindOf([AFHTTPSessionManager class])));

        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(oldManagers);

        // change send usage reports
        [testSession setShouldSendUsageReports:!testSession.shouldSendUsageReports];

        NSArray *newManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(newManagers).to(haveCount(@(oldManagers.count)));
        expect(newManagers).toNot(equal(oldManagers));
        expect(newManagers).to(allPass(beAKindOf([AFHTTPSessionManager class])));

        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(newManagers);
    });

    it(@"should be idempotent", ^{
        NSArray *oldManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(oldManagers).toNot(beEmpty());
        expect(oldManagers).to(allPass(beAKindOf([AFHTTPSessionManager class])));
        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(oldManagers);

        [testSession setShouldSendUsageReports:testSession.shouldSendUsageReports];

        NSArray *managersAfterRedundantSet = [[QueuesSingleton sharedInstance] allManagers];
        expect(managersAfterRedundantSet).to(equal(oldManagers));
        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(managersAfterRedundantSet);
    });
});

QuickSpecEnd

    QuickConfigurationBegin(SessionSingletonSharedExamples)

    + (void)configure : (Configuration *)configuration {
    sharedExamples(@"a persistent property", ^(QCKDSLSharedExampleContext getContext) {
        __block SessionSingleton *session;
        __block id value;
        __block NSString *key;

        beforeEach(^{
            [[NSUserDefaults wmf_userDefaults] wmf_resetToDefaultValues];
            NSDictionary *context = getContext();
            session = context[@"session"];
            value = context[@"value"];
            key = context[@"key"];
        });

        it(@"a persistent property", ^{
            [session setValue:value forKey:key];
            SessionSingleton *newSession = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
            expect([newSession valueForKey:key]).to(equal(value));
            [newSession.dataStore removeFolderAtBasePath];
        });
    });
}

QuickConfigurationEnd
