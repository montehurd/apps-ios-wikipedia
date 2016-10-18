#import "WMFAppViewController.h"
#import "Wikipedia-Swift.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <Tweaks/FBTweakInline.h>
#import <YapDatabase/YapDatabase.h>
#import "PiwikTracker+WMFExtensions.h"

// Utility
#import "NSDate+Utilities.h"
#import "NSUserActivity+WMFExtensions.h"

#import "YapDatabase+WMFExtensions.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKDataStore.h"
#import "WMFContentGroupDataStore.h"

// Networking
#import "SavedArticlesFetcher.h"
#import "SessionSingleton.h"
#import "AssetsFileFetcher.h"

// Model
#import "MWKSearchResult.h"
#import "MWKLanguageLinkController.h"
#import "WMFContentGroup.h"

//Content Sources
#import "WMFRelatedPagesContentSource.h"
#import "WMFMainPageContentSource.h"
#import "WMFNearbyContentSource.h"
#import "WMFContinueReadingContentSource.h"
#import "WMFFeedContentSource.h"
#import "WMFRandomContentSource.h"

// Views
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIViewController+WMFHideKeyboard.h"
#import "UIFont+WMFStyle.h"
#import "WMFStyleManager.h"
#import "UIApplicationShortcutItem+WMFShortcutItem.h"

// View Controllers
#import "WMFExploreViewController.h"
#import "WMFSearchViewController.h"
#import "WMFHistoryTableViewController.h"
#import "WMFSavedArticleTableViewController.h"
#import "WMFFirstRandomViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFMorePageListViewController.h"
#import "UIViewController+WMFSearch.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"

#import "AppDelegate.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFAuthenticationManager.h"

#import "WMFDailyStatsLoggingFunnel.h"

#import "WMFNotificationsController.h"
#import "UIViewController+WMFOpenExternalUrl.h"

#define TEST_SHARED_CONTAINER_MIGRATION DEBUG && 0

#if TEST_SHARED_CONTAINER_MIGRATION
#import "YapDatabase+WMFExtensions.h"
#import "SDImageCache+WMFPersistentCache.h"
#endif

/**
 *  Enums for each tab in the main tab bar.
 *
 *  @warning Be sure to update `WMFAppTabCount` when these enums change, and always initialize the first enum to 0.
 *
 *  @see WMFAppTabCount
 */
typedef NS_ENUM(NSUInteger, WMFAppTabType) {
    WMFAppTabTypeExplore = 0,
    WMFAppTabTypeSaved,
    WMFAppTabTypeRecent
};

/**
 *  Number of tabs in the main tab bar.
 *
 *  @warning Kept as a separate constant to prevent switch statements from being considered inexhaustive. This means we
 *           need to make sure it's manually kept in sync by ensuring:
 *              - The tab enum we increment is the last one
 *              - The first tab enum is initialized to 0
 *
 *  @see WMFAppTabType
 */
static NSUInteger const WMFAppTabCount = WMFAppTabTypeRecent + 1;

static NSTimeInterval const WMFTimeBeforeRefreshingExploreScreen = 24 * 60 * 60;

@interface WMFAppViewController () <UITabBarControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UIView *splashView;
@property (nonatomic, strong) UITabBarController *rootTabBarController;

@property (nonatomic, strong, readonly) WMFExploreViewController *exploreViewController;
@property (nonatomic, strong, readonly) WMFSavedArticleTableViewController *savedArticlesViewController;
@property (nonatomic, strong, readonly) WMFHistoryTableViewController *recentArticlesViewController;

@property (nonatomic, strong) SavedArticlesFetcher *savedArticlesFetcher;
@property (nonatomic, strong, readonly) SessionSingleton *session;

@property (nonatomic, strong, readonly) MWKDataStore *dataStore;
@property (nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong) WMFContentGroupDataStore *contentStore;

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity *unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem *unprocessedShortcutItem;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, strong) WMFDailyStatsLoggingFunnel *statsFunnel;

@property (nonatomic, strong) WMFNotificationsController *notificationsController;

/// Use @c rootTabBarController instead.
- (UITabBarController *)tabBarController NS_UNAVAILABLE;

@end

@implementation WMFAppViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(isZeroRatedChanged:)
                                                 name:WMFZeroRatingChanged
                                               object:nil];
}

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomePageViewController class]];
}

- (BOOL)uiIsLoaded {
    return _rootTabBarController != nil;
}

- (NSURL *)siteURL {
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

#pragma mark - Setup

- (void)loadMainUI {
    if ([self uiIsLoaded]) {
        return;
    }
    UITabBarController *tabBar = [[UIStoryboard storyboardWithName:@"WMFTabBarUI" bundle:nil] instantiateInitialViewController];
    [self addChildViewController:tabBar];
    [self.view addSubview:tabBar.view];
    [tabBar.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.bottom.and.leading.and.trailing.equalTo(self.view);
    }];
    [tabBar didMoveToParentViewController:self];
    self.rootTabBarController = tabBar;
    [self configureTabController];
    [self configureExploreViewController];
    [self configureArticleListController:self.savedArticlesViewController];
    [self configureArticleListController:self.recentArticlesViewController];
    [[self class] wmf_setSearchButtonDataStore:self.dataStore];
    [[self class] wmf_setSearchButtonPreviewStore:self.previewStore];
}

- (void)configureTabController {
    self.rootTabBarController.delegate = self;
    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController *navigationController = [self navigationControllerForTab:i];
        navigationController.delegate = self;
        navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)configureExploreViewController {
    [self.exploreViewController setUserStore:self.dataStore];
    [self.exploreViewController setPreviewStore:self.previewStore];
    [self.exploreViewController setContentStore:self.contentStore];
    [self.exploreViewController setContentSources:self.contentSources];
}

- (void)configureArticleListController:(WMFArticleListTableViewController *)controller {
    controller.userDataStore = self.dataStore;
    controller.previewStore = self.previewStore;
}

#pragma mark - Notifications

- (void)appWillEnterForegroundWithNotification:(NSNotification *)note {
    self.unprocessedUserActivity = nil;
    self.unprocessedShortcutItem = nil;
    [self resumeApp];
}

- (void)appDidEnterBackgroundWithNotification:(NSNotification *)note {
    [self startBackgroundTask];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self pauseApp];
    });
}

- (void)appLanguageDidChangeWithNotification:(NSNotification *)note {
    if ([_contentSources count] == 0) {
        return;
    }
    [self stopContentSources];
    self.contentSources = nil;
    [self startContentSources];
}

#pragma mark - Background Tasks

- (void)startBackgroundTask {
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }

    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.dataStore stopCacheRemoval];
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    if (self.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }

    UIBackgroundTaskIdentifier backgroundTaskToStop = self.backgroundTaskIdentifier;
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskToStop];
}

#pragma mark - Launch

+ (WMFAppViewController *)initialAppViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard storyboardWithName:NSStringFromClass([WMFAppViewController class]) bundle:nil] instantiateInitialViewController];
}

- (void)launchAppInWindow:(UIWindow *)window {
    WMFStyleManager *manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundWithNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLanguageDidChangeWithNotification:) name:WMFPreferredLanguagesDidChangeNotification object:nil];

    [self showSplashView];

#if TEST_SHARED_CONTAINER_MIGRATION
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:[YapDatabase wmf_databasePath] error:nil];
    [fm removeItemAtPath:[MWKDataStore mainDataStorePath] error:nil];
    [fm removeItemAtPath:[SDImageCache wmf_imageCacheDirectory] error:nil];
    [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToSharedContainer:NO];
#endif

    if (![[NSUserDefaults wmf_userDefaults] wmf_didMigrateToSharedContainer]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            NSError *error = nil;
            if (![MWKDataStore migrateToSharedContainer:&error]) {
                DDLogError(@"Error migrating data store: %@", error);
            }
            error = nil;
            if (![SDImageCache migrateToSharedContainer:&error]) {
                DDLogError(@"Error migrating image cache: %@", error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
                NSLog(@"%f", end - start);
                [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToSharedContainer:YES];
                [self finishLaunch];
            });
        });
    } else {
        [self finishLaunch];
    }
}

- (void)finishLaunch {
    @weakify(self)
        [self presentOnboardingIfNeededWithCompletion:^(BOOL didShowOnboarding) {
            @strongify(self)
                self.previewStore = [[WMFArticlePreviewDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
            self.contentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];

            [self preloadContentSourcesIfNeededWithCompletion:^{
                [self loadMainUI];
                [self hideSplashViewAnimated:!didShowOnboarding];
                [self resumeApp];
                [[PiwikTracker wmf_configuredInstance] wmf_logView:[self rootViewControllerForTab:WMFAppTabTypeExplore]];
            }];

        }];
}

#pragma mark - Start/Pause/Resume App

- (void)resumeApp {
    if (self.isPresentingOnboarding) {
        return;
    }

    if (![self uiIsLoaded]) {
        return;
    }

    [self.statsFunnel logAppNumberOfDaysSinceInstall];

    [self.dataStore syncDataStoreToDatabase];

    [[WMFAuthenticationManager sharedInstance] loginWithSavedCredentialsWithSuccess:NULL failure:NULL];
    [self startContentSources];
    [self.savedArticlesFetcher start];

    if (self.unprocessedUserActivity) {
        [self processUserActivity:self.unprocessedUserActivity];
    } else if (self.unprocessedShortcutItem) {
        [self processShortcutItem:self.unprocessedShortcutItem completion:NULL];
    } else if ([self shouldShowLastReadArticleOnLaunch]) {
        [self showLastReadArticleAnimated:NO];
    } else if ([self shouldShowExploreScreenOnLaunch]) {
        [self showExplore];
    }

    if (FBTweakValue(@"Alerts", @"General", @"Show error on launch", NO)) {
        [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"There was an error" }] sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show warning on launch", NO)) {
        [[WMFAlertManager sharedInstance] showWarningAlert:@"You have been warned" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show success on launch", NO)) {
        [[WMFAlertManager sharedInstance] showSuccessAlert:@"You are successful" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }
    if (FBTweakValue(@"Alerts", @"General", @"Show message on launch", NO)) {
        [[WMFAlertManager sharedInstance] showAlert:@"You have been notified" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    }

    DDLogWarn(@"Resuming… Logging Important Statistics");
    [self logImportantStatistics];
}

- (void)pauseApp {
    if (![self uiIsLoaded]) {
        return;
    }
    [[WMFImageController sharedInstance] clearMemoryCache];
    [self downloadAssetsFilesIfNecessary];
    [self.dataStore startCacheRemoval];
    [self.dataStore clearMemoryCache];
    [self.savedArticlesFetcher stop];
    [self stopContentSources];

    DDLogWarn(@"Backgrounding… Logging Important Statistics");
    [self logImportantStatistics];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    if (![self uiIsLoaded]) {
        return;
    }
    [super didReceiveMemoryWarning];
    [[WMFImageController sharedInstance] clearMemoryCache];
    [self.dataStore clearMemoryCache];
}

#pragma mark - Logging

- (void)logImportantStatistics {
    NSUInteger historyCount = [self.session.dataStore.historyList numberOfItems];
    NSUInteger saveCount = [self.session.dataStore.savedPageList numberOfItems];
    NSUInteger exploreCount = [self.exploreViewController numberOfSectionsInExploreFeed];
    UINavigationController *navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    NSUInteger stackCount = [[navVC viewControllers] count];

    DDLogWarn(@"History Count %lu", (unsigned long)historyCount);
    DDLogWarn(@"Saved Count %lu", (unsigned long)saveCount);
    DDLogWarn(@"Explore Count %lu", (unsigned long)exploreCount);
    DDLogWarn(@"Article Stack Count %lu", (unsigned long)stackCount);
}

- (WMFDailyStatsLoggingFunnel *)statsFunnel {
    if (!_statsFunnel) {
        _statsFunnel = [[WMFDailyStatsLoggingFunnel alloc] init];
    }
    return _statsFunnel;
}

#pragma mark - Content Sources

- (void)preloadContentSourcesIfNeededWithCompletion:(void (^)(void))completion {

    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateToNewFeed]) {
        if (completion) {
            completion();
        }
    } else {
        WMFTaskGroup *group = [WMFTaskGroup new];
        [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

            if ([obj respondsToSelector:@selector(preloadContentForNumberOfDays:completion:)]) {
                [group enter];
                [obj preloadContentForNumberOfDays:2
                                        completion:^{
                                            [group leave];
                                        }];
            }
        }];

        [group waitInBackgroundWithCompletion:^{
            [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToNewFeed:YES];
            if (completion) {
                completion();
            }
        }];
    }
}

- (void)updateFeedSourcesWithCompletion:(dispatch_block_t)completion {
    WMFTaskGroup *group = [WMFTaskGroup new];
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [group enter];
        [obj loadNewContentForce:NO
                      completion:^{
                          [group leave];
                      }];
    }];

    //TODO: nearby doesnt always fire.
    //May need to time it out or exclude
    [group waitInBackgroundWithCompletion:^{
        if (completion) {
            completion();
        }
    }];
}

- (void)startContentSources {
    [self.contentSources makeObjectsPerformSelector:@selector(startUpdating)];
}

- (void)stopContentSources {
    [self.contentSources makeObjectsPerformSelector:@selector(stopUpdating)];
}

- (WMFNearbyContentSource *)nearbyContentSource {
    return [self.contentSources bk_match:^BOOL(id<WMFContentSource> obj) {
        return [obj isKindOfClass:[WMFNearbyContentSource class]];
    }];
}

- (NSArray<id<WMFContentSource>> *)contentSources {
    NSParameterAssert(self.contentStore);
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.previewStore);
    NSParameterAssert([self siteURL]);
    if (!_contentSources) {
        _contentSources = @[
            [[WMFRelatedPagesContentSource alloc] initWithContentGroupDataStore:self.contentStore
                                                                  userDataStore:self.dataStore
                                                        articlePreviewDataStore:self.previewStore],
            [[WMFMainPageContentSource alloc] initWithSiteURL:[self siteURL]
                                        contentGroupDataStore:self.contentStore
                                      articlePreviewDataStore:self.previewStore],
            [[WMFContinueReadingContentSource alloc] initWithContentGroupDataStore:self.contentStore
                                                                     userDataStore:self.dataStore
                                                           articlePreviewDataStore:self.previewStore],
            [[WMFNearbyContentSource alloc] initWithSiteURL:[self siteURL]
                                      contentGroupDataStore:self.contentStore
                                    articlePreviewDataStore:self.previewStore],
            [[WMFFeedContentSource alloc] initWithSiteURL:[self siteURL]
                                    contentGroupDataStore:self.contentStore
                                  articlePreviewDataStore:self.previewStore
                                            userDataStore:self.dataStore
                                  notificationsController:self.notificationsController],
            [[WMFRandomContentSource alloc] initWithSiteURL:[self siteURL]
                                      contentGroupDataStore:self.contentStore
                                    articlePreviewDataStore:self.previewStore]
        ];
    }
    return _contentSources;
}

#pragma mark - Shortcut

- (BOOL)canProcessShortcutItem:(UIApplicationShortcutItem *)item {
    if (!item) {
        return NO;
    }
    if ([item.type isEqualToString:WMFIconShortcutTypeSearch]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        return YES;
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)processShortcutItem:(UIApplicationShortcutItem *)item completion:(void (^)(BOOL))completion {
    if (![self canProcessShortcutItem:item]) {
        if (completion) {
            completion(NO);
        }
        return;
    }

    if (![self uiIsLoaded]) {
        self.unprocessedShortcutItem = item;
        if (completion) {
            completion(YES);
        }
        return;
    }
    self.unprocessedShortcutItem = nil;

    if ([item.type isEqualToString:WMFIconShortcutTypeSearch]) {
        [self showSearchAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        [self showRandomArticleAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        [self showNearbyListAnimated:NO];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        [self showLastReadArticleAnimated:NO];
    }
    if (completion) {
        completion(YES);
    }
}

#pragma mark - NSUserActivity

- (BOOL)canProcessUserActivity:(NSUserActivity *)activity {
    if (!activity) {
        return NO;
    }
    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
        case WMFUserActivityTypeSavedPages:
        case WMFUserActivityTypeHistory:
        case WMFUserActivityTypeSearch:
        case WMFUserActivityTypeSettings:
        case WMFUserActivityTypeContent:
            return YES;
        case WMFUserActivityTypeSearchResults:
            if ([activity wmf_searchTerm] != nil) {
                return YES;
            } else {
                return NO;
            }
            break;
        case WMFUserActivityTypeArticle: {
            if (![activity wmf_articleURL]) {
                return NO;
            } else {
                return YES;
            }
        } break;
        case WMFUserActivityTypeGenericLink: {
            return YES;
        }
        default:
            return NO;
            break;
    }
}

- (BOOL)processUserActivity:(NSUserActivity *)activity {
    if (![self canProcessUserActivity:activity]) {
        return NO;
    }
    if (![self uiIsLoaded]) {
        self.unprocessedUserActivity = activity;
        return YES;
    }
    self.unprocessedUserActivity = nil;
    [self dismissViewControllerAnimated:NO completion:NULL];
    switch ([activity wmf_type]) {
        case WMFUserActivityTypeExplore:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeContent: {
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];

            UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeExplore];
            [navController popToRootViewControllerAnimated:NO];
            NSURL *url = [activity wmf_contentURL];
            WMFContentGroup *group = [self.contentStore contentGroupForURL:url];
            [self.exploreViewController presentMoreViewControllerForGroup:group animated:NO];

        } break;
        case WMFUserActivityTypeSavedPages:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeSaved];
            [[self navigationControllerForTab:WMFAppTabTypeSaved] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeHistory:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeRecent];
            [[self navigationControllerForTab:WMFAppTabTypeRecent] popToRootViewControllerAnimated:NO];
            break;
        case WMFUserActivityTypeSearch:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [[self rootViewControllerForTab:WMFAppTabTypeExplore] wmf_showSearchAnimated:NO];
            break;
        case WMFUserActivityTypeSearchResults:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [[self rootViewControllerForTab:WMFAppTabTypeExplore] wmf_showSearchAnimated:NO];
            [[UIViewController wmf_sharedSearchViewController] setSearchTerm:[activity wmf_searchTerm]];
            break;
        case WMFUserActivityTypeArticle: {
            NSURL *URL = [activity wmf_articleURL];
            if (!URL) {
                return NO;
            }
            [self showArticleForURL:URL animated:NO];
        } break;
        case WMFUserActivityTypeSettings:
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
            [self.exploreViewController showSettings];
            break;
        case WMFUserActivityTypeGenericLink:
            [self wmf_openExternalUrl:activity.webpageURL];
            break;
        default:
            return NO;
            break;
    }

    return YES;
}

#pragma mark - Utilities

- (WMFArticleViewController *)showArticleForURL:(NSURL *)articleURL animated:(BOOL)animated {
    if (!articleURL.wmf_title) {
        return nil;
    }
    WMFArticleViewController *visibleArticleViewController = self.visibleArticleViewController;
    if ([visibleArticleViewController.articleURL isEqual:articleURL]) {
        return visibleArticleViewController;
    }
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    return [[self exploreViewController] wmf_pushArticleWithURL:articleURL dataStore:self.session.dataStore previewStore:self.previewStore restoreScrollPosition:YES animated:animated];
}

- (BOOL)shouldShowExploreScreenOnLaunch {
    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeRefreshingExploreScreen) {
        return YES;
    }
    return NO;
}

- (BOOL)exploreViewControllerIsDisplayingContent {
    return [self navigationControllerForTab:WMFAppTabTypeExplore].viewControllers.count > 1;
}

- (WMFArticleViewController *)visibleArticleViewController {
    UINavigationController *navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    UIViewController *topVC = navVC.topViewController;
    if ([topVC isKindOfClass:[WMFArticleViewController class]]) {
        return (WMFArticleViewController *)topVC;
    }
    return nil;
}

- (UINavigationController *)navigationControllerForTab:(WMFAppTabType)tab {
    return (UINavigationController *)[self.rootTabBarController viewControllers][tab];
}

- (UIViewController<WMFAnalyticsViewNameProviding> *)rootViewControllerForTab:(WMFAppTabType)tab {
    return [[[self navigationControllerForTab:tab] viewControllers] firstObject];
}

#pragma mark - Accessors

- (SavedArticlesFetcher *)savedArticlesFetcher {
    if (![self uiIsLoaded]) {
        return nil;
    }
    if (!_savedArticlesFetcher) {
        _savedArticlesFetcher =
            [[SavedArticlesFetcher alloc] initWithDataStore:[[SessionSingleton sharedInstance] dataStore]
                                               previewStore:self.previewStore
                                              savedPageList:[self.dataStore savedPageList]];
    }
    return _savedArticlesFetcher;
}

- (WMFNotificationsController *)notificationsController {
    if (![self uiIsLoaded]) {
        return nil;
    }

    if (!_notificationsController) {
        _notificationsController = [[WMFNotificationsController alloc] init];
    }

    return _notificationsController;
}

- (SessionSingleton *)session {
    return [SessionSingleton sharedInstance];
}

- (MWKDataStore *)dataStore {
    return self.session.dataStore;
}

- (WMFExploreViewController *)exploreViewController {
    return (WMFExploreViewController *)[self rootViewControllerForTab:WMFAppTabTypeExplore];
}

- (WMFArticleListTableViewController *)savedArticlesViewController {
    return (WMFArticleListTableViewController *)[self rootViewControllerForTab:WMFAppTabTypeSaved];
}

- (WMFArticleListTableViewController *)recentArticlesViewController {
    return (WMFArticleListTableViewController *)[self rootViewControllerForTab:WMFAppTabTypeRecent];
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotate {
    if (self.rootTabBarController) {
        return [self.rootTabBarController shouldAutorotate];
    } else {
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.rootTabBarController) {
        return [self.rootTabBarController supportedInterfaceOrientations];
    } else {
        return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.rootTabBarController) {
        return [self.rootTabBarController preferredInterfaceOrientationForPresentation];
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

#pragma mark - Onboarding

static NSString *const WMFDidShowOnboarding = @"DidShowOnboarding5.0";

- (BOOL)shouldShowOnboarding {
    if (FBTweakValue(@"Welcome", @"General", @"Show on launch (requires force quit)", NO) || [[NSProcessInfo processInfo] environment][@"WMFShowWelcomeView"].boolValue) {
        return YES;
    }
    NSNumber *didShow = [[NSUserDefaults wmf_userDefaults] objectForKey:WMFDidShowOnboarding];
    return !didShow.boolValue;
}

- (void)setDidShowOnboarding {
    [[NSUserDefaults wmf_userDefaults] setObject:@YES forKey:WMFDidShowOnboarding];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (void)presentOnboardingIfNeededWithCompletion:(void (^)(BOOL didShowOnboarding))completion {
    if ([self shouldShowOnboarding]) {
        WMFWelcomePageViewController *vc = [WMFWelcomePageViewController wmf_viewControllerWithIdentifier:@"WMFWelcomePageViewController" fromStoryboardNamed:@"WMFWelcome"];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        vc.completionBlock = ^{
            [self setDidShowOnboarding];
            if (completion) {
                completion(YES);
            }
        };
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        if (completion) {
            completion(NO);
        }
    }
}

#pragma mark - Splash

- (void)showSplashView {
    self.splashView.hidden = NO;
    self.splashView.layer.transform = CATransform3DIdentity;
    self.splashView.alpha = 1.0;
}

- (void)hideSplashViewAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.3 : 0.0;

    [UIView animateWithDuration:duration
        animations:^{
            self.splashView.layer.transform = CATransform3DMakeScale(10.0f, 10.0f, 1.0f);
            self.splashView.alpha = 0.0;
        }
        completion:^(BOOL finished) {
            self.splashView.hidden = YES;
            self.splashView.layer.transform = CATransform3DIdentity;
        }];
}

- (BOOL)isShowingSplashView {
    return self.splashView.hidden == NO;
}

#pragma mark - Explore VC

- (void)showExplore {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
}

#pragma mark - Last Read Article

- (BOOL)shouldShowLastReadArticleOnLaunch {
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    if (!lastRead) {
        return NO;
    }

    if (FBTweakValue(@"Last Open Article", @"General", @"Restore on Launch", YES)) {
        return YES;
    }

    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];
    if (!resignActiveDate) {
        return NO;
    }

    if (fabs([resignActiveDate timeIntervalSinceNow]) < WMFTimeBeforeRefreshingExploreScreen) {
        if (![self exploreViewControllerIsDisplayingContent] && [self.rootTabBarController selectedIndex] == WMFAppTabTypeExplore) {
            return YES;
        }
    }

    return NO;
}

- (void)showLastReadArticleAnimated:(BOOL)animated {
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    [self showArticleForURL:lastRead animated:animated];
}

#pragma mark - Show Search

- (void)showSearchAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [self.exploreViewController wmf_showSearchAnimated:animated];
}

#pragma mark - App Shortcuts

- (void)showRandomArticleAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }

    WMFFirstRandomViewController *vc = [[WMFFirstRandomViewController alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore previewStore:self.previewStore];
    [exploreNavController pushViewController:vc animated:animated];
}

- (void)showNearbyListAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
    [[self nearbyContentSource] loadNewContentForce:NO
                                         completion:^{
                                             WMFContentGroup *nearby = [self.contentStore firstGroupOfKind:[WMFLocationContentGroup kind] forDate:[NSDate date]];
                                             if (!nearby) {
                                                 //TODO: show an error?
                                                 return;
                                             }

                                             NSArray *urls = [self.contentStore contentForContentGroup:nearby];

                                             WMFMorePageListViewController *vc = [[WMFMorePageListViewController alloc] initWithGroup:nearby articleURLs:urls userDataStore:self.dataStore previewStore:self.previewStore];
                                             vc.cellType = WMFMorePageListCellTypeLocation;
                                             [[self navigationControllerForTab:WMFAppTabTypeExplore] pushViewController:vc animated:animated];
                                         }];
}

#pragma mark - Download Assets

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                          withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                               maxAge:kWMFMaxAgeDefault];
    }];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self wmf_hideKeyboard];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (viewController == tabBarController.selectedViewController) {
        switch (tabBarController.selectedIndex) {
            case WMFAppTabTypeExplore: {
                WMFExploreViewController *exploreViewController = (WMFExploreViewController *)[self exploreViewController];
                [exploreViewController scrollToTop];
            } break;
            case WMFAppTabTypeSaved: {
                WMFArticleListTableViewController *savedArticlesViewController = (WMFArticleListTableViewController *)[self savedArticlesViewController];
                [savedArticlesViewController scrollToTop:savedArticlesViewController.userDataStore.savedPageList.numberOfItems > 0];
            } break;
            case WMFAppTabTypeRecent: {
                WMFArticleListTableViewController *historyArticlesViewController = (WMFArticleListTableViewController *)[self recentArticlesViewController];
                [historyArticlesViewController scrollToTop:[historyArticlesViewController.userDataStore.historyList numberOfItems] > 0];
            } break;
        }
    }

    return YES;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    navigationController.interactivePopGestureRecognizer.delegate = self;
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    DDLogWarn(@"Pushing/Popping article… Logging Important Statistics");
    [self logImportantStatistics];
    if ([[navigationController viewControllers] count] == 1) {
        [[NSUserDefaults wmf_userDefaults] wmf_setOpenArticleURL:nil];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    for (WMFAppTabType i = 0; i < WMFAppTabCount; i++) {
        UINavigationController *navigationController = [self navigationControllerForTab:i];
        if (navigationController.interactivePopGestureRecognizer == gestureRecognizer) {
            return navigationController.viewControllers.count > 1;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![gestureRecognizer isMemberOfClass:[UIScreenEdgePanGestureRecognizer class]];
}

#pragma mark - Wikipedia Zero

- (void)isZeroRatedChanged:(NSNotification *)note {
    WMFZeroConfigurationManager *zeroConfigurationManager = [note object];
    if (zeroConfigurationManager.isZeroRated) {
        [self showFirstTimeZeroOnAlertIfNeeded:zeroConfigurationManager.zeroConfiguration];
    } else {
        [self showZeroOffAlert];
    }
}

- (void)setZeroOnDialogShownOnce {
    [[NSUserDefaults wmf_userDefaults] setBool:YES forKey:WMFZeroOnDialogShownOnce];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults wmf_userDefaults] boolForKey:WMFZeroOnDialogShownOnce];
}

- (void)showFirstTimeZeroOnAlertIfNeeded:(WMFZeroConfiguration *)zeroConfiguration {
    if ([self zeroOnDialogShownOnce]) {
        return;
    }

    [self setZeroOnDialogShownOnce];

    NSString *title = zeroConfiguration.message ? zeroConfiguration.message : MWLocalizedString(@"zero-free-verbiage", nil);

    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:title message:MWLocalizedString(@"zero-learn-more", nil) preferredStyle:UIAlertControllerStyleAlert];

    [dialog addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil) style:UIAlertActionStyleCancel handler:NULL]];

    [dialog addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"zero-learn-more-learn-more", nil)
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *_Nonnull action) {
                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:MWLocalizedString(@"zero-webpage-url", nil)]];
                                             }]];

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:dialog animated:YES completion:NULL];
}

- (void)showZeroOffAlert {

    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:MWLocalizedString(@"zero-charged-verbiage", nil) message:MWLocalizedString(@"zero-charged-verbiage-extended", nil) preferredStyle:UIAlertControllerStyleAlert];

    [dialog addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"zero-learn-more-no-thanks", nil) style:UIAlertActionStyleCancel handler:NULL]];

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:dialog animated:YES completion:NULL];
}

#pragma mark - UNUserNotificationCenterDelegate

// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    if ([response.actionIdentifier isEqualToString:WMFInTheNewsNotificationShareActionIdentifier]) {
        NSDictionary *info = response.notification.request.content.userInfo;
        NSString *articleURLString = info[WMFNotificationInfoArticleURLStringKey];
        NSURL *articleURL = [NSURL URLWithString:articleURLString];
        WMFArticleViewController *articleVC = [self showArticleForURL:articleURL animated:NO];
        [articleVC shareArticleWhenReady];
    }
    completionHandler();
}

@end
