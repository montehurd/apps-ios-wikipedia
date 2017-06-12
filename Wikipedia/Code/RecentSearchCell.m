#import "RecentSearchCell.h"
@import WMF.UITableViewCell_WMFEdgeToEdgeSeparator;
#import "Wikipedia-Swift.h"

@implementation RecentSearchCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self wmf_makeCellDividerBeEdgeToEdge];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self wmf_configureSubviewsForDynamicType];
}

@end
