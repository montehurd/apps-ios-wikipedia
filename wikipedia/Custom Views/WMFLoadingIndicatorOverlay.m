//  Created by Monte Hurd on 3/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFLoadingIndicatorOverlay.h"
#import "UIColor+WMFHexColor.h"
#import <Masonry/Masonry.h>

static const CGFloat kActivityIndicatorWidth             = 100.0f;
static const CGFloat kActivityIndicatorCornerRadius      = 10.0f;
static const NSInteger kActivityIndicatorBackgroundColor = 0x000000;

@interface WMFLoadingIndicatorOverlay ()

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic) CGFloat lastNonZeroAlpha;

@end

@implementation WMFLoadingIndicatorOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
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
        self.activityIndicator.hidesWhenStopped   = YES;
        self.activityIndicator.backgroundColor    = [UIColor wmf_colorWithHex:kActivityIndicatorBackgroundColor alpha:1.0f];
        self.activityIndicator.layer.cornerRadius = kActivityIndicatorCornerRadius;
    }
    return _activityIndicator;
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    if (!hidden) {
        self.hidden = NO;
        if (self.showSpinner) {
            [self.activityIndicator startAnimating];
        }

        [self performAnimations:^{
            self.alpha = self.lastNonZeroAlpha;
        } completion:nil];
    } else {
        [self performAnimations:^{
            self.alpha = 0.0;
        } completion:^{
            [self.activityIndicator stopAnimating];
            self.hidden = YES;
        }];
    }
}

- (void)performAnimations:(dispatch_block_t)animationsBlock
               completion:(dispatch_block_t)completionBlock {
    [UIView animateWithDuration:self.animationDuration
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        if (animationsBlock) {
            animationsBlock();
        }
    } completion:^(BOOL finished) {
        if (completionBlock) {
            completionBlock();
        }
    }];
}

- (void)setAlpha:(CGFloat)alpha {
    if (self.alpha != 0.0f) {
        self.lastNonZeroAlpha = self.alpha;
    }
    [super setAlpha:alpha];
}

@end
