
#import <UIKit/UIKit.h>
#import "WMFArticleNavigationDelegate.h"
#import "WMFAnalyticsLogging.h"
#import "WMFArticleContentController.h"
#import "WMFArticleListItemController.h"

@class MWKDataStore;
@class MWKSavedPageList;
@class WMFArticleViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleViewControllerDelegate <WMFArticleNavigationDelegate>

- (void)articleViewController:(WMFArticleViewController*)articleViewController didTapSectionWithFragment:(NSString*)fragment;

@end

@interface WMFArticleViewController : UITableViewController
    <WMFArticleContentController, WMFArticleListItemController, WMFAnalyticsLogging>

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;

@property (nonatomic, weak) id<WMFArticleViewControllerDelegate> delegate;

- (void)updateUI;

/*
   Only exposed to allow save & read button to be selectable in popup.
 */
//@property (nonatomic, strong, readonly) UIButton* saveButton;

- (void)fetchArticle;

@end

NS_ASSUME_NONNULL_END
