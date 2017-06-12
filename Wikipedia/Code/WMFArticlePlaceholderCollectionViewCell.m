#import "WMFArticlePlaceholderCollectionViewCell.h"
#import "WMFTitleInsetRespectingButton.h"
#import "Wikipedia-Swift.h"

@implementation WMFArticlePlaceholderCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *stretch = [UIImage imageNamed:@"article-card-placeholder"];
    stretch = [stretch resizableImageWithCapInsets:UIEdgeInsetsMake(stretch.size.height / 2, stretch.size.width / 2 - 0.5, stretch.size.height / 2, stretch.size.width / 2 - 0.5)];
    self.placeholderImageView.image = stretch;
    self.placeholderImageView.contentMode = UIViewContentModeScaleToFill;
    [self.placeholderSaveButton setImage:[UIImage imageNamed:@"save-mini"] forState:UIControlStateNormal];
    [self.placeholderSaveButton setTitle:[WMFSaveButton saveTitle] forState:UIControlStateNormal];
    self.placeholderSaveButton.tintColor = [UIColor wmf_placeholderLightGray];
}

@end
