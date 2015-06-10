
@import UIKit;

@protocol WMFVerticalOverlapFlowLayoutDelegate;

@interface WMFVerticalOverlapFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGFloat overlapSpacing;

@property (nonatomic, weak) id<WMFVerticalOverlapFlowLayoutDelegate> delegate;

@end


@protocol WMFVerticalOverlapFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>

- (BOOL)layout:(WMFVerticalOverlapFlowLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath;
- (void)layout:(WMFVerticalOverlapFlowLayout*)layout didDeleteItemAtIndexPath:(NSIndexPath*)indexPath;

@end


