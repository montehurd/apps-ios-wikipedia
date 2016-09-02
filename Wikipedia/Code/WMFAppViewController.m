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
// Networking
#import "SavedArticlesFetcher.h"
#import "SessionSingleton.h"
#import "AssetsFileFetcher.h"

// Model
#import "MWKSearchResult.h"
#import "MWKLanguageLinkController.h"

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
#import "WMFWelcomeViewController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFNearbyListViewController.h"
#import "UIViewController+WMFSearch.h"
#import "UINavigationController+WMFHideEmptyToolbar.h"

#import "AppDelegate.h"
#import "WMFRandomSectionController.h"
#import "WMFNearbySectionController.h"
#import "WMFRandomArticleFetcher.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "WMFAuthenticationManager.h"

#import "WMFDailyStatsLoggingFunnel.h"

#import "WMFMostReadListTableViewController.h"

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
@property (nonatomic, strong) WMFRandomArticleFetcher *randomFetcher;
@property (nonatomic, strong) SessionSingleton *session;
@property (nonatomic, strong) WMFSavedPageSpotlightManager *spotlightManager;

@property (nonatomic) BOOL isPresentingOnboarding;

@property (nonatomic, strong) NSUserActivity *unprocessedUserActivity;
@property (nonatomic, strong) UIApplicationShortcutItem *unprocessedShortcutItem;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, strong) WMFDailyStatsLoggingFunnel *statsFunnel;

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
                                             selector:@selector(zeroDispositionDidChange:)
                                                 name:WMFZeroDispositionDidChange
                                               object:nil];
}

- (BOOL)isPresentingOnboarding {
    return [self.presentedViewController isKindOfClass:[WMFWelcomeViewController class]];
}

- (BOOL)uiIsLoaded {
    return _rootTabBarController != nil;
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
    [self.exploreViewController setDataStore:[self dataStore]];
}

- (void)configureArticleListController:(WMFArticleListTableViewController *)controller {
    controller.dataStore = self.session.dataStore;
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
    [WikipediaAppUtils copyAssetsFolderToAppDataDocuments];

    WMFStyleManager *manager = [WMFStyleManager new];
    [manager applyStyleToWindow:window];
    [WMFStyleManager setSharedStyleManager:manager];

    [window setRootViewController:self];
    [window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundWithNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundWithNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];

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
                [self loadMainUI];
            self.spotlightManager = [[WMFSavedPageSpotlightManager alloc] initWithDataStore:self.session.dataStore];
            [self hideSplashViewAnimated:!didShowOnboarding];
            [self resumeApp];
            [[PiwikTracker wmf_configuredInstance] wmf_logView:[self rootViewControllerForTab:WMFAppTabTypeExplore]];
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

    [[WMFAuthenticationManager sharedInstance] loginWithSavedCredentialsWithSuccess:NULL failure:NULL];
    [self.savedArticlesFetcher start];

    if (self.unprocessedUserActivity) {
        [self processUserActivity:self.unprocessedUserActivity];
    } else if (self.unprocessedShortcutItem) {
        [self processShortcutItem:self.unprocessedShortcutItem completion:NULL];
    } else if ([self shouldShowLastReadArticleOnLaunch]) {
        [self showLastReadArticleAnimated:YES];
    } else if ([self shouldShowExploreScreenOnLaunch]) {
        [self showExplore];
    }

    //    if (FBTweakValue(@"Alerts", @"General", @"Show error on launch", NO)) {
    //        [[WMFAlertManager sharedInstance] showErrorAlert:[NSError errorWithDomain:@"WMFTestDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"There was an error"}] sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //    }
    //    if (FBTweakValue(@"Alerts", @"General", @"Show warning on launch", NO)) {
    //        [[WMFAlertManager sharedInstance] showWarningAlert:@"You have been warned" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //    }
    //    if (FBTweakValue(@"Alerts", @"General", @"Show success on launch", NO)) {
    //        [[WMFAlertManager sharedInstance] showSuccessAlert:@"You are successful" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //    }
    //    if (FBTweakValue(@"Alerts", @"General", @"Show message on launch", NO)) {
    //        [[WMFAlertManager sharedInstance] showAlert:@"You have been notified" sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //    }
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
    [[[SessionSingleton sharedInstance] dataStore] clearMemoryCache];
    [self.savedArticlesFetcher stop];

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
    [[[SessionSingleton sharedInstance] dataStore] clearMemoryCache];
}

#pragma mark - Logging

- (void)logImportantStatistics {
    NSUInteger historyCount = [self.session.dataStore.userDataStore.historyList numberOfItems];
    NSUInteger saveCount = [self.session.dataStore.userDataStore.savedPageList numberOfItems];
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
        [self showSearchAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeRandom]) {
        [self showRandomArticleAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeNearby]) {
        [self showNearbyListAnimated:YES];
    } else if ([item.type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        [self showLastReadArticleAnimated:YES];
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
        case WMFUserActivityTypeTopRead:
            return YES;
        case WMFUserActivityTypeSearchResults:
            if ([activity wmf_searchTerm]) {
                return YES;
            } else {
                return NO;
            }
            break;
        case WMFUserActivityTypeArticle: {
            if (!activity.webpageURL) {
                return NO;
            } else {
                return YES;
            }
        } break;
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
        case WMFUserActivityTypeTopRead:
        {
            [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
            
            UINavigationController *navController = [self navigationControllerForTab:WMFAppTabTypeExplore];
            [navController popToRootViewControllerAnimated:NO];
            NSDictionary *userInfo = activity.userInfo;
            NSDate *date = userInfo[@"date"];
            NSURL *siteURL = userInfo[@"siteURL"];
            NSString *host = siteURL.host;
            if (date == nil || host == nil) {
                break;
            }
            MWKDataStore *dataStore = [[SessionSingleton sharedInstance] dataStore];
            [dataStore readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                NSString *collection = [@[@"wmftopread", host] componentsJoinedByString:@":"];
                NSString *key = [[NSDateFormatter wmf_englishHyphenatedYearMonthDayFormatter] stringFromDate:date];
                NSArray* previews = [transaction objectForKey:key inCollection:collection];
                if ([previews count] > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        WMFMostReadListTableViewController *mostReadListVC = [[WMFMostReadListTableViewController alloc] initWithPreviews:previews fromSiteURL:siteURL forDate:date dataStore:dataStore];
                        [navController pushViewController:mostReadListVC animated:NO];
                    });
                }
            }];
        }
            break;
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
            NSURL *URL = activity.webpageURL;
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
        default:
            return NO;
            break;
    }

    return YES;
}

#pragma mark - Utilities

- (void)showArticleForURL:(NSURL *)articleURL animated:(BOOL)animated {
    if (!articleURL.wmf_title) {
        return;
    }
    if ([[self onscreenURL] isEqual:articleURL]) {
        return;
    }
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    [[self exploreViewController] wmf_pushArticleWithURL:articleURL dataStore:self.session.dataStore restoreScrollPosition:YES animated:animated];
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

- (NSURL *)onscreenURL {
    UINavigationController *navVC = [self navigationControllerForTab:self.rootTabBarController.selectedIndex];
    if ([navVC.topViewController isKindOfClass:[WMFArticleViewController class]]) {
        return ((WMFArticleViewController *)navVC.topViewController).articleURL;
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
                                              savedPageList:[[[SessionSingleton sharedInstance] userDataStore] savedPageList]];
    }
    return _savedArticlesFetcher;
}

- (WMFRandomArticleFetcher *)randomFetcher {
    if (![self uiIsLoaded]) {
        return nil;
    }

    if (_randomFetcher == nil) {
        _randomFetcher = [[WMFRandomArticleFetcher alloc] init];
    }
    return _randomFetcher;
}

- (SessionSingleton *)session {
    if (![self uiIsLoaded]) {
        return nil;
    }

    if (!_session) {
        _session = [SessionSingleton sharedInstance];
    }

    return _session;
}

- (MWKDataStore *)dataStore {
    return self.session.dataStore;
}

- (MWKUserDataStore *)userDataStore {
    return self.session.userDataStore;
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
        WMFWelcomeViewController *vc = [WMFWelcomeViewController welcomeViewControllerFromDefaultStoryBoard];
        vc.completionBlock = ^{
            [self setDidShowOnboarding];
            if (completion) {
                completion(YES);
            }
        };
        [self presentViewController:vc animated:NO completion:NULL];
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
    NSURL *siteURL = [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
    [self.randomFetcher fetchRandomArticleWithSiteURL:siteURL
        failure:^(NSError *error) {
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
        }
        success:^(MWKSearchResult *result) {
            NSURL *articleURL = [siteURL wmf_URLWithTitle:result.displayTitle];
            [[self exploreViewController] wmf_pushArticleWithURL:articleURL dataStore:self.session.dataStore animated:YES];
        }];
}

- (void)showNearbyListAnimated:(BOOL)animated {
    [self.rootTabBarController setSelectedIndex:WMFAppTabTypeExplore];
    UINavigationController *exploreNavController = [self navigationControllerForTab:WMFAppTabTypeExplore];
    if (exploreNavController.presentedViewController) {
        [exploreNavController dismissViewControllerAnimated:NO completion:NULL];
    }
    [[self navigationControllerForTab:WMFAppTabTypeExplore] popToRootViewControllerAnimated:NO];
    NSURL *siteURL = [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
    WMFNearbyListViewController *vc = [[WMFNearbyListViewController alloc] initWithSearchSiteURL:siteURL dataStore:self.dataStore];
    [[self navigationControllerForTab:WMFAppTabTypeExplore] pushViewController:vc animated:animated];
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
                [savedArticlesViewController scrollToTop:savedArticlesViewController.dataStore.userDataStore.savedPageList.numberOfItems > 0];
            } break;
            case WMFAppTabTypeRecent: {
                WMFArticleListDataSourceTableViewController *historyArticlesViewController = (WMFArticleListDataSourceTableViewController *)[self recentArticlesViewController];
                [historyArticlesViewController scrollToTop:[historyArticlesViewController.dataStore.userDataStore.historyList numberOfItems] > 0];
            } break;
        }
    }

    return YES;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [navigationController wmf_hideToolbarIfViewControllerHasNoToolbarItems:viewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    DDLogWarn(@"Pushing/Popping article… Logging Important Statistics");
    [self logImportantStatistics];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![otherGestureRecognizer.view isKindOfClass:[UIScrollView class]];
}

#pragma mark - WMFZeroDisposition

- (void)zeroDispositionDidChange:(NSNotification *)note {
    ZeroConfigState *state = [note object];
    if ([SessionSingleton sharedInstance].zeroConfigState.disposition) {
        [self showFirstTimeZeroOnAlertIfNeeded:state.zeroConfiguration];
    } else {
        [self showZeroOffAlert];
    }
}

- (void)setZeroOnDialogShownOnce {
    [[NSUserDefaults wmf_userDefaults] setBool:YES forKey:ZeroOnDialogShownOnce];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (BOOL)zeroOnDialogShownOnce {
    return [[NSUserDefaults wmf_userDefaults] boolForKey:ZeroOnDialogShownOnce];
}

- (void)showFirstTimeZeroOnAlertIfNeeded:(WMFZeroConfiguration *)zeroConfiguration {
    if ([self zeroOnDialogShownOnce]) {
        return;
    }

    [self setZeroOnDialogShownOnce];

    NSString* title = zeroConfiguration.message ? zeroConfiguration.message : MWLocalizedString(@"zero-free-verbiage", nil);
    
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

@end
