#import "WMFSearchViewController.h"
#import <WMF/PiwikTracker+WMFExtensions.h>
#import <WMF/SessionSingleton.h>
#import <WMF/NSUserActivity+WMFExtensions.h>
#import <WMF/MWKLanguageLinkController.h>
#import <WMF/MWKLanguageLink.h>
@import Masonry;

#import "RecentSearchesViewController.h"
#import "WMFSearchResultsTableViewController.h"
#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"
#import "WMFSearchDataSource.h"
#import "Wikipedia-Swift.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "NSString+FormattedAttributedString.h"
#import "UIButton+WMFButton.h"
#import "UIFont+WMFStyle.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFEmptyView.h"

static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;

@interface WMFSearchViewController () <UISearchBarDelegate,
                                       WMFRecentSearchesViewControllerDelegate,
                                       UITextFieldDelegate,
                                       WMFArticleListTableViewControllerDelegate,
                                       WMFSearchLanguagesBarViewControllerDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) RecentSearchesViewController *recentSearchesViewController;
@property (nonatomic, strong) WMFSearchResultsTableViewController *resultsListController;
@property (nonatomic, strong) WMFSearchLanguagesBarViewController *searchLanguagesBarViewController;

@property (strong, nonatomic) IBOutlet UIView *searchFieldContainer;
@property (strong, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) IBOutlet UIView *searchContentContainer;
@property (strong, nonatomic) IBOutlet UIButton *searchSuggestionButton;
@property (strong, nonatomic) IBOutlet UIView *resultsListContainerView;
@property (strong, nonatomic) IBOutlet UIView *recentSearchesContainerView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic, strong) WMFSearchFetcher *fetcher;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *suggestionButtonHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchFieldTop;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewTop;

@property (nonatomic, assign, getter=isRecentSearchesHidden) BOOL recentSearchesHidden;

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated;

/**
 *  Set the text of the search field programatically.
 *
 *  Sets the text on the receiver's @c searchField and updates the vertical separator's visibility.  This is solely
 *  for cases when the user searches for something without typing it manually or clearing the search field.
 *
 *  @warning Use this instead of setting @c searchField.text directly.
 *
 *  @param text The string to show in the search field.
 */
- (void)setSearchFieldText:(NSString *)text;

@end

@implementation WMFSearchViewController

+ (instancetype)searchViewControllerWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    WMFSearchViewController *searchVC = [self wmf_initialViewControllerFromClassStoryboard];
    searchVC.dataStore = dataStore;
    searchVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    searchVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return searchVC;
}

#pragma mark - Accessors

- (NSString *)currentResultsSearchTerm {
    return [[self.resultsListController.dataSource searchResults] searchTerm];
}

- (NSURL *)currentResultsSearchSiteURL {
    return [self.resultsListController.dataSource searchSiteURL];
}

- (NSString *)searchSuggestion {
    return [[self.resultsListController.dataSource searchResults] searchSuggestion];
}

- (WMFSearchFetcher *)fetcher {
    if (!_fetcher) {
        _fetcher = [[WMFSearchFetcher alloc] init];
    }
    return _fetcher;
}

- (void)updateRecentSearchesVisibility {
    [self updateRecentSearchesVisibility:YES];
}

- (void)updateRecentSearchesVisibility:(BOOL)animated {
    BOOL hideRecentSearches =
        [self.searchField.text wmf_trim].length > 0 || [self.dataStore.recentSearchList countOfEntries] == 0;

    [self setRecentSearchesHidden:hideRecentSearches animated:animated];
}

- (void)setRecentSearchesHidden:(BOOL)showingRecentSearches {
    [self setRecentSearchesHidden:showingRecentSearches animated:NO];
}

- (void)setRecentSearchesHidden:(BOOL)hidingRecentSearches animated:(BOOL)animated {
    if (self.isRecentSearchesHidden == hidingRecentSearches) {
        return;
    }

    _recentSearchesHidden = hidingRecentSearches;

    [UIView animateWithDuration:animated ? [CATransaction animationDuration] : 0.0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.recentSearchesContainerView.alpha = self.isRecentSearchesHidden ? 0.0 : 1.0;
                         self.resultsListContainerView.alpha = 1.0 - self.recentSearchesContainerView.alpha;
                     }
                     completion:nil];
}

- (void)setSearchFieldText:(NSString *)text {
    self.searchField.text = text;
    [self setSeparatorViewHidden:text.length == 0 animated:YES];
}

#pragma mark - Setup

- (void)configureArticleList {
    self.resultsListController.userDataStore = self.dataStore;
    self.resultsListController.delegate = self;
}

- (void)configureRecentSearchList {
    self.recentSearchesViewController.recentSearches = self.dataStore.recentSearchList;
    self.recentSearchesViewController.delegate = self;
}

- (void)configureSearchField {
    self.searchField.textAlignment = NSTextAlignmentNatural;
    [self setSeparatorViewHidden:YES animated:NO];
    [self.searchField setPlaceholder:WMFLocalizedStringWithDefaultValue(@"search-field-placeholder-text", nil, nil, @"Search Wikipedia", @"Search field placeholder text")];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureSearchField];

    // move search field offscreen, preparing for transition in viewWillAppear
    self.searchFieldTop.constant = -self.searchFieldHeight.constant;

    self.title = WMFLocalizedStringWithDefaultValue(@"search-title", nil, nil, @"Search", @"Title for search interface.\n{{Identical|Search}}");
    self.resultsListController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.resultsListController.tableView.backgroundColor = [UIColor clearColor];

    self.closeButton.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"close-button-accessibility-label", nil, nil, @"Close", @"Accessibility label for a button that closes a dialog.\n{{Identical|Close}}");

    [self updateUIWithResults:nil];
    [self updateRecentSearchesVisibility:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.searchFieldTop.constant = 0;
    [self.view setNeedsUpdateConstraints];

    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self.view layoutIfNeeded];
        [self.searchField becomeFirstResponder];
    }
                                                completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[PiwikTracker sharedInstance] wmf_logView:self];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_searchViewActivity]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!self.presentedViewController) {
        /*
           Only perform animations & search site sync if search is being modally dismissed (as opposed to having another
           view presented on top of it.
         */
        [self saveLastSearch];

        self.searchFieldTop.constant = -self.searchFieldHeight.constant;

        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            [self.searchField resignFirstResponder];
            [self.view layoutIfNeeded];
        }
                                                    completion:nil];
    }
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    if (self.traitCollection.verticalSizeClass != newCollection.verticalSizeClass) {
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[WMFArticleListDataSourceTableViewController class]]) {
        self.resultsListController = segue.destinationViewController;
        [self configureArticleList];
    }
    if ([segue.destinationViewController isKindOfClass:[RecentSearchesViewController class]]) {
        self.recentSearchesViewController = segue.destinationViewController;
        [self configureRecentSearchList];
    }
    if ([segue.destinationViewController isKindOfClass:[WMFSearchLanguagesBarViewController class]]) {
        self.searchLanguagesBarViewController = (WMFSearchLanguagesBarViewController *)segue.destinationViewController;
        self.searchLanguagesBarViewController.delegate = self;

        // Allow size of contained VC's view to control container size: http://stackoverflow.com/a/34279613
        self.searchLanguagesBarViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
}

- (void)searchLanguagesBarViewController:(WMFSearchLanguagesBarViewController *)controller didChangeCurrentlySelectedSearchLanguage:(MWKLanguageLink *)language {
    [self searchForSearchTerm:self.searchField.text];
}

#pragma mark - Separator View

- (void)setSeparatorViewHidden:(BOOL)hidden animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.25 : 0.0
                     animations:^{
                         self.separatorView.alpha = hidden ? 0.0 : 1.0;
                     }];
}

#pragma mark - Dismissal

- (void)dismiss {
    [self.searchField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapCloseButton:(id)sender {
    [self dismiss];
}

- (BOOL)accessibilityPerformEscape {
    [self dismiss];
    return YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (![[self currentResultsSearchTerm] isEqualToString:textField.text]) {
        [self searchForSearchTerm:textField.text];
    }
}

- (IBAction)textFieldDidChange {
    NSString *query = self.searchField.text;

    dispatchOnMainQueueAfterDelayInSeconds(0.4, ^{
        DDLogDebug(@"Search field text changed to: %@", query);

        /**
         *  This check must performed before checking isEmpty and calling didCancelSearch
         *  This is to work around a "feature" of Siri which sets the textfield.text to nil
         *  when cancelling the Siri interface, and then immediately sets the text to its original value
         *
         *  The sequence of events is like so:
         *  Say "Mountain" to Siri
         *  "Mountain" is typed in the text field by Siri
         *  textFieldDidChange fires with textfield.text="Mountain"
         *  Tap a search result (which "cancels" the Siri UI)
         *  textFieldDidChange fires with textfield.text="" (This is the offending event!)
         *  textFieldDidChange fires with textfield.text="Mountain"
         *
         *  The event setting the textfield.text == nil causes many side effects which can cause crashes like:
         *  https://phabricator.wikimedia.org/T123241
         */
        if (![query isEqualToString:self.searchField.text]) {
            DDLogInfo(@"Aborting search for %@ since query has changed to %@", query, self.searchField.text);
            return;
        }

        BOOL isFieldEmpty = [query wmf_trim].length == 0;

        /**
         * This check is to avoid interpretting the "speech recognition in progress" blue spinner as 
         * actual text input. I could not find a clean way to detect this beyond subclassing the UITextField
         * which seemed more complex.
         * 
         * See:
         *   - https://phabricator.wikimedia.org/T156375
         *   - http://stackoverflow.com/questions/24041181/how-to-detect-that-speech-recogntion-is-in-progress
         */
        if ((query.length == 1) && ([query characterAtIndex:0] == NSAttachmentCharacter)) {
            return;
        }

        [self setSeparatorViewHidden:isFieldEmpty animated:YES];

        if (isFieldEmpty) {
            [self didCancelSearch];
            return;
        }

        [self setRecentSearchesHidden:YES animated:YES];

        DDLogDebug(@"Searching for %@ after delay.", query);
        [self searchForSearchTerm:query];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self saveLastSearch];
    [self updateRecentSearchesVisibility];
    [self.resultsListController wmf_hideEmptyView];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self didCancelSearch];
    return YES;
}

#pragma mark - Search

- (void)setSearchTerm:(NSString *)searchTerm {
    if (searchTerm.length == 0) {
        return;
    }
    [self setSearchFieldText:searchTerm];
    [self searchForSearchTerm:searchTerm];
}

- (NSURL *)currentlySelectedSearchURL {
    return self.searchLanguagesBarViewController.currentlySelectedSearchLanguage.siteURL;
}

- (void)didCancelSearch {
    [self setSearchFieldText:nil];
    [self updateSearchSuggestion:nil];
    self.resultsListController.dataSource = nil;
    [self updateRecentSearchesVisibility];
    [self.resultsListController wmf_hideEmptyView];
}

- (void)searchForSearchTerm:(NSString *)searchTerm {
    if ([searchTerm wmf_trim].length == 0) {
        DDLogDebug(@"Ignoring whitespace-only query.");
        return;
    }
    @weakify(self);

    WMFErrorHandler failure = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if ([searchTerm isEqualToString:self.searchField.text]) {
                [self.resultsListController wmf_showEmptyViewOfType:WMFEmptyViewTypeNoSearchResults];
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                DDLogError(@"Encountered search error: %@", error);
            }
        });
    };

    WMFSuccessIdHandler success = ^(WMFSearchResults *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if ([searchTerm isEqualToString:results.searchTerm]) {
                if (results.results.count == 0) {
                    dispatchOnMainQueueAfterDelayInSeconds(0.25, ^{
                        //Without the delay there is a weird animation due to the table also reloading simultaneously
                        [self.resultsListController wmf_showEmptyViewOfType:WMFEmptyViewTypeNoSearchResults];
                    });
                }
            }

            // change recent search visibility if no prefix results returned, and update suggestion if needed
            [UIView animateWithDuration:0.25
                             animations:^{
                                 [self updateUIWithResults:results];
                             }];
        });
    };

    [self.resultsListController wmf_hideEmptyView];
    NSURL *url = [self currentlySelectedSearchURL];

    if ([self.resultsListController isDisplayingResultsForSearchTerm:searchTerm fromSiteURL:url]) {
        DDLogDebug(@"Bailing out from running search for term because we're already showing results for this search term and search site.");
        return;
    }

    [self.fetcher fetchArticlesForSearchTerm:searchTerm
        siteURL:url
        resultLimit:WMFMaxSearchResultLimit
        failure:^(NSError *_Nonnull error) {

        }
        success:^(WMFSearchResults *_Nonnull results) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (![results.searchTerm isEqualToString:self.searchField.text]) {
                    failure([NSError wmf_cancelledError]);
                    return;
                }

                /*
             HAX: must set dataSource before starting the animation since dataSource is _unsafely_ assigned to the
             collection view, meaning there's a chance the collectionView accesses deallocated memory during an animation
             */
                WMFSearchDataSource *dataSource =
                    [[WMFSearchDataSource alloc] initWithSearchSiteURL:url
                                                         searchResults:results];

                self.resultsListController.dataSource = dataSource;

                [self updateUIWithResults:results];
                [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_searchResultsActivitySearchSiteURL:url searchTerm:results.searchTerm]];

                if ([results.results count] < kWMFMinResultsBeforeAutoFullTextSearch) {
                    [self.fetcher fetchArticlesForSearchTerm:searchTerm
                                                     siteURL:url
                                                 resultLimit:WMFMaxSearchResultLimit
                                              fullTextSearch:YES
                                     appendToPreviousResults:results
                                                     failure:failure
                                                     success:success];
                    return;
                }

                success(results);
            });
        }];
}

- (void)updateUIWithResults:(WMFSearchResults *)results {
    [self updateSearchSuggestion:results.searchSuggestion];
    [self updateRecentSearchesVisibility];
}

- (void)updateSearchSuggestion:(NSString *)searchSuggestion {
    NSAttributedString *title =
        [searchSuggestion length] ? [self getAttributedStringForSuggestion:searchSuggestion] : nil;
    [self.searchSuggestionButton setAttributedTitle:title forState:UIControlStateNormal];
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (CGFloat)searchFieldHeightForCurrentTraitCollection {
    return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 44 : 64;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];

    self.searchFieldHeight.constant = [self searchFieldHeightForCurrentTraitCollection];

    self.contentViewTop.constant = self.searchFieldHeight.constant;

    self.suggestionButtonHeightConstraint.constant =
        [self.searchSuggestionButton attributedTitleForState:UIControlStateNormal].length > 0 ? [self.searchSuggestionButton wmf_heightAccountingForMultiLineText] : 0;
}

- (NSAttributedString *)getAttributedStringForSuggestion:(NSString *)suggestion {
    return [WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters:\n* %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")
        attributedStringWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]}
                   substitutionStrings:@[suggestion]
                substitutionAttributes:@[@{NSFontAttributeName: [UIFont italicSystemFontOfSize:18]}]];
}

#pragma mark - RecentSearches

- (void)saveLastSearch {
    if ([self currentResultsSearchTerm]) {
        MWKRecentSearchEntry *entry = [[MWKRecentSearchEntry alloc] initWithURL:[self currentResultsSearchSiteURL]
                                                                     searchTerm:[self currentResultsSearchTerm]];
        [self.dataStore.recentSearchList addEntry:entry];
        [self.dataStore.recentSearchList save];
        [self.recentSearchesViewController reloadRecentSearches];
    }
}

#pragma mark - WMFRecentSearchesViewControllerDelegate

- (void)recentSearchController:(RecentSearchesViewController *)controller
           didSelectSearchTerm:(MWKRecentSearchEntry *)searchTerm {
    [self setSearchFieldText:searchTerm.searchTerm];
    [self searchForSearchTerm:searchTerm.searchTerm];
    [self updateRecentSearchesVisibility];
}

#pragma mark - Actions

- (IBAction)searchForSuggestion:(id)sender {
    [self setSearchFieldText:[self searchSuggestion]];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self updateSearchSuggestion:nil];
                     }];
    [self searchForSearchTerm:self.searchField.text];
}

#pragma mark - WMFArticleListTableViewControllerDelegate

- (void)listViewController:(WMFArticleListTableViewController *)listController didSelectArticleURL:(nonnull NSURL *)url {
    //log tap through done in table
    UIViewController *presenter = [self presentingViewController];
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [presenter wmf_pushArticleWithURL:url dataStore:self.dataStore animated:YES];
                             }];
}

- (UIViewController *)listViewController:(WMFArticleListTableViewController *)listController viewControllerForPreviewingArticleURL:(nonnull NSURL *)url {
    WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    return vc;
}

- (void)listViewController:(WMFArticleListTableViewController *)listController didCommitToPreviewedViewController:(UIViewController *)viewController {
    //log tap through done in table
    UIViewController *presenter = [self presentingViewController];
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 [presenter wmf_pushArticleViewController:(WMFArticleViewController *)viewController animated:YES];
                             }];
}

- (NSString *)analyticsContext {
    return @"Search";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}

@end
