@import UIKit;
@import WMF.Swift;

@class WMFContentGroup;
@class MWKDataStore;
@class WMFFeedNewsStory;
@protocol WMFExploreCollectionViewControllerDelegate;

extern const NSInteger WMFExploreFeedMaximumNumberOfDays;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreCollectionViewController : UICollectionViewController <WMFAnalyticsViewNameProviding, WMFAnalyticsContextProviding>

@property (nonatomic, strong) MWKDataStore *userStore;

@property (nonatomic, weak) id<WMFExploreCollectionViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL canScrollToTop;

- (UIButton *)titleButton;

- (NSUInteger)numberOfSectionsInExploreFeed;

- (void)presentMoreViewControllerForGroup:(WMFContentGroup *)group animated:(BOOL)animated;

- (void)showInTheNewsForStories:(NSArray<WMFFeedNewsStory *> *)stories date:(nullable NSDate *)date animated:(BOOL)animated;

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated;

@end

@protocol WMFExploreCollectionViewControllerDelegate <NSObject>

@optional
- (void)exploreCollectionViewController:(WMFExploreCollectionViewController *)collectionVC didEndScrolling:(UIScrollView *)scrollView;

@optional
- (void)exploreCollectionViewController:(WMFExploreCollectionViewController *)collectionVC willBeginScrolling:(UIScrollView *)scrollView;

@optional
- (void)exploreCollectionViewController:(WMFExploreCollectionViewController *)collectionVC didScroll:(UIScrollView *)scrollView;

@optional
- (void)exploreCollectionViewController:(WMFExploreCollectionViewController *)collectionVC didScrollToTop:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
