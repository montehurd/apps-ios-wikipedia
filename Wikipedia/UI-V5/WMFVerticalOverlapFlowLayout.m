
#import "WMFVerticalOverlapFlowLayout.h"

@interface WMFVerticalOverlapFlowLayout ()

@property (assign, nonatomic) NSUInteger itemCount;
@property (assign) CGSize calculatedSize;

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

- (void)setOverlapSpacing:(CGFloat)closedStackSpacing {
    if (_overlapSpacing != closedStackSpacing) {
        _overlapSpacing = closedStackSpacing;
        [self invalidateLayout];
    }
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];

    NSUInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    self.itemCount = count;
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
    NSUInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];

    CGSize contentSize = [super collectionViewContentSize];

    NSArray* items = [super layoutAttributesForElementsInRect:CGRectMake(0, 0, contentSize.width, contentSize.height)];

    CGFloat yAdjustment = self.itemSize.height - self.overlapSpacing;

    [items enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes* item, NSUInteger idx, BOOL* stop) {
        [self updateAttributes:item yAdjustment:yAdjustment];

        if (idx == count - 1) {
            CGSize s = [super collectionViewContentSize];
            s.width = self.itemSize.width;
            s.height = CGRectGetMaxY(item.frame) + self.overlapSpacing;
            self.calculatedSize = s;
        }
    }];

    return items;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* item = [super layoutAttributesForItemAtIndexPath:indexPath];

    CGFloat yAdjustment = self.itemSize.height - self.overlapSpacing;

    [self updateAttributes:item yAdjustment:yAdjustment];

    return item;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* item = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];

    CGFloat yAdjustment = self.itemSize.height - self.overlapSpacing;

    [self updateAttributes:item yAdjustment:yAdjustment];

    return item;
}

#pragma mark - Update Attributes

- (void)updateAttributes:(UICollectionViewLayoutAttributes*)item yAdjustment:(float)yAdjustment {
    CGRect frame = item.frame;

    frame.origin.y -= (yAdjustment * (item.indexPath.row)); //add 1 to account for header
    item.zIndex     = item.indexPath.row;

    item.frame = frame;
}

@end
