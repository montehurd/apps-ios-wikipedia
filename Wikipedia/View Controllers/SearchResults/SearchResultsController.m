
#import "SearchResultsController.h"
#import "WikipediaAppUtils.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "SearchResultCell.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import "UIViewController+HideKeyboard.h"
#import "CenterNavController.h"
#import "SearchResultFetcher.h"
#import "ThumbnailFetcher.h"
#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "TopMenuTextFieldContainer.h"
#import "TopMenuTextField.h"
#import "SearchDidYouMeanButton.h"
#import "SearchMessageLabel.h"
#import "RecentSearchesViewController.h"
#import "NSArray+Predicate.h"
#import "SearchResultAttributedString.h"
#import "UITableView+DynamicCellHeight.h"
#import "NSArray+WMFExtensions.h"
#import <BlocksKit/BlocksKit.h>
#import "WMFIntrinsicContentSizeAwareTableView.h"
#import "UIScrollView+WMFScrollsToTop.h"
#import "WMFSearchFunnel.h"

static NSString* const kWMFSearchCellID     = @"SearchResultCell";
static CGFloat const kWMFSearchDelay        = 0.4;
static NSUInteger const kWMFMaxStringLength = 100;
static CGFloat const kWMFDefaultCellHeight  = 80.0;

typedef NS_ENUM (NSUInteger, WMFSearchResultsControllerType) {
    WMFSearchResultsControllerTypeStandard,
    WMFSearchResultsControllerTypeReadMore
};


static NSUInteger const kWMFMinResultsBeforeAutoFullTextSearch = 12;
static NSUInteger const kWMFReadMoreNumberOfArticles           = 3;

@interface SearchResultsController ()<FetchFinishedDelegate>{
    CGFloat scrollViewDragBeganVerticalOffset_;
}

@property (nonatomic, assign) WMFSearchResultsControllerType type;

@property (nonatomic, assign) NSUInteger maxResults;
@property (nonatomic, assign) NSUInteger minResultsBeforeRunningFullTextSearch;

@property (nonatomic, assign) BOOL highlightSearchTermInResultTitles;

@property (nonatomic, strong) NSString* searchSuggestion;

@property (nonatomic, strong) NSArray* searchStringWordsToHighlight;

@property (nonatomic, strong) NSTimer* delayedSearchTimer;

@property (nonatomic) BOOL ignoreScrollEvents;

@property (nonatomic, strong, readwrite) IBOutlet WMFIntrinsicContentSizeAwareTableView* searchResultsTable;

@property (nonatomic, strong) UIImage* placeholderImage;
@property (nonatomic, strong) NSString* cachePath;

@property (nonatomic, weak) IBOutlet SearchDidYouMeanButton* didYouMeanButton;
@property (nonatomic, weak) IBOutlet SearchMessageLabel* searchMessageLabel;

@property (nonatomic, strong) RecentSearchesViewController* recentSearchesViewController;

@property (nonatomic, weak) IBOutlet UIView* recentSearchesContainer;

@property (nonatomic, strong) SearchResultCell* offScreenSizingCell;

@property (nonatomic, strong) NSDate* searchStartTime;

@end

@implementation SearchResultsController

+ (SearchResultsController*)initialViewControllerFromStoryBoard {
    return [[UIStoryboard storyboardWithName:@"WMFSearchResults" bundle:nil] instantiateInitialViewController];
}

+ (SearchResultsController*)standardSearchResultsController {
    SearchResultsController* vc = [SearchResultsController initialViewControllerFromStoryBoard];
    vc.type                                  = WMFSearchResultsControllerTypeStandard;
    vc.maxResults                            = SEARCH_MAX_RESULTS;
    vc.minResultsBeforeRunningFullTextSearch = kWMFMinResultsBeforeAutoFullTextSearch;
    vc.highlightSearchTermInResultTitles     = YES;
    return vc;
}

+ (SearchResultsController*)readMoreSearchResultsController {
    SearchResultsController* vc = [SearchResultsController standardSearchResultsController];
    vc.type                                  = WMFSearchResultsControllerTypeReadMore;
    vc.maxResults                            = kWMFReadMoreNumberOfArticles;
    vc.minResultsBeforeRunningFullTextSearch = kWMFReadMoreNumberOfArticles;
    vc.highlightSearchTermInResultTitles     = NO;
    return vc;
}

- (void)setSearchString:(NSString*)searchString {
    _searchString = searchString;

    [self updateRecentSearchesContainerVisibility];
}

- (NSUInteger)maxResultsAdjustedForExcludedArticles {
    if (self.maxResults > 0) {
        //We are triming any excluded articles, so we need to fetch more articles to compensate
        return self.maxResults + [self.articlesToExcludeFromResults count];
    }

    return self.maxResults;
}

- (void)updateRecentSearchesContainerVisibility {
    BOOL shouldHide = (
        (self.searchString.length == 0)
        &&
        (self.recentSearchesViewController.recentSearchesItemCount.integerValue > 0)
        ) ? NO : YES;

    if (self.recentSearchesContainer.hidden == shouldHide) {
        return;
    }

    [UIView transitionWithView:self.recentSearchesContainer
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];

    self.recentSearchesContainer.hidden = shouldHide;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"RecentSearchesViewController_embed"]) {
        self.recentSearchesViewController = (RecentSearchesViewController*)[segue destinationViewController];
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.ignoreScrollEvents = NO;
    self.searchString       = @"";

    self.placeholderImage = [UIImage imageNamed:@"logo-placeholder-search.png"];

    // NSCachesDirectory can be used as temp storage. iOS will clear this directory if it needs to so
    // don't store anything critical there. Works well here for quick access to thumbs as user scrolls
    // table view.
    NSArray* cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cachePath = [cachePaths objectAtIndex:0];

    self.searchStringWordsToHighlight = @[];

    scrollViewDragBeganVerticalOffset_ = 0.0f;

    self.searchResults                  = @[];
    self.searchSuggestion               = nil;
    self.navigationItem.hidesBackButton = YES;

    // Register the search results cell for reuse
    [self.searchResultsTable registerNib:[UINib nibWithNibName:@"SearchResultPrototypeView" bundle:nil] forCellReuseIdentifier:kWMFSearchCellID];

    // Turn off the separator since one gets added in SearchResultCell.m
    self.searchResultsTable.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.didYouMeanButton.userInteractionEnabled = YES;
    [self.didYouMeanButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didYouMeanButtonPushed)]];

    [self.recentSearchesViewController addObserver:self
                                        forKeyPath:@"recentSearchesItemCount"
                                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                           context:nil];

    // Single off-screen cell for determining dynamic cell height.
    self.offScreenSizingCell = (SearchResultCell*)[self.searchResultsTable dequeueReusableCellWithIdentifier:kWMFSearchCellID];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self isReadMore]) {
        self.searchResultsTable.scrollEnabled = NO;
        [self.searchResultsTable wmf_shouldScrollToTopOnStatusBarTap:NO];
    } else {
        [self.searchResultsTable wmf_shouldScrollToTopOnStatusBarTap:YES];
    }
}

- (void)dealloc {
    [self.recentSearchesViewController removeObserver:self forKeyPath:@"recentSearchesItemCount"];
}

- (void)didYouMeanButtonPushed {
    [self.didYouMeanButton hide];
    TopMenuTextFieldContainer* textFieldContainer = [ROOT.topMenuViewController getNavBarItem:NAVBAR_TEXT_FIELD];
    textFieldContainer.textField.text = self.searchSuggestion;
    self.searchString                 = self.searchSuggestion;
    [self searchAfterDelay:@0.0f reason:SEARCH_REASON_DID_YOU_MEAN_TAPPED];
    [self.searchFunnel logSearchDidYouMean];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if ((object == self.recentSearchesViewController) && [keyPath isEqualToString:@"recentSearchesItemCount"]) {
        [self updateRecentSearchesContainerVisibility];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self cancelDelayedSearch];

    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Important to only auto-search when the view appears if-and-only-if it isn't already showing results!
    if ((self.searchString.length > 0) && (self.searchResults.count == 0)) {
        [self searchAfterDelay:@0.05f reason:SEARCH_REASON_VIEW_APPEARED];
    }
}

- (void)setSearchStartTime {
    self.searchStartTime = [NSDate new];
}

- (NSTimeInterval)searchTime {
    return [[NSDate new] timeIntervalSinceDate:self.searchStartTime];
}

- (void)cancelDelayedSearch {
    if (self.delayedSearchTimer) {
        [self.delayedSearchTimer invalidate];
        self.delayedSearchTimer = nil;
    }
}

- (void)search {
    if (self.searchString.length == 0) {
        [self clearSearchResults];
    } else {
        [self setSearchStartTime];
        [self searchAfterDelay:@(kWMFSearchDelay) reason:SEARCH_REASON_SEARCH_STRING_CHANGED];
    }
}

- (void)searchAfterDelay:(NSNumber*)delay reason:(SearchReason)reason {
    [self cancelDelayedSearch];

    self.delayedSearchTimer = [NSTimer scheduledTimerWithTimeInterval:delay.floatValue
                                                               target:self
                                                             selector:@selector(performSearch:)
                                                             userInfo:@{@"reason": @(reason)}
                                                              repeats:NO];
}

- (void)performSearch:(NSTimer*)timer {
    // Reminder: do not call "performSearch:" directly - only "searchAfterDelay:reason:" should do so.
    // To search call "searchAfterDelay:reason:" - this is because it ensures delayed searches get cancelled.

    SearchReason reason = ((NSNumber*)timer.userInfo[@"reason"]).integerValue;

//    if (self.navigationController.topViewController != self) return;

    if (self.searchString.length == 0) {
        return;
    }

    [self updateWordsToHighlight];

    [self searchForTerm:self.searchString reason:reason];
}

- (void)updateWordsToHighlight {
    // Call this only when searchString is updated. Keeps the list of words to highlight up to date.
    // Get the words by splitting searchString on a combination of whitespace and punctuation
    // character sets so search term words get highlighted even if the puncuation in the result is slightly
    // different from the punctuation in the retrieved search result title.
    NSMutableCharacterSet* charSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [charSet formUnionWithCharacterSet:[NSMutableCharacterSet punctuationCharacterSet]];

    if (self.highlightSearchTermInResultTitles) {
        self.searchStringWordsToHighlight = [self.searchString componentsSeparatedByCharactersInSet:charSet];
    } else {
        self.searchStringWordsToHighlight = @[];
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (self.ignoreScrollEvents) {
        return;
    }

    // Hide the keyboard if it was visible when the results are scrolled, but only if
    // the results have been scrolled in excess of some small distance threshold first.
    // This prevents tiny scroll adjustments, which seem to occur occasionally for some
    // reason, from causing the keyboard to hide when the user is typing on it!
    CGFloat distanceScrolled = fabs(scrollViewDragBeganVerticalOffset_ - scrollView.contentOffset.y);

    if (distanceScrolled > HIDE_KEYBOARD_ON_SCROLL_THRESHOLD) {
        [self hideKeyboard];
    }
}

#pragma mark Search term methods (requests titles matching search term and associated thumbnail urls)

- (void)clearSearchResults {
    [self.searchMessageLabel hide];
    [self.didYouMeanButton hide];
    self.searchResults    = @[];
    self.searchSuggestion = nil;
    [self.searchResultsTable reloadData];

    [[QueuesSingleton sharedInstance].articleFetchManager.operationQueue cancelAllOperations];

    // Cancel any in-progress searches.
    [[QueuesSingleton sharedInstance].searchResultsFetchManager.operationQueue cancelAllOperations];
}

- (void)reduceToOnlyResultsFromSearchTerm:(NSString*)searchTerm {
    NSPredicate* predicate =
        [NSPredicate predicateWithFormat:@"searchterm ==[c] %@", searchTerm];
    self.searchResults = [self.searchResults filteredArrayUsingPredicate:predicate];

    [self.searchResultsTable reloadData];
}

- (void)updateAttributeTextForSearchType:(SearchType)searchType {
    for (NSMutableDictionary* result in self.searchResults) {
        //TODO: change name of "SearchResultAttributedString" to "SearchResultStringStyler" or something... it's an NSObject!
        NSNumber* typeAsNumber                         = result[@"searchtype"];
        SearchResultAttributedString* attributedResult =
            [SearchResultAttributedString initWithTitle:result[@"title"]
                                                snippet:result[@"snippet"]
                                    wikiDataDescription:result[@"description"]
                                         highlightWords:self.searchStringWordsToHighlight
                                   shouldHighlightWords:![self isReadMore]
                                             searchType:typeAsNumber.integerValue];

        result[@"attributedText"] = attributedResult;
    }
}

- (NSArray*)removePrefixResultsFromSupplementalResults:(NSArray*)supplementalResults {
    // Remove items from supplementalResults which are already
    // present in self.searchResults so we don't see dupes.
    NSMutableArray* supplementalFullTextResults = supplementalResults.mutableCopy;
    for (NSDictionary* prefixResult in self.searchResults) {
        NSNumber* prefixResultId = prefixResult[@"pageid"];
        NSUInteger dupeIndex     = [supplementalFullTextResults indexOfObjectPassingTest:^BOOL (NSDictionary* obj, NSUInteger idx, BOOL* stop) {
            NSNumber* fullTextResultId = obj[@"pageid"];
            if ([fullTextResultId isEqual:prefixResultId]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];

        if (dupeIndex != NSNotFound) {
            [supplementalFullTextResults removeObjectAtIndex:dupeIndex];
        }
    }
    return supplementalFullTextResults;
}

- (NSArray*)removeExcludedArticlesFromSearchResults:(NSArray*)searchResults {
    NSMutableArray* mutableResults = [searchResults mutableCopy];

    [self.articlesToExcludeFromResults enumerateObjectsUsingBlock:^(MWKArticle* article, NSUInteger idx, BOOL* stop) {
        NSDictionary* match = [searchResults bk_match:^BOOL (NSDictionary* result) {
            if ([article.title.text localizedCaseInsensitiveCompare:result[@"title"]] == NSOrderedSame) {
                return YES;
            }
            return NO;
        }];

        if (match) {
            [mutableResults removeObject:match];
        }
    }];

    return mutableResults;
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error;
{
    if ([sender isKindOfClass:[SearchResultFetcher class]]) {
        SearchResultFetcher* searchResultFetcher = (SearchResultFetcher*)sender;

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                [self fadeAlert];
                [self.searchMessageLabel hide];

                NSArray* searchResults = [self removeExcludedArticlesFromSearchResults:searchResultFetcher.searchResults];

                if (searchResultFetcher.searchReason == SEARCH_REASON_SUPPLEMENT_PREFIX_WITH_FULL_TEXT) {
                    // Supplement the prefix results with these full text results, but first remove
                    // items from fullTextSearchResults which are already present in self.searchResults
                    // so we don't see dupes.
                    NSArray* supplementalFullTextResults =
                        [self removePrefixResultsFromSupplementalResults:searchResults];

                    self.searchResults =
                        [[self.searchResults arrayByAddingObjectsFromArray:supplementalFullTextResults] wmf_arrayByTrimmingToLength:self.maxResults];
                    [self.searchFunnel logSearchResultsWithTypeOfSearch:WMFSearchTypeFull resultCount:[self.searchResults count] elapsedTime:[self searchTime]];
                } else {
                    self.searchResults = [searchResults wmf_arrayByTrimmingToLength:self.maxResults];
                    [self.searchFunnel logSearchResultsWithTypeOfSearch:WMFSearchTypePrefix resultCount:[self.searchResults count] elapsedTime:[self searchTime]];
                }
                //NSLog(@"self.searchResultsOrdered = %@", self.searchResultsOrdered);

                [self updateAttributeTextForSearchType:searchResultFetcher.searchType];

                // We have search titles! Show them right away!
                // NSLog(@"FIRE ONE! Show search result titles.");
                [self.searchResultsTable reloadData];

                // If we received fewer than MIN_RESULTS_BEFORE_AUTO_FULL_TEXT_SEARCH prefix results,
                // do a full-text search too, the results of which will be appended to the prefix results.
                // Note: this also has to be done in the FETCH_FINAL_STATUS_FAILED case below.
                if ((self.searchResults.count < self.minResultsBeforeRunningFullTextSearch) && (searchResultFetcher.searchType == SEARCH_TYPE_TITLES)) {
                    [self.searchFunnel logSearchAutoSwitch];
                    [self performSupplementalFullTextSearchForTerm:searchResultFetcher.searchTerm];
                }
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                [self fadeAlert];
                break;
            case FETCH_FINAL_STATUS_FAILED:

                if (error.code == SEARCH_RESULT_ERROR_NO_MATCHES) {
                    // We don't want the supplemental full text results blasting prefix results,
                    // but we do need to reduce to only show items for current search string.
                    // Needed because we don't blank out search results as a user types.
                    // (Previously we cleared search results here, but now that supplemental
                    // full text results can arrive after the prefix results have been presented
                    // this became necessary.)
                    [self reduceToOnlyResultsFromSearchTerm:self.searchString];

                    if (searchResultFetcher.searchType == SEARCH_TYPE_TITLES) {
                        [self performSupplementalFullTextSearchForTerm:searchResultFetcher.searchTerm];
                    } else {
                        // Don't show the no-results found message if there were any prefix results.
                        if (self.searchResults.count == 0) {
                            [self.searchMessageLabel showWithText:error.localizedDescription];
                        }
                    }
                } else {
                    [self.searchMessageLabel showWithText:error.localizedDescription];
                }

                if (searchResultFetcher.searchReason == SEARCH_REASON_SUPPLEMENT_PREFIX_WITH_FULL_TEXT) {
                    [self.searchFunnel logShowSearchErrorWithTypeOfSearch:WMFSearchTypeFull elapsedTime:[[NSDate new] timeIntervalSinceDate:self.searchStartTime]];
                } else {
                    [self.searchFunnel logShowSearchErrorWithTypeOfSearch:WMFSearchTypePrefix elapsedTime:[[NSDate new] timeIntervalSinceDate:self.searchStartTime]];
                }

                break;
        }

        // Show search suggestion if necessary.
        // Search suggestion can be returned if zero or more search results found.
        // That's why this is here in not in the "SUCCEEDED" case above.
        // We only want the suggestion from the initial TITLE search.
        if (searchResultFetcher.searchType == SEARCH_TYPE_TITLES) {
            self.searchSuggestion = [searchResultFetcher.searchSuggestion copy];
        }
        if (self.searchSuggestion) {
            [self.didYouMeanButton showWithText:([self isReadMore]) ? MWCurrentArticleLanguageLocalizedString(@"search-did-you-mean", nil) : MWLocalizedString(@"search-did-you-mean", nil)
                                           term:self.searchSuggestion];
        }
    } else if ([sender isKindOfClass:[ThumbnailFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                NSString* fileName = [[sender url] lastPathComponent];

                // See if cache file found, show it instead of downloading if found.
                NSString* cacheFilePath = [self.cachePath stringByAppendingPathComponent:fileName];

                // Save cache file.
                [fetchedData writeToFile:cacheFilePath atomically:YES];

                // Then see if cell for this image name is still onscreen and set its image if so.
                UIImage* image = [UIImage imageWithData:fetchedData];

                // Check if cell still onscreen! This is important!
                NSArray* visibleRowIndexPaths = [self.searchResultsTable indexPathsForVisibleRows];
                for (NSIndexPath* thisIndexPath in visibleRowIndexPaths.copy) {
                    NSDictionary* rowData = [self searchResultForIndexPath:thisIndexPath];
                    NSString* url         = rowData[@"thumbnail"][@"source"];
                    if ([url.lastPathComponent isEqualToString:fileName]) {
                        SearchResultCell* cell = (SearchResultCell*)[self.searchResultsTable cellForRowAtIndexPath:thisIndexPath];
                        cell.resultImageView.image = image;
                        [cell setNeedsDisplay];
                        break;
                    }
                }
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
                break;
            case FETCH_FINAL_STATUS_FAILED:
                break;
        }
    }
}

- (void)scrollTableToTop {
    if ([self.searchResultsTable numberOfRowsInSection:0] > 0) {
        // Ignore scroll event so keyboard doesn't disappear.
        self.ignoreScrollEvents = YES;
        [UIView animateWithDuration:0.15f animations:^{
            [self.searchResultsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                           atScrollPosition:UITableViewScrollPositionTop
                                                   animated:NO];
        } completion:^(BOOL done){
            self.ignoreScrollEvents = NO;
        }];
    }
}

- (BOOL)isReadMore {
    return (self.type == WMFSearchResultsControllerTypeReadMore);
}

- (NSString*)getSearchLanguage {
    if ([self isReadMore]) {
        return [SessionSingleton sharedInstance].currentArticleSite.language;
    } else {
        return [SessionSingleton sharedInstance].searchLanguage;
    }
}

- (void)performSupplementalFullTextSearchForTerm:(NSString*)searchTerm {
    (void)[[SearchResultFetcher alloc] initAndSearchForTerm:searchTerm
                                                 searchType:SEARCH_TYPE_IN_ARTICLES
                                               searchReason:SEARCH_REASON_SUPPLEMENT_PREFIX_WITH_FULL_TEXT
                                                   language:[self getSearchLanguage]
                                                 maxResults:[self maxResultsAdjustedForExcludedArticles]
                                                withManager:[QueuesSingleton sharedInstance].searchResultsFetchManager
                                         thenNotifyDelegate:self];
}

- (void)searchForTerm:(NSString*)searchTerm reason:(SearchReason)reason {
    // Reminder: do not call "searchForTerm:reason:" directly - only "performSearch:" should do so.
    // To search call "searchAfterDelay:reason:" - this is because it ensures delayed searches get cancelled.

    [self scrollTableToTop];

    [self.didYouMeanButton hide];

    (void)[[SearchResultFetcher alloc] initAndSearchForTerm:searchTerm
                                                 searchType:SEARCH_TYPE_TITLES
                                               searchReason:reason
                                                   language:[self getSearchLanguage]
                                                 maxResults:[self maxResultsAdjustedForExcludedArticles]
                                                withManager:[QueuesSingleton sharedInstance].searchResultsFetchManager
                                         thenNotifyDelegate:self];
}

#pragma mark Search results table methods (requests actual thumb image data)

- (NSDictionary*)searchResultForIndex:(NSUInteger)index {
    if (index >= [self.searchResults count]) {
        return nil;
    }

    return self.searchResults[index];
}

- (NSDictionary*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    return [self searchResultForIndex:indexPath.row];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary* result = [self searchResultForIndexPath:indexPath];

    //Optimization to prevent calculation to get cell size
    if ([result[@"attributedText"] length] < kWMFMaxStringLength) {
        return floor(kWMFDefaultCellHeight * MENUS_SCALE_MULTIPLIER);
    }

    self.offScreenSizingCell.resultLabel.attributedText = result[@"attributedText"];

    return [tableView heightForSizingCell:self.offScreenSizingCell];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    SearchResultCell* cell = (SearchResultCell*)[tableView dequeueReusableCellWithIdentifier:kWMFSearchCellID];

    NSDictionary* result = [self searchResultForIndexPath:indexPath];

    cell.resultLabel.attributedText = result[@"attributedText"];
    cell.resultImageView.image      = self.placeholderImage;

    NSString* thumbURL = result[@"thumbnail"][@"source"];
    if (thumbURL) {
        __block NSString* fileName = [thumbURL lastPathComponent];

        // See if cache file found, show it instead of downloading if found.
        NSString* cacheFilePath = [self.cachePath stringByAppendingPathComponent:fileName];
        BOOL isDirectory        = NO;
        BOOL fileExists         = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath isDirectory:&isDirectory];
        if (fileExists) {
            cell.resultImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:cacheFilePath]];
        } else {
            // No thumb found so fetch it.
            (void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL:thumbURL
                                                             withManager:[QueuesSingleton sharedInstance].searchResultsFetchManager
                                                      thenNotifyDelegate:self];
        }
    }

    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self hideKeyboard];

    NSDictionary* result = [self searchResultForIndexPath:indexPath];

    NSString* title = result[@"title"];

    [self loadArticleWithTitle:title];
    [self.searchFunnel logSearchResultTap];
}

- (void)loadArticleWithTitle:(NSString*)title {
    if ([title length] == 0) {
        return;
    }

    [self saveSearchTermToRecentList];

    // Set CurrentArticleTitle so web view knows what to load.
    title = [title wmf_stringByReplacingUndrescoresWithSpaces];

    [NAV loadArticleWithTitle:[[SessionSingleton sharedInstance].searchSite titleWithString:title]
                     animated:YES
              discoveryMethod:MWKHistoryDiscoveryMethodSearch
                   popToWebVC:YES];
}

- (void)doneTapped {
    if (self.searchResults.count == 0) {
        return;
    }

    // If there is an exact match in the search results for the current search term,
    // load that article.
    if ([self perfectSearchStringTitleMatchFoundInSearchResults]) {
        [self loadArticleWithTitle:self.searchString];
    } else {
        // Else load title of first result.
        NSDictionary* firstItem = self.searchResults.firstObject;
        if (firstItem[@"title"]) {
            [self loadArticleWithTitle:firstItem[@"title"]];
        }
    }
}

- (void)saveSearchTermToRecentList {
    [self.recentSearchesViewController saveTerm:self.searchString
                                      forDomain:[SessionSingleton sharedInstance].searchSite.language
                                           type:SEARCH_TYPE_TITLES];
}

- (BOOL)perfectSearchStringTitleMatchFoundInSearchResults {
    if (self.searchResults.count == 0) {
        return NO;
    }
    id perfectMatch =
        [self.searchResults firstMatchForPredicate:[NSPredicate predicateWithFormat:@"(title == %@)", self.searchString]];

    BOOL perfectMatchFound = perfectMatch ? YES : NO;
    return perfectMatchFound;
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
