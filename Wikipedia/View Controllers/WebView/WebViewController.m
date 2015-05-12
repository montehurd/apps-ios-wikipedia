//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WebViewController_Private.h"
#import <Masonry/Masonry.h>
#import "NSString+WMFHTMLParsing.h"

NSString* const WebViewControllerTextWasHighlighted    = @"textWasSelected";
NSString* const WebViewControllerWillShareNotification = @"SelectionShare";
NSString* const WebViewControllerShareBegin            = @"beginShare";
NSString* const WebViewControllerShareSelectedText     = @"selectedText";
NSString* const kSelectedStringJS                      = @"window.getSelection().toString()";

@implementation WebViewController

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self->session = [SessionSingleton sharedInstance];
    }
    return self;
}

- (instancetype)init {
    return [self initWithSession:[SessionSingleton sharedInstance]];
}

- (instancetype)initWithSession:(SessionSingleton*)aSession {
    NSParameterAssert(aSession);
    self = [super init];
    if (self) {
        self->session = aSession;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)prefersTopNavigationHidden {
    return [self shouldShowOnboarding];
}

- (NavBarMode)navBarMode {
    return NAVBAR_MODE_DEFAULT;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark View lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTrackingFooter];

    self.bottomNavHeightConstraint.constant = CHROME_MENUS_HEIGHT;

    self.scrollingToTop = NO;

    [self scrollIndicatorSetup];

    self.panSwipeRecognizer = nil;

    self.zeroStatusLabel.font = [UIFont systemFontOfSize:ALERT_FONT_SIZE];
    self.zeroStatusLabel.text = @"";

    self.referencesVC = nil;

    self.sectionToEditId = 0;

    __weak WebViewController* weakSelf = self;
    [self.bridge addListener:@"DOMContentLoaded" withBlock:^(NSString* type, NSDictionary* payload) {
        [weakSelf jumpToFragmentIfNecessary];
        [weakSelf autoScrollToLastScrollOffsetIfNecessary];

        [weakSelf updateProgress:1.0 animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf hideProgressViewAnimated:YES];
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tocVC updateTocForArticle:[SessionSingleton sharedInstance].currentArticle];
            [weakSelf updateTOCScrollPositionWithoutAnimationIfHidden];
        });
    }];

    self.unsafeToScroll    = NO;
    self.unsafeToToggleTOC = NO;
    self.lastScrollOffset  = CGPointZero;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveCurrentPage)
                                                 name:@"SavePage"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchFieldBecameFirstResponder)
                                                 name:@"SearchFieldBecameFirstResponder"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zeroStateChanged:)
                                                 name:@"ZeroStateChanged"
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sectionImageRetrieved:)
                                                 name:WMFURLCacheSectionImageRetrievedNotification
                                               object:nil];

    [self fadeAlert];

    scrollViewDragBeganVerticalOffset_ = 0.0f;

    // Ensure web view can appear beneath translucent nav bar when scrolled up
    for (UIView* subview in self.webView.subviews) {
        subview.clipsToBounds = NO;
    }

    // Ensure the keyboard hides if the web view is scrolled
    // We already are delegate from PullToRefreshViewController
    //self.webView.scrollView.delegate = self;

    self.webView.backgroundColor = [UIColor whiteColor];

    [self.webView hideScrollGradient];

    [self tocSetupSwipeGestureRecognizers];

    [self reloadCurrentArticle];

    // Restrict the web view from scrolling horizonally.
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];

    // UIWebView has a bug which causes a black bar to appear at
    // bottom of the web view if toc quickly dragged on and offscreen.
    self.webView.opaque = NO;

    self.bottomBarViewBottomConstraint = nil;

    self.view.backgroundColor = CHROME_COLOR;

    // Uncomment these lines only if testing onboarding!
    // These lines allow the onboarding to run on every app cold start.
    //[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"ShowOnboarding"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    // Ensure toc show/hide animation scales the web view w/o vertical motion.
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    self.webView.scrollView.layer.anchorPoint = CGPointMake((isRTL ? 1.0 : 0.0), 0.0);

    [self tocUpdateViewLayout];
}

- (void)jumpToFragmentIfNecessary {
    if (self.jumpToFragment && (self.jumpToFragment.length > 0)) {
        [self.bridge sendMessage:@"scrollToFragment"
                     withPayload:@{ @"hash": self.jumpToFragment }];
    }
    self.jumpToFragment = nil;
}

- (void)autoScrollToLastScrollOffsetIfNecessary {
    if (!self.jumpToFragment) {
        [self.webView.scrollView setContentOffset:self.lastScrollOffset animated:NO];
    }
    [self saveWebViewScrollOffset];
}

- (void)tocUpdateViewLayout {
    CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat tocWidth     = [self tocGetWidthForWebViewScale:webViewScale];
    self.tocViewLeadingConstraint.constant = 0;
    self.tocViewWidthConstraint.constant   = tocWidth;
}

- (void)showAlert:(id)alertText type:(AlertType)type duration:(CGFloat)duration {
    if ([self tocDrawerIsOpen]) {
        return;
    }

    // Don't show alerts if onboarding onscreen.
    if ([self shouldShowOnboarding]) {
        return;
    }

    [super showAlert:alertText type:type duration:duration];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self doStuffOnAppear];
    [self.webView.scrollView wmf_shouldScrollToTopOnStatusBarTap:YES];
}

- (void)doStuffOnAppear {
    if ([self shouldShowOnboarding]) {
        [self showOnboarding];

        // Ok to show the menu now. (The onboarding view is covering the web view at this point.)
        ROOT.topMenuHidden = NO;

        self.webView.alpha = 1.0f;
    }

    // Don't move this to viewDidLoad - this is because viewDidLoad may only get
    // called very occasionally as app suspend/resume probably doesn't cause
    // viewDidLoad to fire.
    [self downloadAssetsFilesIfNecessary];

    [self performHousekeepingIfNecessary];

    //[self.view randomlyColorSubviews];
}

- (BOOL)shouldShowOnboarding {
    NSNumber* showOnboarding = [[NSUserDefaults standardUserDefaults] objectForKey:@"ShowOnboarding"];
    return showOnboarding.boolValue;
}

- (void)showOnboarding {
    OnboardingViewController* onboardingVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"OnboardingViewController"];

    onboardingVC.truePresentingVC = self;
    //[onboardingVC.view.layer removeAllAnimations];
    [self presentViewController:onboardingVC animated:NO completion:^{}];

    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"ShowOnboarding"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)performHousekeepingIfNecessary {
    NSDate* lastHousekeepingDate        = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHousekeepingDate"];
    NSInteger daysSinceLastHouseKeeping = [[NSDate date] daysAfterDate:lastHousekeepingDate];
    //NSLog(@"daysSinceLastHouseKeeping = %ld", (long)daysSinceLastHouseKeeping);
    if (daysSinceLastHouseKeeping > 1) {
        //NSLog(@"Performing housekeeping...");
        DataHousekeeping* dataHouseKeeping = [[DataHousekeeping alloc] init];
        [dataHouseKeeping performHouseKeeping];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastHousekeepingDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if ([self shouldShowOnboarding]) {
        self.webView.alpha = 0.0f;
    }

    [super viewWillAppear:animated];

    self.bottomMenuHidden = ROOT.topMenuHidden;
    self.referencesHidden = YES;

    ROOT.topMenuViewController.navBarMode = NAVBAR_MODE_DEFAULT;
    [ROOT.topMenuViewController updateTOCButtonVisibility];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];

    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];

    [super viewWillDisappear:animated];
}

#pragma mark Scroll indicator

static CGFloat const kScrollIndicatorMinYMargin = 4.0f;

- (void)scrollIndicatorSetup {
    self.scrollIndicatorView                                           = [[UIView alloc] init];
    self.scrollIndicatorView.opaque                                    = NO;
    self.scrollIndicatorView.backgroundColor                           = [UIColor wmf_colorWithHex:kScrollIndicatorBackgroundColor alpha:kScrollIndicatorAlpha];
    self.scrollIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollIndicatorView.layer.cornerRadius                        = kScrollIndicatorCornerRadius;

    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.showsVerticalScrollIndicator   = NO;

    [self.webView addSubview:self.scrollIndicatorView];

    self.scrollIndicatorViewTopConstraint =
        [NSLayoutConstraint constraintWithItem:self.scrollIndicatorView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.webView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:kScrollIndicatorMinYMargin];

    self.scrollIndicatorViewTopConstraint.priority = UILayoutPriorityDefaultLow;

    [self.view addConstraint:self.scrollIndicatorViewTopConstraint];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollIndicatorView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.webView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:-kScrollIndicatorLeftMargin]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollIndicatorView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:kScrollIndicatorWidth]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollIndicatorView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationLessThanOrEqual
                                                             toItem:self.webView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:-kScrollIndicatorMinYMargin]];

    self.scrollIndicatorViewHeightConstraint =
        [NSLayoutConstraint constraintWithItem:self.scrollIndicatorView
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1.0
                                      constant:kScrollIndicatorHeight];

    [self.view addConstraint:self.scrollIndicatorViewHeightConstraint];
}

- (CGFloat)footerMinimumScrollY {
    /*
       Reminder/Examples:
        VALUES  |   TOP OF FOOTER WOULD SCROLL

          0         Not past the top of the screen.
         100        100 pixels past the top of the screen.
        -100        100 pixels below the top of the screen.

     */
    if ([[SessionSingleton sharedInstance] articleIsAMainArticle:[[SessionSingleton sharedInstance] currentArticle]]) {
        // Prevent top of footer from being scrolled up past bottom of screen.
        return -self.view.frame.size.height;
    } else {
        // Prevent bottom of footer from being scrolled up past bottom of screen.
        return self.footerViewController.footerHeight - self.view.frame.size.height;
    }
}

- (void)scrollIndicatorMove {
    CGFloat f = self.webView.scrollView.contentSize.height - kBottomScrollSpacerHeight + [self footerMinimumScrollY];
    if (f == 0) {
        f = 0.00001f;
    }
    //self.scrollIndicatorView.alpha = [self tocDrawerIsOpen] ? 0.0f : 1.0f;
    CGFloat percent = self.webView.scrollView.contentOffset.y / f;
    //NSLog(@"percent = %f", percent);
    self.scrollIndicatorViewTopConstraint.constant = percent * (self.bottomBarView.frame.origin.y - kScrollIndicatorHeight) + kScrollIndicatorMinYMargin;
}

#pragma mark Sync config/ios.json if necessary

- (void)downloadAssetsFilesIfNecessary {
    // Sync config/ios.json at most once per day.
    [[QueuesSingleton sharedInstance].assetsFetchManager.operationQueue cancelAllOperations];

    (void)[[AssetsFileFetcher alloc] initAndFetchAssetsFileOfType:WMFAssetsFileTypeConfig
                                                      withManager:[QueuesSingleton sharedInstance].assetsFetchManager
                                                           maxAge:kWMFMaxAgeDefault];
}

#pragma mark Edit section

- (void)showSectionEditor {
    SectionEditorViewController* sectionEditVC =
        [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SectionEditorViewController"];

    sectionEditVC.section = session.currentArticle.sections[self.sectionToEditId];

    [ROOT pushViewController:sectionEditVC animated:YES];
}

- (void)searchFieldBecameFirstResponder {
    [self tocHide];
}

#pragma mark Update constraints

- (void)updateViewConstraints {
    [super updateViewConstraints];

    [self constrainBottomMenu];
}

#pragma mark Angle from velocity vector

- (CGFloat)getAngleInDegreesForVelocity:(CGPoint)velocity {
    // Returns angle from 0 to 360 (ccw from right)
    return (atan2(velocity.y, -velocity.x) / M_PI * 180 + 180);
}

- (CGFloat)getAbsoluteHorizontalDegreesFromVelocity:(CGPoint)velocity {
    // Returns deviation from horizontal axis in degrees.
    return (atan2(fabs(velocity.y), fabs(velocity.x)) / M_PI * 180);
}

#pragma mark Table of contents

- (BOOL)tocDrawerIsOpen {
    return !CGAffineTransformIsIdentity(self.webView.scrollView.transform);
}

- (void)tocHideWithDuration:(NSNumber*)duration {
    if ([self tocDrawerIsOpen]) {
        // Note: don't put this on the mainQueue. It can cause problems
        // if the toc needs to be hidden with 0 duration, such as when
        // the device is rotated. (could wrap this in a block and add
        // it to mainQueue if duration not 0, or directly call the block
        // if duration is 0, but I don't think we need to.)

        self.unsafeToToggleTOC = YES;

        // Save the scroll position; if we're near the end of the page things will
        // get reset correctly when we start to zoom out!
        __block CGPoint origScrollPosition = self.webView.scrollView.contentOffset;

        // Clear alerts
        [self fadeAlert];

        [UIView animateWithDuration:duration.floatValue
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            self.scrollIndicatorView.alpha = 1.0;
            // If the top menu isn't hidden, reveal the bottom menu.
            self.bottomMenuHidden = ROOT.topMenuHidden;

            self.webView.scrollView.transform = CGAffineTransformIdentity;

            self.referencesContainerView.transform = CGAffineTransformIdentity;

            self.bottomBarView.transform = CGAffineTransformIdentity;

            self.tocViewLeadingConstraint.constant = 0;

            [self.view layoutIfNeeded];
        } completion:^(BOOL done) {
            [self.tocVC didHide];
            self.unsafeToToggleTOC = NO;
            self.webView.scrollView.contentOffset = origScrollPosition;

            self.footerContainer.userInteractionEnabled = YES;

            WikiGlyphButton* tocButton = [ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TOC];
            [tocButton.label setWikiText:WIKIGLYPH_TOC_COLLAPSED
                                   color:tocButton.label.color
                                    size:tocButton.label.size
                          baselineOffset:tocButton.label.baselineOffset];

            self.webViewBottomConstraint.constant = 0;
        }];
    }
}

- (CGFloat)tocGetWebViewBottomConstraintConstant {
    /*
       When the TOC is shown, "self.webView.scrollView.transform" is changed, but this
       causes the height of the scrollView to be reduced, which doesn't mess anything up
       visually, but does cause the area beneath the scrollView to no longer respond to
       drag events.

       To reproduce the dragging deadspot issue solved by this offset:
        - set "self.webView.scrollView.layer.borderWidth = 10;"
        - comment out the line where the value returned by this method is used
        - run and open the TOC
        - notice the area beneath the border is not properly draggable

       So here we calculate the perfect bottom constraint constant to expand the "border"
       to completely encompass the vertical height of the scaled (when TOC is shown) webview.
     */
    CGFloat scale  = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat height = self.webView.scrollView.bounds.size.height;
    return (height - (height * scale)) * (1.0f / scale);
}

- (void)tocShowWithDuration:(NSNumber*)duration {
    if ([self tocDrawerIsOpen]) {
        return;
    }

    self.footerContainer.userInteractionEnabled = NO;

    self.webViewBottomConstraint.constant = [self tocGetWebViewBottomConstraintConstant];

    self.unsafeToToggleTOC = YES;

    // Hide any alerts immediately.
    [self hideAlert];

    [self.tocVC willShow];

    [self tocUpdateViewLayout];
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:duration.floatValue
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.scrollIndicatorView.alpha = 0.0;
        self.bottomMenuHidden = YES;
        self.referencesHidden = YES;

        CGFloat webViewScale = [self tocGetWebViewScaleWhenTOCVisible];
        CGAffineTransform xf = CGAffineTransformMakeScale(webViewScale, webViewScale);

        self.webView.scrollView.transform = xf;
        self.referencesContainerView.transform = xf;
        self.bottomBarView.transform = xf;

        CGFloat tocWidth = [self tocGetWidthForWebViewScale:webViewScale];
        self.tocViewLeadingConstraint.constant = -tocWidth;

        [self.view layoutIfNeeded];
    } completion:^(BOOL done) {
        self.unsafeToToggleTOC = NO;

        WikiGlyphButton* tocButton = [ROOT.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TOC];
        [tocButton.label setWikiText:WIKIGLYPH_TOC_EXPANDED
                               color:tocButton.label.color
                                size:tocButton.label.size
                      baselineOffset:tocButton.label.baselineOffset];
    }];
}

- (void)tocHide {
    if (self.unsafeToToggleTOC) {
        return;
    }

    [self tocHideWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

- (void)tocShow {
    // Prevent toc reveal if pull to refresh in effect.
    if (self.webView.scrollView.contentOffset.y < 0) {
        return;
    }

    // Prevent toc reveal if loading article.
    if (self.progressView.alpha > 0.0) {
        return;
    }

    if (!self.referencesHidden) {
        return;
    }

    if ([session articleIsAMainArticle:session.currentArticle]) {
        return;
    }

    if (self.unsafeToToggleTOC) {
        return;
    }

    [self tocShowWithDuration:TOC_TOGGLE_ANIMATION_DURATION];
}

- (void)tocToggle {
    // Clear alerts
    [self fadeAlert];

    [self referencesHide];

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    } else {
        [self tocShow];
    }
}

- (BOOL)shouldPanVelocityTriggerTOC:(CGPoint)panVelocity {
    CGFloat angleFromHorizontalAxis = [self getAbsoluteHorizontalDegreesFromVelocity:panVelocity];
    if (
        (angleFromHorizontalAxis < TOC_SWIPE_TRIGGER_MAX_ANGLE)
        &&
        (fabsf(panVelocity.x) > TOC_SWIPE_TRIGGER_MIN_X_VELOCITY)
        ) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    // Don't allow the web view's scroll view or the TOC's scroll view to start vertical scrolling if the
    // angle and direction of the swipe are within tolerances to trigger TOC toggle. Needed because you
    // don't want either of these to be scrolling vertically when the TOC is being revealed or hidden.
    //WHOA! see this: http://stackoverflow.com/a/18834934
    if (gestureRecognizer == self.panSwipeRecognizer) {
        if (
            (otherGestureRecognizer == self.webView.scrollView.panGestureRecognizer)
            ||
            (otherGestureRecognizer == self.tocVC.scrollView.panGestureRecognizer)
            ) {
            UIPanGestureRecognizer* otherPanRecognizer = (UIPanGestureRecognizer*)otherGestureRecognizer;
            CGPoint velocity                           = [otherPanRecognizer velocityInView:otherGestureRecognizer.view];
            if ([self shouldPanVelocityTriggerTOC:velocity]) {
                // Kill vertical scroll before it starts if we're going to show TOC.
                self.webView.scrollView.panGestureRecognizer.enabled = NO;
                self.webView.scrollView.panGestureRecognizer.enabled = YES;
                self.tocVC.scrollView.panGestureRecognizer.enabled   = NO;
                self.tocVC.scrollView.panGestureRecognizer.enabled   = YES;
            }
        }
    }
    return YES;
}

- (void)tocSetupSwipeGestureRecognizers {
    // Use pan instead for swipe so we can control speed at which swipe triggers. Idea from:
    // http://www.mindtreatstudios.com/how-its-made/ios-gesture-recognizer-tips-tricks/

    self.panSwipeRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanSwipe:)];
    self.panSwipeRecognizer.delegate               = self;
    self.panSwipeRecognizer.minimumNumberOfTouches = 1;
    [self.view addGestureRecognizer:self.panSwipeRecognizer];
}

- (void)handlePanSwipe:(UIPanGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:recognizer.view];

        if (![self shouldPanVelocityTriggerTOC:velocity] || self.webView.scrollView.isDragging) {
            return;
        }

        // Device rtl value is checked since this is what would cause the other constraints to flip.
        BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];

        if (velocity.x < 0) {
            //NSLog(@"swipe left");
            if (isRTL) {
                [self tocHide];
            } else {
                [self tocShow];
            }
        } else if (velocity.x > 0) {
            //NSLog(@"swipe right");
            if (isRTL) {
                [self tocShow];
            } else {
                [self tocHide];
            }
        }
    }
}

- (CGFloat)tocGetWebViewScaleWhenTOCVisible {
    CGFloat scale = 1.0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.6f : 0.7f);
    } else {
        scale = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.42f : 0.55f);
    }

    // Adjust scale so it won't result in fractional pixel width when applied to web view width.
    // This prevents the web view from jumping a bit w/long pages.
    NSInteger i        = (NSInteger)self.view.frame.size.width * scale;
    CGFloat cleanScale = (i / self.view.frame.size.width);

    return cleanScale;
}

- (CGFloat)tocGetWidthForWebViewScale:(CGFloat)webViewScale {
    return self.view.frame.size.width * (1.0f - webViewScale);
}

- (CGFloat)tocGetPercentOnscreen {
    CGFloat defaultWebViewScaleWhenTOCVisible = [self tocGetWebViewScaleWhenTOCVisible];
    CGFloat defaultTOCWidth                   = [self tocGetWidthForWebViewScale:defaultWebViewScaleWhenTOCVisible];
    return 1.0f - (fabsf(self.tocVC.view.frame.origin.x) / defaultTOCWidth);
}

- (BOOL)rectIntersectsWebViewTop:(CGRect)rect {
    CGFloat elementScreenYOffset =
        rect.origin.y - self.webView.scrollView.contentOffset.y + rect.size.height;
    return (elementScreenYOffset > 0) && (elementScreenYOffset < rect.size.height);
}

- (void)tocScrollWebViewToSectionWithElementId:(NSString*)elementId
                                      duration:(CGFloat)duration
                                   thenHideTOC:(BOOL)hideTOC {
    CGRect r = [self.webView getWebViewRectForHtmlElementWithId:elementId];
    if (CGRectIsNull(r)) {
        return;
    }

    // Determine if the element is already intersecting the top of the screen.
    // The method below is more efficient than calling
    // getScreenRectForHtmlElementWithId again (as it was already called by
    // getWebViewRectForHtmlElementWithId).
    // if ([self rectIntersectsWebViewTop:r]) return;

    CGPoint point = r.origin;

    // Leave x unchanged.
    point.x = self.webView.scrollView.contentOffset.x;

    // Scroll the section up just a tad more so the top of section div is just above top of web view.
    // This ensures the section that was scrolled to is considered the "current" section. (This is
    // because the current section is the one intersecting the top of the screen.)

    point.y += 2;

    if ([elementId isEqualToString:@"section_heading_and_content_block_0"]) {
        point = CGPointZero;
    }

    [self tocScrollWebViewToPoint:point
                         duration:duration
                      thenHideTOC:hideTOC];
}

- (void)tocScrollWebViewToPoint:(CGPoint)point
                       duration:(CGFloat)duration
                    thenHideTOC:(BOOL)hideTOC {
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        // Not using "setContentOffset:animated:" so duration of animation
        // can be controlled and action can be taken after animation completes.
        self.webView.scrollView.contentOffset = point;
    } completion:^(BOOL done) {
        // Record the new scroll location.
        [self saveWebViewScrollOffset];
        // Toggle toc.
        if (hideTOC) {
            [self tocHide];
        }
    }];
}

- (void)updateTOCScrollPositionIfVisible {
    if ([self tocDrawerIsOpen]) {
        [self.tocVC updateTOCForWebviewScrollPositionAnimated:YES];
    }
}

- (void)updateTOCScrollPositionWithoutAnimationIfHidden {
    if (![self tocDrawerIsOpen]) {
        [self.tocVC updateTOCForWebviewScrollPositionAnimated:NO];
    }
}

#pragma mark UIContainerViewControllerCallbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
    return YES;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if (
        (object == self.webView.scrollView)
        &&
        [keyPath isEqual:@"contentSize"]
        ) {
        [object preventHorizontalScrolling];
    }
}

#pragma mark Dealloc

- (void)dealloc {
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Webview obj-c to javascript bridge

- (CommunicationBridge*)bridge {
    if (!_bridge) {
        _bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];

        __weak WebViewController* weakSelf = self;
        [_bridge addListener:@"linkClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            NSString* href = payload[@"href"];

            if ([strSelf tocDrawerIsOpen]) {
                [strSelf tocHide];
                return;
            }

            if (!strSelf.referencesHidden) {
                [strSelf referencesHide];
            }

            // @todo merge this link title extraction into MWSite
            if ([href hasPrefix:@"/wiki/"]) {
                // Ensure the menu is visible when navigating to new page.
                [strSelf animateTopAndBottomMenuReveal];

                MWKTitle* pageTitle = [[SessionSingleton sharedInstance].currentArticleSite titleWithInternalLink:href];

                [strSelf navigateToPage:pageTitle
                        discoveryMethod:MWKHistoryDiscoveryMethodLink];
            } else if ([href hasPrefix:@"http:"] || [href hasPrefix:@"https:"] || [href hasPrefix:@"//"]) {
                // A standard external link, either explicitly http(s) or left protocol-relative on web meaning http(s)
                if ([href hasPrefix:@"//"]) {
                    // Expand protocol-relative link to https -- secure by default!
                    href = [@"https:" stringByAppendingString:href];
                }

                // TODO: make all of the stuff above parse the URL into parts
                // unless it's /wiki/ or #anchor style.
                // Then validate if it's still in Wikipedia land and branch appropriately.
                if ([SessionSingleton sharedInstance].zeroConfigState.disposition &&
                    [[NSUserDefaults standardUserDefaults] boolForKey:@"ZeroWarnWhenLeaving"]) {
                    strSelf.externalUrl = href;
                    UIAlertView* dialog = [[UIAlertView alloc]
                                           initWithTitle:MWLocalizedString(@"zero-interstitial-title", nil)
                                                     message:MWLocalizedString(@"zero-interstitial-leave-app", nil)
                                                    delegate:strSelf
                                           cancelButtonTitle:MWLocalizedString(@"zero-interstitial-cancel", nil)
                                           otherButtonTitles:MWLocalizedString(@"zero-interstitial-continue", nil)
                                           , nil];
                    [dialog show];
                } else {
                    NSURL* url = [NSURL URLWithString:href];
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];

        [_bridge addListener:@"editClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            if ([strSelf tocDrawerIsOpen]) {
                [strSelf tocHide];
                return;
            }

            if (strSelf.editable) {
                strSelf.sectionToEditId = [payload[@"sectionId"] integerValue];
                [strSelf showSectionEditor];
            } else {
                ProtectedEditAttemptFunnel* funnel = [[ProtectedEditAttemptFunnel alloc] init];
                [funnel logProtectionStatus:[[strSelf.protectionStatus allowedGroupsForAction:@"edit"] componentsJoinedByString:@","]];
                [strSelf showProtectedDialog];
            }
        }];

        [_bridge addListener:@"nonAnchorTouchEndedWithoutDragging" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            //NSLog(@"nonAnchorTouchEndedWithoutDragging = %@", payload);

            // Tiny delay prevents menus from occasionally appearing when user swipes to reveal toc.
            [strSelf performSelector:@selector(animateTopAndBottomMenuReveal) withObject:nil afterDelay:0.05];

            // nonAnchorTouchEndedWithoutDragging is used so TOC may be hidden if user tapped, but did *not* drag.
            // Used because UIWebView is difficult to attach one-finger touch events to.
            [strSelf tocHide];

            [strSelf referencesHide];
        }];

        [_bridge addListener:@"referenceClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            if ([strSelf tocDrawerIsOpen]) {
                [strSelf tocHide];
                return;
            }

            //NSLog(@"referenceClicked: %@", payload);
            [strSelf referencesShow:payload];
        }];

        /*
           [_bridge addListener:@"disambigClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {

           //NSLog(@"disambigClicked: %@", payload);

           }];

           [_bridge addListener:@"issuesClicked" withBlock:^(NSString* messageType, NSDictionary* payload) {

           //NSLog(@"issuesClicked: %@", payload);

           }];
         */

        UIMenuItem* shareSnippet = [[UIMenuItem alloc] initWithTitle:MWLocalizedString(@"share-custom-menu-item", nil)
                                                              action:@selector(shareSnippet:)];
        [UIMenuController sharedMenuController].menuItems = @[shareSnippet];

        [_bridge addListener:@"imageClicked" withBlock:^(NSString* type, NSDictionary* payload) {
            WebViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }

            NSString* selectedImageURL = payload[@"url"];
            NSCParameterAssert(selectedImageURL.length);
            MWKImage* selectedImage = [strSelf->session.currentArticle.images largestImageVariantForURL:selectedImageURL
                                                                                             cachedOnly:NO];
            NSCParameterAssert(selectedImage);
            [strSelf presentGalleryForArticle:strSelf->session.currentArticle showingImage:selectedImage];
        }];

        self.unsafeToScroll = NO;
    }
    return _bridge;
}

#pragma mark History

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    // Ensure the web VC is the top VC.
    [ROOT popToViewController:self animated:YES];

    [self fadeAlert];
}

#pragma Saved Pages

- (void)saveCurrentPage {
    MWKTitle* title          = session.currentArticle.title;
    MWKUserDataStore* store  = session.userDataStore;
    MWKSavedPageList* list   = store.savedPageList;
    MWKSavedPageEntry* entry = [list entryForTitle:title];

    SavedPagesFunnel* funnel = [[SavedPagesFunnel alloc] init];

    if (entry == nil) {
        // Show alert.
        [self showPageSavedAlertMessageForTitle:title.prefixedText];

        // Actually perform the save.
        entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
        [list addEntry:entry];

        [store save];
        [funnel logSaveNew];
    } else {
        // Unsave!
        [list removeEntry:entry];
        [store save];

        [self fadeAlert];
        [funnel logDelete];
    }
}

- (void)showPageSavedAlertMessageForTitle:(NSString*)title {
    // First show saved message.
    NSString* savedMessage = MWLocalizedString(@"share-menu-page-saved", nil);

    NSMutableAttributedString* attributedSavedMessage =
        [savedMessage attributedStringWithAttributes:@{}
                                 substitutionStrings:@[title]
                              substitutionAttributes:@[@{ NSFontAttributeName: [UIFont italicSystemFontOfSize:ALERT_FONT_SIZE] }]].mutableCopy;

    CGFloat duration                  = 2.0;
    BOOL AccessSavedPagesMessageShown = [[NSUserDefaults standardUserDefaults] boolForKey:@"AccessSavedPagesMessageShown"];

    //AccessSavedPagesMessageShown = NO;

    if (!AccessSavedPagesMessageShown) {
        duration = 5;
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"AccessSavedPagesMessageShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSString* accessMessage = [NSString stringWithFormat:@"\n%@", MWLocalizedString(@"share-menu-page-saved-access", nil)];

        NSDictionary* d = @{
            NSFontAttributeName: [UIFont wmf_glyphFontOfSize:ALERT_FONT_SIZE],
            NSBaselineOffsetAttributeName: @2
        };

        NSAttributedString* attributedAccessMessage =
            [accessMessage attributedStringWithAttributes:@{}
                                      substitutionStrings:@[WIKIGLYPH_W, WIKIGLYPH_HEART]
                                   substitutionAttributes:@[d, d]];


        [attributedSavedMessage appendAttributedString:attributedAccessMessage];
    }

    [self showAlert:attributedSavedMessage type:ALERT_TYPE_BOTTOM duration:duration];
}

#pragma mark Web view scroll offset recording

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollViewScrollingEnded:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
    [self scrollViewScrollingEnded:scrollView];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView*)scrollView {
    // If user quickly scrolls web view make toc update when user lifts finger.
    // (in addition to when scroll ends)
    if (scrollView == self.webView.scrollView) {
        [self updateTOCScrollPositionIfVisible];
    }
}

- (void)scrollViewScrollingEnded:(UIScrollView*)scrollView {
    if (scrollView == self.webView.scrollView) {
        // Once we've started scrolling around don't allow the webview delegate to scroll
        // to a saved position! Super annoying otherwise.
        self.unsafeToScroll = YES;

        //[self printLiveContentLocationTestingOutputToConsole];
        //NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
        [self saveWebViewScrollOffset];

        [self updateTOCScrollPositionIfVisible];
        [self updateTOCScrollPositionWithoutAnimationIfHidden];

        self.pullToRefreshView.alpha = 0.0f;
    }
}

- (void)saveWebViewScrollOffset {
    // Don't record scroll position of "main" pages.
    if ([session articleIsAMainArticle:session.currentArticle]) {
        return;
    }

    MWKHistoryEntry* entry = [session.userDataStore.historyList entryForTitle:session.currentArticle.title];
    if (entry) {
        entry.scrollPosition                    = self.webView.scrollView.contentOffset.y;
        session.userDataStore.historyList.dirty = YES;         // hack to force
        [session.userDataStore save];
    }
}

#pragma mark Web view html content live location retrieval

- (void)printLiveContentLocationTestingOutputToConsole {
    // Test with the top image (presently) on the San Francisco article.
    // (would test p.x and p.y against CGFLOAT_MAX to ensure good value was retrieved)
    CGPoint p = [self.webView getScreenCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p = %@", NSStringFromCGPoint(p));

    CGPoint p2 = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    NSLog(@"p2 = %@", NSStringFromCGPoint(p2));

    // Also test location of second section on page.
    // (would test r with CGRectIsNull(r) to ensure good values were retrieved)
    CGRect r = [self.webView getScreenRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
    NSLog(@"r = %@", NSStringFromCGRect(r));

    CGRect r2 = [self.webView getWebViewRectForHtmlElementWithId:@"section_heading_and_content_block_1"];
    NSLog(@"r2 = %@", NSStringFromCGRect(r2));
}

- (void)debugScrollLeadSanFranciscoArticleImageToTopLeft {
    // Awesome! Now works regarless of pinch-zoom scale!
    CGPoint p = [self.webView getWebViewCoordsForHtmlImageWithSrc:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/da/SF_From_Marin_Highlands3.jpg/280px-SF_From_Marin_Highlands3.jpg"];
    [self.webView.scrollView setContentOffset:p animated:YES];
}

#pragma mark Web view limit scroll up

- (void)limitScrollUp:(UIScrollView*)webScrollView {
    // When trying to scroll the bottom of the web view article all the way to
    // the top, this is the minimum amount that will be allowed to be onscreen
    // before we limit scrolling.
    CGFloat onscreenMinHeight = -[self footerMinimumScrollY];

    CGFloat offsetMaxY = kBottomScrollSpacerHeight + onscreenMinHeight;

    if ((webScrollView.contentSize.height - webScrollView.contentOffset.y) < offsetMaxY) {
        CGPoint p = CGPointMake(webScrollView.contentOffset.x,
                                webScrollView.contentSize.height - offsetMaxY);

        // This limits scrolling!
        [webScrollView setContentOffset:p animated:NO];
    }
}

- (void)keyboardDidShow:(NSNotification*)note {
    self.keyboardIsVisible = YES;
}

- (void)keyboardWillHide:(NSNotification*)note {
    self.keyboardIsVisible = NO;
}

#pragma mark Scroll hiding keyboard threshold

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (scrollView == self.webView.scrollView) {
        [self limitScrollUp:scrollView];
    }

    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled     = scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y;
    CGFloat fabsDistanceScrolled = fabs(distanceScrolled);

    if (self.keyboardIsVisible && fabsDistanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self hideKeyboard];
        //NSLog(@"Keyboard Hidden!");
    }

    [self scrollIndicatorMove];

    if (![self tocDrawerIsOpen]) {
        [self adjustTopAndBottomMenuVisibilityOnScroll];
        // No need to report scroll event to pull to refresh super vc if toc open.
        [super scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    scrollViewDragBeganVerticalOffset_ = scrollView.contentOffset.y;
}

- (void)scrollViewDidScrollToTop:(UIScrollView*)scrollView {
    [self updateTOCScrollPositionIfVisible];
    [self updateTOCScrollPositionWithoutAnimationIfHidden];
    [self saveWebViewScrollOffset];
    self.scrollingToTop = NO;
}

#pragma mark Menus auto show-hide on scroll / reveal on tap

- (void)adjustTopAndBottomMenuVisibilityOnScroll {
    // This method causes the menus to hide when user scrolls down and show when they scroll up.
    if (self.webView.scrollView.isDragging && ![self tocDrawerIsOpen]) {
        CGFloat distanceScrolled  = scrollViewDragBeganVerticalOffset_ - self.webView.scrollView.contentOffset.y;
        CGFloat minPixelsScrolled = 20;

        // Reveal menus if scroll velocity is a bit fast. Point is to avoid showing the menu
        // if the user is *slowly* scrolling. This is how Safari seems to handle things.
        CGPoint scrollVelocity = [self.webView.scrollView.panGestureRecognizer velocityInView:self.view];
        if (distanceScrolled > 0) {
            // When pulling down let things scroll a bit faster before menus reveal is triggered.
            if (scrollVelocity.y < 350.0f) {
                return;
            }
        } else {
            // When pushing up set a lower scroll velocity threshold to hide menus.
            if (scrollVelocity.y > -250.0f) {
                return;
            }
        }

        if (fabsf(distanceScrolled) < minPixelsScrolled) {
            return;
        }
        [ROOT animateTopAndBottomMenuHidden:((distanceScrolled > 0) ? NO : YES)];

        [self referencesHide];
    }
}

- (void)animateTopAndBottomMenuReveal {
    // Toggle the menus closed on tap (only if they were showing).
    if (![self tocDrawerIsOpen]) {
        if (ROOT.topMenuViewController.navBarMode != NAVBAR_MODE_SEARCH) {
            [ROOT animateTopAndBottomMenuHidden:NO];
        }
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView*)scrollView {
    self.scrollingToTop = YES;
    [self referencesHide];

    // Called when the title bar is tapped.
    [self animateTopAndBottomMenuReveal];
    return YES;
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    //[self downloadAssetsFilesIfNecessary];

    /*
       OnboardingViewController *onboardingVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"OnboardingViewController"];
       [self presentViewController:onboardingVC animated:YES completion:^{}];
     */

    /*
       AccountCreationViewController *createAcctVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"AccountCreationViewController"];

       [ROOT pushViewController:createAcctVC animated:YES];
     */

    //DataHousekeeping *dataHouseKeeping = [[DataHousekeeping alloc] init];
    //[dataHouseKeeping performHouseKeeping];

    // Do not remove the following commented toggle. It's for testing W0 stuff.
    //[session.zeroConfigState toggleFakeZeroOn];

    //[self toggleImageSheet];

    //ReferencesVC *referencesVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ReferencesVC"];
    //[self presentViewController:referencesVC animated:YES completion:^{}];

    //NSLog(@"articleFetchManager.operationCount = %lu", (unsigned long)[QueuesSingleton sharedInstance].articleFetchManager.operationQueue.operationCount);
}

#if DEBUG
- (void)toggleImageSheet {
    // Quick hack for confirming images for article have routed properly to core data store.
    // To do this for real, probably need to make separate view controller - could still present
    // images using save autolayout stacking as "topActionSheetShowWithViews", but would need to
    // determine which UIImageViews were scrolled offscreen and nil their image property out
    // until they're not offscreen. Could do separate UIImageView class to make this easier - it
    // would have a property with the image's core data ImageData NSManagedObjectID. That way
    // it could simply re-retrieve its image data whenever it needed to.
    static BOOL showImageSheet = NO;
    showImageSheet = !showImageSheet;

    if (showImageSheet) {
        MWKArticle* article   = session.currentArticle;
        NSMutableArray* views = @[].mutableCopy;
        for (MWKSection* section in article.sections) {
            int index = 0;
            for (MWKImage* image in [section.images uniqueLargestVariants]) {
                NSString* title = (section.line) ? section.line : article.title.prefixedText;
                //NSLog(@"\n\n\nsection image = %@ \n\tsection = %@ \n\tindex in section = %@ \n\timage size = %@", sectionImage.image.fileName, sectionTitle, sectionImage.index, sectionImage.image.dataSize);
                if (index == 0) {
                    PaddedLabel* label = [[PaddedLabel alloc] init];
                    label.padding       = UIEdgeInsetsMake(20, 20, 10, 20);
                    label.numberOfLines = 0;
                    label.textColor     = [UIColor darkGrayColor];
                    label.lineBreakMode = NSLineBreakByWordWrapping;
                    label.font          = [UIFont systemFontOfSize:30];
                    label.textAlignment = NSTextAlignmentCenter;
                    title               = [title wmf_stringByRemovingHTML];
                    label.text          = title;
                    [views addObject:label];
                }
                if (image.isCached) {
                    UIImage* img           = [image asUIImage];
                    UIImageView* imageView = [[UIImageView alloc] initWithImage:img];
                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                    [views addObject:imageView];
                    UIView* spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
                    [views addObject:spacerView];
                    index++;
                }
            }
        }
        NSLog(@"%@", views);
        [NAV topActionSheetShowWithViews:views orientation:TABULAR_SCROLLVIEW_LAYOUT_HORIZONTAL];
    } else {
        [NAV topActionSheetHide];
    }
}

#endif

- (void)updateHistoryDateVisitedForArticleBeingNavigatedFrom {
    // This is a quick hack to help with the natural back/forward behavior of the case
    // where you go back and forth from some master article to others.
    //
    // Proper fix might be to store more of a 'tree' structure so that we know which
    // 'leaf' to hang off of, but this works for now.
    MWKHistoryList* historyList = session.userDataStore.historyList;
    //NSLog(@"XXX %d", (int)historyList.length);
    if (historyList.length > 0) {
        // Grab the latest
        MWKHistoryEntry* historyEntry = [historyList entryForTitle:session.currentArticle.title];
        if (historyEntry) {
            historyEntry.date = [NSDate date];
            [historyList addEntry:historyEntry];
            [session.userDataStore save];
        }
    }
}

#pragma mark - Article loading

- (void)navigateToPage:(MWKTitle*)title
       discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    NSString* cleanTitle = title.prefixedText;

    // Don't try to load nothing. Core data takes exception with such nonsense.
    if (cleanTitle == nil) {
        return;
    }
    if (cleanTitle.length == 0) {
        return;
    }

    [self hideKeyboard];

    // Show loading message
    //[self showAlert:MWLocalizedString(@"search-loading-section-zero", nil) type:ALERT_TYPE_TOP duration:-1];

    self.jumpToFragment = title.fragment;

    if (discoveryMethod != MWKHistoryDiscoveryMethodBackForward && discoveryMethod != MWKHistoryDiscoveryMethodReload) {
        [self updateHistoryDateVisitedForArticleBeingNavigatedFrom];
    }

    [self retrieveArticleForPageTitle:title
                      discoveryMethod:discoveryMethod];

    /*
       // Reset the search field to its placeholder text after 5 seconds.
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TopMenuTextFieldContainer *textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        if (!textFieldContainer.textField.isFirstResponder) textFieldContainer.textField.text = @"";
       });
     */
}

- (void)reloadCurrentArticle {
    [self navigateToPage:session.currentArticle.title
         discoveryMethod:MWKHistoryDiscoveryMethodReload];
}

- (void)cancelArticleLoading {
    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];
}

- (void)cancelSearchLoading {
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)retrieveArticleForPageTitle:(MWKTitle*)pageTitle
                    discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    // Cancel certain in-progress fetches.
    [self cancelSearchLoading];
    [self cancelArticleLoading];

    self.currentTitle = pageTitle;

    MWKArticle* article = [session.dataStore articleWithTitle:self.currentTitle];
    session.currentArticle                = article;
    session.currentArticleDiscoveryMethod = discoveryMethod;

    switch (session.currentArticleDiscoveryMethod) {
        case MWKHistoryDiscoveryMethodSearch:
        case MWKHistoryDiscoveryMethodRandom:
        case MWKHistoryDiscoveryMethodLink:
        case MWKHistoryDiscoveryMethodReload:
        case MWKHistoryDiscoveryMethodUnknown: {
            // Mark article as needing refreshing so its data will be re-downloaded.
            // Reminder: this needs to happen *after* "session.title" has been updated
            // with the title of the article being retrieved. Otherwise you end up
            // marking the previous article as needing to be refreshed.
            session.currentArticle.needsRefresh = YES;
            break;
        }

        case MWKHistoryDiscoveryMethodSaved:
        case MWKHistoryDiscoveryMethodBackForward:
            break;
    }

    // If article is cached
    if ([article isCached] && !article.needsRefresh) {
        [self displayArticle:session.currentArticle.title];
        //[self showAlert:MWLocalizedString(@"search-loading-article-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
        [self fadeAlert];
    } else {
        if (discoveryMethod != MWKHistoryDiscoveryMethodBackForward) {
            [self showProgressViewAnimated:YES];
        }

        // "fetchFinished:" above will be notified when articleFetcher has actually retrieved some data.
        // Note: cast to void to avoid compiler warning: http://stackoverflow.com/a/7915839
        (void)[[ArticleFetcher alloc] initAndFetchSectionsForArticle:session.currentArticle
                                                         withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                  thenNotifyDelegate:self];
    }
}

#pragma mark - ArticleFetcherDelegate

- (void)articleFetcher:(ArticleFetcher*)savedArticlesFetcher
     didUpdateProgress:(CGFloat)progress {
    [self updateProgress:[self totalProgressWithArticleFetcherProgress:progress] animated:YES];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[ArticleFetcher class]]) {
        MWKArticle* article = session.currentArticle;

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                // Redirect if necessary.
                MWKTitle* redirectedTitle = article.redirected;
                if (redirectedTitle) {
                    // Get discovery method for call to "retrieveArticleForPageTitle:".
                    // There should only be a single history item (at most).
                    MWKHistoryEntry* history = [session.userDataStore.historyList entryForTitle:article.title];
                    // Get the article's discovery method.
                    MWKHistoryDiscoveryMethod discoveryMethod =
                        (history) ? history.discoveryMethod : MWKHistoryDiscoveryMethodSearch;

                    // Redirect!
                    [self retrieveArticleForPageTitle:redirectedTitle
                                      discoveryMethod:discoveryMethod];
                    return;
                }

                // Update the toc and web view.
                [self displayArticle:article.title];

                [self hideAlert];
            }
            break;

            case FETCH_FINAL_STATUS_FAILED:
            {
                [self displayArticle:article.title];

                NSString* errorMsg = error.localizedDescription;
                [self showAlert:errorMsg type:ALERT_TYPE_TOP duration:-1];

                [self hideProgressViewAnimated:YES];
            }
            break;

            case FETCH_FINAL_STATUS_CANCELLED:
            {
            }
            break;

            default:
                break;
        }
    } else if ([sender isKindOfClass:[WikipediaZeroMessageFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                NSDictionary* banner = (NSDictionary*)fetchedData;
                if (banner) {
                    TopMenuTextFieldContainer* textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
                    textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text-zero", nil);

                    //[self showAlert:title type:ALERT_TYPE_TOP duration:2];
                    NSString* title = banner[@"message"];
                    self.zeroStatusLabel.text            = title;
                    self.zeroStatusLabel.padding         = UIEdgeInsetsMake(3, 10, 3, 10);
                    self.zeroStatusLabel.textColor       = banner[@"foreground"];
                    self.zeroStatusLabel.backgroundColor = banner[@"background"];

                    [NAV promptFirstTimeZeroOnWithTitleIfAppropriate:title];
                }
            }
            break;

            case FETCH_FINAL_STATUS_FAILED:
            {
            }
            break;

            case FETCH_FINAL_STATUS_CANCELLED:
            {
            }
            break;
        }
    }
}

#pragma mark - Lead image

- (NSString*)leadImageGetHtml {
    // Get lead image html structured such that no JS bridge messages are needed for lead image presentation.
    // Set everything here via css before the html payload is delivered to the web view.

    MWKArticle* article = session.currentArticle;

    if ([session articleIsAMainArticle:article]) {
        return @"";
    }

    NSString* title       = article.displaytitle;
    NSString* description = article.entityDescription ? [[article.entityDescription wmf_stringByRemovingHTML] wmf_stringByCapitalizingFirstCharacter] : @"";

    BOOL hasImage          = article.imageURL ? YES : NO;
    CGFloat fontMultiplier = [self leadImageGetSizeReductionMultiplierForTitleOfLength:title.length];

    // offsetY is percent to shift image vertically. 0 aligns top to top of lead_image_div,
    // 50 centers it vertically, and 100 aligns bottom of image to bottom of lead_image_div.
    NSInteger offsetY = 25;

    if (hasImage) {
        CGRect focalRect = [article.image primaryFocalRectNormalizedToImageSize:NO];
        if (!CGRectEqualToRect(focalRect, CGRectZero)) {
            offsetY = [self leadImageFocalOffsetYPercentageFromTopOfRect:focalRect];
        }
    }

    NSString* leadImageDivStyleOverrides =
        !hasImage ? @"" : [NSString stringWithFormat:
                           @"background-image:-webkit-linear-gradient(top, rgba(0,0,0,0.0) 0%%, rgba(0,0,0,0.5) 100%%),"
                           @"url('%@')"
                           @"%@;"
                           "background-position: calc(50%%) calc(%ld%%);",
                           article.imageURL,
                           [article.image isCached] ? @"" : @",url('wmf://bundledImage/lead-default.png')",
                           offsetY];

    NSString* leadImageHtml =
        [NSString stringWithFormat:
         @"<div id='lead_image_div' class='lead_image_div' style=\"%@\">"
         "<div id='lead_image_text_container'>"
         "<div id='lead_image_title' style='%@'>%@</div>"
         "<div id='lead_image_description' style='%@'>%@</div>"
         "</div>"
         "</div>",
         leadImageDivStyleOverrides,
         [NSString stringWithFormat:@"font-size:%.02fpx;", 34.0f * fontMultiplier],
         title,
         [NSString stringWithFormat:@"font-size:%.02fpx;", 17.0f],
         description
        ];

    if (!hasImage) {
        leadImageHtml = [NSString stringWithFormat:@"<div id='lead_image_none'>%@</div>", leadImageHtml];
    }

    return leadImageHtml;
}

- (CGFloat)leadImageGetSizeReductionMultiplierForTitleOfLength:(NSUInteger)length {
    // Quick hack for shrinking long titles in rough proportion to their length.

    CGFloat multiplier = 1.0f;

    // Assume roughly title 28 chars per line. Note this doesn't take in to account
    // interface orientation, which means the reduction is really not strictly
    // in proportion to line count, rather to string length. This should be ok for
    // now. Search for "lopado" and you'll see an insanely long title in the search
    // results, which is nice for testing, and which this seems to handle.
    // Also search for "list of accidents" for lots of other long title articles,
    // many with lead images.

    CGFloat charsPerLine = 28;
    CGFloat lines        = ceil(length / charsPerLine);

    // For every 2 "lines" (after the first 2) reduce title text size by 10%.
    if (lines > 2) {
        CGFloat linesAfter2Lines = lines - 2;
        multiplier = 1.0f - (linesAfter2Lines * 0.1f);
    }

    // Don't shrink below 60%.
    return MAX(multiplier, 0.6f);
}

- (void)sectionImageRetrieved:(NSNotification*)notification {
    NSDictionary* payload = notification.userInfo;
    NSNumber* isLeadImage = payload[kURLCacheKeyIsLeadImage];
    if (isLeadImage.boolValue) {
        [self leadImageRetrieved:notification];
    }
}

- (void)leadImageRetrieved:(NSNotification*)notification {
    [self leadImageHidePlaceHolderAndCenterOnFaceIfNeeded:notification];
}

- (NSInteger)leadImageFocalOffsetYPercentageFromTopOfRect:(CGRect)rect {
    float percentFromTop = (CGRectGetMidY(rect) * 100.0f);
    return @(MAX(0, MIN(100, percentFromTop))).integerValue;
}

- (void)leadImageHidePlaceHolderAndCenterOnFaceIfNeeded:(NSNotification*)notification {
    static NSString* hidePlaceholderJS = nil;
    if (!hidePlaceholderJS) {
        hidePlaceholderJS = @"document.getElementById('lead_image_div').style.backgroundImage = document.getElementById('lead_image_div').style.backgroundImage.replace('wmf://bundledImage/lead-default.png', 'wmf://bundledImage/empty.png');";
    }

    NSDictionary* payload = notification.userInfo;
    NSString* stringRect  = payload[kURLCacheKeyPrimaryFocalUnitRectString];
    CGRect rect           = CGRectFromString(stringRect);

    NSString* applyFocalOffsetJS = @"";
    if (!CGRectEqualToRect(rect, CGRectZero)) {
        NSInteger yFocalOffset = [self leadImageFocalOffsetYPercentageFromTopOfRect:rect];
        applyFocalOffsetJS = [NSString stringWithFormat:@"document.getElementById('lead_image_div').style.backgroundPosition = 'calc(100%%) calc(%ld%%)';", yFocalOffset];
    }

    static NSString* animationCss = nil;
    if (!animationCss) {
        animationCss =
            @"document.getElementById('lead_image_div').style.transition = 'background-position 0.8s';";
    }

    NSString* js = [NSString stringWithFormat:@"%@%@%@", animationCss, hidePlaceholderJS, applyFocalOffsetJS];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark Display article from data store

- (void)displayArticle:(MWKTitle*)title {
    MWKArticle* article = [session.dataStore articleWithTitle:title];
    session.currentArticle = article;

    if (![article isCached]) {
        return;
    }

    switch (session.currentArticleDiscoveryMethod) {
        case MWKHistoryDiscoveryMethodSaved:
        case MWKHistoryDiscoveryMethodSearch:
        case MWKHistoryDiscoveryMethodRandom:
        case MWKHistoryDiscoveryMethodLink:
        case MWKHistoryDiscoveryMethodUnknown: {
            // Update the history so the most recently viewed article appears at the top.
            [session.userDataStore updateHistory:title discoveryMethod:session.currentArticleDiscoveryMethod];
            break;
        }

        case MWKHistoryDiscoveryMethodReload:
        case MWKHistoryDiscoveryMethodBackForward:
            // Traversing history should not alter it, and should be served from the cache.
            break;
    }


    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:title.site.language];
    NSString* uidir              = ([WikipediaAppUtils isDeviceLanguageRTL] ? @"rtl" : @"ltr");

    int langCount           = article.languagecount;
    NSDate* lastModified    = article.lastmodified;
    MWKUser* lastModifiedBy = article.lastmodifiedby;
    self.editable         = article.editable;
    self.protectionStatus = article.protection;

    [self.bottomMenuViewController updateBottomBarButtonsEnabledState];

    [ROOT.topMenuViewController updateTOCButtonVisibility];

    NSMutableArray* sectionTextArray = [[NSMutableArray alloc] init];

    for (MWKSection* section in session.currentArticle.sections) {
        NSString* html = nil;

        @try {
            html = section.text;
        }@catch (NSException* exception) {
            NSAssert(html, @"html was not created from section %@: %@", section.title, section.text);
        }

        if (!html) {
            html = MWLocalizedString(@"article-unable-to-load-section", nil);;
        }

        // Structural html added around section html just before display.
        NSString* sectionHTMLWithID = [section displayHTML:html];
        [sectionTextArray addObject:sectionHTMLWithID];
    }

    if (session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodSaved ||
        session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodBackForward ||
        session.currentArticleDiscoveryMethod == MWKHistoryDiscoveryMethodReload) {
        MWKHistoryEntry* historyEntry = [session.userDataStore.historyList entryForTitle:article.title];
        CGPoint scrollOffset          = CGPointMake(0, historyEntry.scrollPosition);
        self.lastScrollOffset = scrollOffset;
    } else {
        CGPoint scrollOffset = CGPointMake(0, 0);
        self.lastScrollOffset = scrollOffset;
    }

    if (![session articleIsAMainArticle:session.currentArticle]) {
        NSString* lastModifiedByUserName =
            (lastModifiedBy && !lastModifiedBy.anonymous) ? lastModifiedBy.name : nil;
        [self.footerViewController updateLanguageCount:langCount];
        [self.footerViewController updateLastModifiedDate:lastModified userName:lastModifiedByUserName];
        [self.footerViewController updateReadMoreForArticle:article];
        [self.footerViewController updateLegalFooterLocalizedText];

        // Add spacer above bottom native tracking component.
        [sectionTextArray addObject:@"<div style='background-color:transparent;height:40px;'></div>"];

        // Add target div for TOC "read more" entry so it can use existing
        // TOC scrolling mechanism.
        [sectionTextArray addObject:@"<div id='section_heading_and_content_block_100000'></div>"];
    }

    // This is important! Ensures bottom of web view article can be scrolled closer to the top of
    // the screen. Works in conjunction with "limitScrollUp:" method.
    // Note: had to add "px" to the height because we added "<!DOCTYPE html>" to the top
    // of the index.html - it won't actually give the div height w/o this now (no longer
    // using quirks mode now that doctype specified).
    [sectionTextArray addObject:[NSString stringWithFormat:@"<div style='height:%dpx;background-color:white;'></div>", (int)kBottomScrollSpacerHeight]];

    // Join article sections text
    NSString* joint   = @"";     //@"<div style=\"height:20px;\"></div>";
    NSString* htmlStr = [sectionTextArray componentsJoinedByString:joint];

    // If any of these are nil, the bridge "sendMessage:" calls will crash! So catch 'em here.
    BOOL safeToCrossBridge = (languageInfo.code && languageInfo.dir && uidir && htmlStr);
    if (!safeToCrossBridge) {
        NSLog(@"\n\nUnsafe to cross JS bridge!");
        NSLog(@"\tlanguageInfo.code = %@", languageInfo.code);
        NSLog(@"\tlanguageInfo.dir = %@", languageInfo.dir);
        NSLog(@"\tuidir = %@", uidir);
        NSLog(@"\thtmlStr is nil = %d\n\n", (htmlStr == nil));
        //TODO: output "could not load page" alert and/or show last page?
        return;
    }

    [self.bridge loadHTML:htmlStr withAssetsFile:@"index.html" leadSectionHtml:[self leadImageGetHtml]];

    // NSLog(@"languageInfo = %@", languageInfo.code);
    [self.bridge sendMessage:@"setLanguage"
                 withPayload:@{
         @"lang": languageInfo.code,
         @"dir": languageInfo.dir,
         @"uidir": uidir
     }];

    if (!self.editable) {
        [self.bridge sendMessage:@"setPageProtected" withPayload:@{}];
    }

    if ([self tocDrawerIsOpen]) {
        [self tocHide];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgress:0.85 animated:YES];
    });
}

#pragma mark Scroll to last section after rotate

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSString* js = @"(function() {"
                   @"    _topElement = document.elementFromPoint( window.innerWidth / 2, 0 );"
                   @"    if (_topElement) {"
                   @"        var rect = _topElement.getBoundingClientRect();"
                   @"        return rect.top / rect.height;"
                   @"    } else {"
                   @"        return 0;"
                   @"    }"
                   @"})()";
    float relativeScrollOffset = [[self.webView stringByEvaluatingJavaScriptFromString:js] floatValue];
    self.relativeScrollOffsetBeforeRotate = relativeScrollOffset;

    [self tocHideWithDuration:@0.0f];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self tocUpdateViewLayout];

    [self scrollToElementOnScreenBeforeRotate];
}

- (void)scrollToElementOnScreenBeforeRotate {
    NSString* js = @"(function() {"
                   @"    if (_topElement) {"
                   @"    if (_topElement.id && (_topElement.id === 'lead_image_div')) return 0;"
                   @"        var rect = _topElement.getBoundingClientRect();"
                   @"        return (window.scrollY + rect.top) - (%f * rect.height);"
                   @"    } else {"
                   @"        return 0;"
                   @"    }"
                   @"})()";
    NSString* js2         = [NSString stringWithFormat:js, self.relativeScrollOffsetBeforeRotate, self.relativeScrollOffsetBeforeRotate];
    int finalScrollOffset = [[self.webView stringByEvaluatingJavaScriptFromString:js2] intValue];

    CGPoint point = CGPointMake(0, finalScrollOffset);

    [self tocScrollWebViewToPoint:point
                         duration:0
                      thenHideTOC:NO];
}

#pragma mark Wikipedia Zero handling

- (void)zeroStateChanged:(NSNotification*)notification {
    [[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager.operationQueue cancelAllOperations];

    if ([[[notification userInfo] objectForKey:@"state"] boolValue]) {
        (void)[[WikipediaZeroMessageFetcher alloc] initAndFetchMessageForDomain:session.currentArticleSite.language
                                                                    withManager:[QueuesSingleton sharedInstance].zeroRatedMessageFetchManager
                                                             thenNotifyDelegate:self];
    } else {
        TopMenuTextFieldContainer* textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
        textFieldContainer.textField.placeholder = MWLocalizedString(@"search-field-placeholder-text", nil);
        NSString* warnVerbiage = MWLocalizedString(@"zero-charged-verbiage", nil);

        CGFloat duration = 5.0f;

        //[self showAlert:warnVerbiage type:ALERT_TYPE_TOP duration:duration];
        self.zeroStatusLabel.text            = warnVerbiage;
        self.zeroStatusLabel.backgroundColor = [UIColor redColor];
        self.zeroStatusLabel.textColor       = [UIColor whiteColor];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.zeroStatusLabel.text = @"";
            self.zeroStatusLabel.padding = UIEdgeInsetsZero;
        });

        [NAV promptZeroOff];
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        NSURL* url = [NSURL URLWithString:self.externalUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (UIScrollView*)refreshScrollView {
    return self.webView.scrollView;
}

- (NSString*)refreshPromptString {
    return MWLocalizedString(@"article-pull-to-refresh-prompt", nil);
}

- (NSString*)refreshRunningString {
    return MWLocalizedString(@"article-pull-to-refresh-is-refreshing", nil);
}

- (void)refreshWasPulled {
    [self reloadCurrentArticle];
}

- (BOOL)refreshShouldShow {
    return (![self tocDrawerIsOpen])
           &&
           (session.currentArticle != nil)
           &&
           (!ROOT.isAnimatingTopAndBottomMenuHidden);
}

#pragma mark Bottom menu bar

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"BottomMenuViewController_embed2"]) {
        self.bottomMenuViewController = (BottomMenuViewController*)[segue destinationViewController];
    }

    if ([segue.identifier isEqualToString:@"TOCViewController_embed"]) {
        self.tocVC       = (TOCViewController*)[segue destinationViewController];
        self.tocVC.webVC = self;
    }
}

- (void)setBottomMenuHidden:(BOOL)bottomMenuHidden {
    if (self.bottomMenuHidden == bottomMenuHidden) {
        return;
    }

    _bottomMenuHidden = bottomMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = bottomMenuHidden ? 0.0 : 1.0;

    self.bottomBarView.alpha = alpha;
}

- (void)constrainBottomMenu {
    // If visible, constrain bottom of bottomNavBar to bottom of superview.
    // If hidden, constrain top of bottomNavBar to bottom of superview.

    if (self.bottomBarViewBottomConstraint) {
        [self.view removeConstraint:self.bottomBarViewBottomConstraint];
    }

    self.bottomBarViewBottomConstraint =
        [NSLayoutConstraint constraintWithItem:self.bottomBarView
                                     attribute:((self.bottomMenuHidden) ? NSLayoutAttributeTop : NSLayoutAttributeBottom)
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0];

    [self.view addConstraint:self.bottomBarViewBottomConstraint];
}

- (void)showProtectedDialog {
    UIAlertView* alert = [[UIAlertView alloc] init];
    alert.title   = MWLocalizedString(@"page_protected_can_not_edit_title", nil);
    alert.message = MWLocalizedString(@"page_protected_can_not_edit", nil);
    [alert addButtonWithTitle:@"OK"];
    alert.cancelButtonIndex = 0;
    [alert show];
}

#pragma mark Refs

- (void)setReferencesHidden:(BOOL)referencesHidden {
    if (self.referencesHidden == referencesHidden) {
        return;
    }

    _referencesHidden = referencesHidden;

    [self updateReferencesHeightAndBottomConstraints];

    if (referencesHidden) {
        // Cause the highlighted ref link in the webView to no longer be highlighted.
        [self.referencesVC reset];
    }

    // Fade out refs when hidden.
    CGFloat alpha = referencesHidden ? 0.0 : 1.0;

    self.referencesContainerView.alpha = alpha;
}

- (void)updateReferencesHeightAndBottomConstraints {
    CGFloat refsHeight = [self getRefsPanelHeight];
    self.referencesContainerViewBottomConstraint.constant = self.referencesHidden ? refsHeight : 0.0;
    self.referencesContainerViewHeightConstraint.constant = refsHeight;
}

- (CGFloat)getRefsPanelHeight {
    CGFloat percentOfHeight = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0.4 : 0.6;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        percentOfHeight *= 0.5;
    }
    NSNumber* refsHeight = @((self.view.frame.size.height * MENUS_SCALE_MULTIPLIER) * percentOfHeight);
    return (CGFloat)refsHeight.integerValue;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Reminder: do tocHideWithDuration in willRotateToInterfaceOrientation, not here
    // (even though it makes the toc animate offscreen nicely if it was onscreen) as
    // it messes up in rtl langs for some reason, blanking out the screen.
    //[self tocHideWithDuration:@0.0f];

    [self updateReferencesHeightAndBottomConstraints];
}

- (BOOL)didFindReferencesInPayload:(NSDictionary*)payload {
    NSArray* refs = payload[@"refs"];
    if (!refs || (refs.count == 0)) {
        return NO;
    }
    if (refs.count == 1) {
        NSString* firstRef = refs[0];
        if ([firstRef isEqualToString:@""]) {
            return NO;
        }
    }
    return YES;
}

- (void)referencesShow:(NSDictionary*)payload {
    if (!self.referencesHidden) {
        self.referencesVC.panelHeight = [self getRefsPanelHeight];
        self.referencesVC.payload     = payload;
        return;
    }

    // Don't show refs panel if reference data has yet to be retrieved. The
    // reference parsing javascript can't parse until the reference section html has
    // been retrieved. If user taps a reference link while the non-lead sections are
    // still being retrieved we need to just not show the panel rather than showing a
    // useless blank panel.
    if (![self didFindReferencesInPayload:payload]) {
        return;
    }

    self.referencesVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ReferencesVC"];

    self.referencesVC.webVC = self;
    [self addChildViewController:self.referencesVC];
    self.referencesVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.referencesContainerView addSubview:self.referencesVC.view];

    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                             options:0
                                             metrics:nil
                                               views:@{ @"view": self.referencesVC.view }]];
    [self.referencesContainerView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                             options:0
                                             metrics:nil
                                               views:@{ @"view": self.referencesVC.view }]];

    [self.referencesVC didMoveToParentViewController:self];

    [self.referencesContainerView layoutIfNeeded];

    self.referencesVC.panelHeight = [self getRefsPanelHeight];
    self.referencesVC.payload     = payload;

    [UIView animateWithDuration:0.16
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.referencesHidden = NO;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)referencesHide {
    if (self.referencesHidden) {
        return;
    }
    [UIView animateWithDuration:0.16
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.referencesHidden = YES;

        [self.view layoutIfNeeded];
    } completion:^(BOOL done) {
        [self.referencesVC willMoveToParentViewController:nil];
        [self.referencesVC.view removeFromSuperview];
        [self.referencesVC removeFromParentViewController];
        self.referencesVC = nil;
    }];
}

#pragma mark - Progress

- (WMFProgressLineView*)progressView {
    if (!_progressView) {
        WMFProgressLineView* progress = [[WMFProgressLineView alloc] initWithFrame:CGRectZero];
        _progressView = progress;
    }

    return _progressView;
}

- (void)showProgressViewAnimated:(BOOL)animated {
    self.progressView.progress = 0.0;

    if (!animated) {
        [self _showProgressView];
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self _showProgressView];
    } completion:^(BOOL finished) {
    }];
}

- (void)_showProgressView {
    self.progressView.alpha = 1.0;
    [ROOT.topMenuViewController.view addSubview:self.progressView];

    [self.progressView mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(ROOT.topMenuViewController.view.mas_bottom).with.offset(-2);
        make.left.equalTo(ROOT.topMenuViewController.view.mas_left);
        make.right.equalTo(ROOT.topMenuViewController.view.mas_right);
        make.height.equalTo(@2.0);
    }];
}

- (void)hideProgressViewAnimated:(BOOL)animated {
    if (!animated) {
        [self _hideProgressView];
        return;
    }

    [UIView animateWithDuration:0.25 animations:^{
        [self _hideProgressView];
    } completion:^(BOOL finished) {
    }];
}

- (void)_hideProgressView {
    self.progressView.alpha = 0.0;
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    [self.progressView setProgress:progress animated:animated];
}

- (CGFloat)totalProgressWithArticleFetcherProgress:(CGFloat)progress {
    return 0.75 * progress;
}

#pragma mark - Sharing

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(shareSnippet:)) {
        if ([self.selectedText isEqualToString:@""]) {
            return NO;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:WebViewControllerTextWasHighlighted
                                                            object:self
                                                          userInfo:nil];
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)shareSnippet:(id)sender {
    NSString* selectedText = [self selectedtext];

    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewControllerWillShareNotification
                                                        object:self
                                                      userInfo:@{ WebViewControllerShareSelectedText: selectedText }];
}

- (NSString*)selectedtext {
    NSString* selectedText =
        [[self.webView stringByEvaluatingJavaScriptFromString:kSelectedStringJS] wmf_shareSnippetFromText];
    return selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
}

#pragma mark - Tracking Footer

- (void)setupTrackingFooter {
    if (!self.footerContainer) {
        self.footerContainer = [[WMFWebViewFooterContainerView alloc] initWithHeight:kBottomScrollSpacerHeight];
        [self.webView wmf_addTrackingView:self.footerContainer
                               atLocation:WMFTrackingViewLocationBottom];

        self.footerViewController = [[WMFWebViewFooterViewController alloc] init];
        [self wmf_addChildController:self.footerViewController andConstrainToEdgesOfContainerView:self.footerContainer];
    }
}

@end
