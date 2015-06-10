
#import "WMFVerticalOverlapFlowLayout.h"
#import <BlocksKit/BlocksKit+UIKit.h>

@interface WMFVerticalOverlapFlowLayout ()<UIGestureRecognizerDelegate>

@property (assign, nonatomic) NSUInteger itemCount;
@property (assign) CGSize calculatedSize;

@property (nonatomic, strong) UIPanGestureRecognizer* deletePanGesture;
@property (nonatomic, strong) NSIndexPath* panningIndexPath;

@end


@implementation WMFVerticalOverlapFlowLayout

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.minimumLineSpacing      = 0.0f;
    self.minimumInteritemSpacing = 0.0f;
    self.scrollDirection         = UICollectionViewScrollDirectionVertical;
    self.overlapSpacing          = 65.0;
}

#pragma mark - Public

- (void)setOverlapSpacing:(CGFloat)overlapSpacing {
    if (_overlapSpacing != overlapSpacing) {
        _overlapSpacing = overlapSpacing;
        [self invalidateLayout];
    }
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    if(!self.deletePanGesture){
        
        self.deletePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithGesture:)];
        self.deletePanGesture.maximumNumberOfTouches = 1;
        self.deletePanGesture.delegate = self;
        [self.collectionView addGestureRecognizer:self.deletePanGesture];
        [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.deletePanGesture];
    }
    

    NSUInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    self.itemCount = count;
    
    CGSize s = [super collectionViewContentSize];
    s.width = self.itemSize.width;
    
    UICollectionViewLayoutAttributes* lastItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:count-1 inSection:0]];
    s.height = CGRectGetMaxY(lastItem.frame);
    self.calculatedSize = s;
}

- (void)invalidateLayout {
    [super invalidateLayout];

    NSUInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    self.itemCount = count;
}

- (CGSize)collectionViewContentSize {
    return self.calculatedSize;
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {

    CGSize contentSize = [super collectionViewContentSize];
    NSArray* items = [super layoutAttributesForElementsInRect:CGRectMake(0, 0, contentSize.width, contentSize.height)];

    [items enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes* item, NSUInteger idx, BOOL* stop) {
        [self updateAttributesWithOverlapSpacing:item];
        if([self.panningIndexPath isEqual:item.indexPath]){
            [self updateAttibutesWithPanTranslation:item];
        }
    }];

    return items;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    
    UICollectionViewLayoutAttributes* item = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self updateAttributesWithOverlapSpacing:item];
    if([self.panningIndexPath isEqual:indexPath]){
        [self updateAttibutesWithPanTranslation:item];
    }

    return item;
}


- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath{
    
    UICollectionViewLayoutAttributes* item = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    [self updateAttibutesForDeletion:item];
    return item;
}


#pragma mark - Update Attributes

- (void)updateAttributesWithOverlapSpacing:(UICollectionViewLayoutAttributes*)item {
    
    CGFloat yAdjustment = self.itemSize.height - self.overlapSpacing;

    CGRect frame = item.frame;
    frame.origin.y -= (yAdjustment * (item.indexPath.row));
    item.zIndex     = item.indexPath.row;
    item.frame = frame;
}

- (void)updateAttibutesWithPanTranslation:(UICollectionViewLayoutAttributes*)item{
    
    CGPoint translation = [self.deletePanGesture translationInView:self.collectionView];
    
    CGRect frame = item.frame;
    frame.origin.x += translation.x;
    item.frame = frame;
}

- (void)updateAttibutesForDeletion:(UICollectionViewLayoutAttributes*)item{
    
    CGRect frame = item.frame;
    frame.origin.x += self.collectionView.bounds.size.width*2;
    item.frame = frame;
}


#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    if(![gestureRecognizer isEqual:self.deletePanGesture]){
        return YES;
    }
    
    CGPoint attachmentPoint = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath* touchedIndexPath = [self.collectionView indexPathForItemAtPoint:attachmentPoint];
    
    if(!touchedIndexPath){
        return NO;
    }
    
    if(![self.delegate layout:self canDeleteItemAtIndexPath:touchedIndexPath]){
        return NO;
    }
    
    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self.collectionView];
    if(velocity.y > 0 || velocity.y < 0){
        return NO;
    }
    
    return YES;
}

- (void)didPanWithGesture:(UIPanGestureRecognizer*)pan{
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            
            CGPoint attachmentPoint = [pan locationInView:self.collectionView];

            NSIndexPath* touchedIndexPath = [self.collectionView indexPathForItemAtPoint:attachmentPoint];
            if(!touchedIndexPath){
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }
            
            UICollectionViewLayoutAttributes* attributes = [self layoutAttributesForItemAtIndexPath:touchedIndexPath];
            
            if(!attributes){
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }
            
            self.panningIndexPath = touchedIndexPath;
            [self invalidateLayout];
            
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            [self invalidateLayout];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            
            CGPoint translation = [pan translationInView:self.collectionView];
            CGFloat originalX = [super layoutAttributesForItemAtIndexPath:self.panningIndexPath].frame.origin.x;
            
            if(translation.x >= (originalX + self.collectionView.bounds.size.width/2)){
                [self completeDeletionPanAnimation];
                return;
            }
            
            CGPoint velocity = [pan velocityInView:self.collectionView];
            if(velocity.x > 500){
                [self completeDeletionPanAnimation];
                return;
            }
            
            [self cancelDeletionPanAnimation];
            
        }
            break;
            
        default:
            break;
    }
}

- (void)cancelTouchesInGestureRecognizer:(UIGestureRecognizer*)gesture{
    gesture.enabled = NO;
    gesture.enabled = YES;
}

- (void)completeDeletionPanAnimation{

    NSIndexPath* indexpath = self.panningIndexPath;
    self.panningIndexPath = nil;
    [self.delegate layout:self didDeleteItemAtIndexPath:indexpath];
}

- (void)cancelDeletionPanAnimation{
    
    self.panningIndexPath = nil;
    
    [self.collectionView performBatchUpdates:^{
        
        [self invalidateLayout];

    } completion:nil];
}







@end
