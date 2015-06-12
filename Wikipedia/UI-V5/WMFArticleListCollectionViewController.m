
#import "WMFArticleListCollectionViewController.h"
#import "MWKUserDataStore.h"
#import "MWKSavedPageList.h"
#import "WMFVerticalOverlapFlowLayout.h"
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"
#import "WebViewController.h"

@interface WMFArticleListCollectionViewController ()<WMFVerticalOverlapFlowLayoutDelegate>

@property (nonatomic, assign, readwrite) WMFArticleListType listType;

@end

@implementation WMFArticleListCollectionViewController

#pragma mark - Accessors

- (MWKSavedPageList*)savedPages {
    return [self.userDataStore savedPageList];
}

- (WMFVerticalOverlapFlowLayout*)verticalOverlapLayout {
    return (WMFVerticalOverlapFlowLayout*)([self.collectionView.collectionViewLayout isKindOfClass:[WMFVerticalOverlapFlowLayout class]] ? self.collectionView.collectionViewLayout : nil);
}

#pragma mark - List Type

- (NSString*)titleForListType:(WMFArticleListType)type {
    //Do not make static so translations are always fresh
    return @{@(WMFArticleListTypeSaved): MWLocalizedString(@"saved-pages-title", nil)}[@(type)];
}

- (void)setListType:(WMFArticleListType)type animated:(BOOL)animated {
    if (self.listType == type) {
        return;
    }

    self.listType = type;
    [self.collectionView reloadData];
}

#pragma mark - Saved pages / Article Access

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPages entryAtIndex:indexPath.row];
    return [self.userDataStore.dataStore articleWithTitle:savedEntry.title];
}

- (void)deleteSavedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPages entryAtIndex:indexPath.row];
    if (savedEntry) {
        // Delete the saved record.
        [self.savedPages removeEntry:savedEntry];
        [self.userDataStore save];

        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title                            = [self titleForListType:self.listType];
    [self verticalOverlapLayout].delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self verticalOverlapLayout].itemSize = CGSizeMake(self.view.bounds.size.width, 200);

    WebViewController* vc = [[WebViewController alloc] init];

    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:^{
        [vc navigateToPage:[self articleForIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].title discoveryMethod:MWKHistoryDiscoveryMethodLink];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// iOS 7 Rotation Support
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self verticalOverlapLayout].itemSize = CGSizeMake(self.view.bounds.size.width, 200);
    }];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS 8+ Rotation Support
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context)
    {
        [self verticalOverlapLayout].itemSize = CGSizeMake(size.width, 200);
    }                            completion:NULL];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self savedPages] length];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WMFArticleViewControllerContainerCell class]) forIndexPath:indexPath];

    if (cell.viewController == nil) {
        [cell setViewControllerAndAddViewToContentView:[[WMFArticleViewController alloc] init]];
    }

    [self addChildViewController:cell.viewController];

    MWKArticle* article = [self articleForIndexPath:indexPath];
    cell.viewController.article = article;

    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController didMoveToParentViewController:self];
}

- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController willMoveToParentViewController:nil];
    [containerCell.viewController removeFromParentViewController];
}

#pragma mark - <WMFVerticalOverlapFlowLayoutDelegate>

- (BOOL)layout:(WMFVerticalOverlapFlowLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)layout:(WMFVerticalOverlapFlowLayout*)layout didDeleteItemAtIndexPath:(NSIndexPath*)indexPath {
    [self deleteSavedPageForIndexPath:indexPath];
}

@end
