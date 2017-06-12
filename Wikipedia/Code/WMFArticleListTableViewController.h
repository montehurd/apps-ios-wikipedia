#import "UIViewController+WMFEmptyView.h"
#import "WMFTableViewUpdater.h"
@class MWKDataStore;
@class WMFArticleListTableViewController;
@import WMF.Swift;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleListTableViewControllerDelegate <NSObject>

- (void)listViewController:(WMFArticleListTableViewController *)listController didSelectArticleURL:(NSURL *)url;

- (UIViewController *)listViewController:(WMFArticleListTableViewController *)listController viewControllerForPreviewingArticleURL:(NSURL *)url;

- (void)listViewController:(WMFArticleListTableViewController *)listController didCommitToPreviewedViewController:(UIViewController *)viewController;

@end

@interface WMFArticleListTableViewController : UITableViewController <WMFAnalyticsContextProviding, WMFAnalyticsContentTypeProviding, WMFTableViewUpdaterDelegate>

@property (nonatomic, strong) MWKDataStore *userDataStore;

/**
 *  Optional delegate which will is informed of selection.
 *
 *  If left @c nil, falls back to pushing an article container using its @c navigationController.
 */
@property (nonatomic, weak, nullable) id<WMFArticleListTableViewControllerDelegate> delegate;

@end

@interface WMFArticleListTableViewController (WMFSubclasses)

- (NSString *)analyticsContext;
- (NSString *)analyticsContentType;

- (WMFEmptyViewType)emptyViewType;

- (BOOL)showsDeleteAllButton;
- (NSString *)deleteButtonText;
- (NSString *)deleteAllConfirmationText;
- (NSString *)deleteText;
- (NSString *)deleteCancelText;

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteAll;

@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

- (NSURL *)urlAtIndexPath:(NSIndexPath *)indexPath;

- (void)updateEmptyAndDeleteState;

@end

NS_ASSUME_NONNULL_END
