#import "WMFWindowWithZeroBadge.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>

@interface WMFWindowWithZeroBadge()

@property (nonatomic, strong)UILabel* label;
@property (nonatomic) BOOL isBadgeVisible;

@end

@implementation WMFWindowWithZeroBadge

- (void)layoutSubviews {
    [super layoutSubviews];
    //HAX: Needed so transition animations don't go in from of the label.
    [self bringSubviewToFront:self.label];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UILabel alloc] init];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        self.label.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.8];
        self.label.textColor = [UIColor whiteColor];
        self.label.layer.cornerRadius = 12;
        self.label.font = [UIFont boldSystemFontOfSize:10];
        self.label.clipsToBounds = YES;
        self.label.hidden = YES;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.layer.borderWidth = 1.0;
        self.label.layer.borderColor = [UIColor blackColor].CGColor;
        self.isBadgeVisible = NO;
        
        [self addSubview:self.label];
        
        [self.label mas_makeConstraints:^(MASConstraintMaker* make) {
            make.height.and.width.equalTo(@(24));
            make.leading.equalTo(self.label.superview).with.offset(2.f);
            make.bottom.equalTo(self.label.superview).with.offset(-55.f);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showZeroBadge) name:WMFZeroBadgeShow object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideZeroBadge) name:WMFZeroBadgeHide object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleZeroBadge) name:WMFZeroBadgeToggle object:nil];
    }
    return self;
}

- (void)hideZeroBadge {
    self.label.text = @"";
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.isBadgeVisible = NO;
    self.label.hidden = YES;
}

- (void)showZeroBadge {
    self.label.text = @"W0";
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.isBadgeVisible = YES;
    self.label.hidden = NO;
}

- (void)toggleZeroBadge {
    if(self.isBadgeVisible){
        [self hideZeroBadge];
    }else{
        [self showZeroBadge];
    }
}

@end
