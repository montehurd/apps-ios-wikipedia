//  Created by Monte Hurd on 3/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFFadedLoadingIndicator.h"
#import "UIColor+WMFHexColor.h"
#import <Masonry/Masonry.h>

static const CGFloat kFadeDuration                       = 0.5f;
static const CGFloat kActivityIndicatorWidth             = 100.0f;
static const CGFloat kActivityIndicatorCornerRadius      = 10.0f;
static const CGFloat kActivityIndicatorBackgroundAlpha   = 1.0;
static const NSInteger kActivityIndicatorBackgroundColor = 0x000000;

@interface WMFFadedLoadingIndicator ()
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic) BOOL isTransparent;
@end

@implementation WMFFadedLoadingIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.alpha                  = 0.0;
        self.isTransparent          = YES;
        [self addSubview:self.activityIndicator];
        [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker* make) {
            make.center.equalTo(self.activityIndicator.superview);
            make.size.mas_equalTo(CGSizeMake(kActivityIndicatorWidth, kActivityIndicatorWidth));
        }];
    }
    return self;
}

- (UIActivityIndicatorView*)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.color              = [UIColor whiteColor];
        self.activityIndicator.alpha              = 0.0;
        self.activityIndicator.backgroundColor    = [UIColor wmf_colorWithHex:kActivityIndicatorBackgroundColor alpha:kActivityIndicatorBackgroundAlpha];
        self.activityIndicator.layer.cornerRadius = kActivityIndicatorCornerRadius;
    }
    return _activityIndicator;
}

- (void)fadeFromTransparentToColor:(UIColor*)color
                             alpha:(CGFloat)alpha
                        useSpinner:(BOOL)useSpinner {
    self.isTransparent   = NO;
    self.backgroundColor = color;
    if (useSpinner) {
        [self.activityIndicator startAnimating];
    }
    [UIView animateWithDuration:kFadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.alpha = alpha;
        self.activityIndicator.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
}

- (void)fadeToTransparent {
    [UIView animateWithDuration:kFadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.alpha = 0.0;
        self.activityIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
        self.isTransparent = YES;
    }];
}

@end
