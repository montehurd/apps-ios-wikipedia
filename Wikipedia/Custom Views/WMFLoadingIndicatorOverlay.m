//  Created by Monte Hurd on 3/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFLoadingIndicatorOverlay.h"
#import "UIColor+WMFHexColor.h"
#import <Masonry/Masonry.h>

static CGFloat const kActivityIndicatorWidth             = 100.0f;
static CGFloat const kActivityIndicatorCornerRadius      = 10.0f;
static NSInteger const kActivityIndicatorBackgroundColor = 0x000000;

static CGFloat const kShowFadeAnimationDuration = 0.43f;
static CGFloat const kHideFadeAnimationDuration = 0.23f;

@interface WMFLoadingIndicatorOverlay ()

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic) CGFloat lastNonZeroAlpha;
@property (nonatomic) BOOL isVisible;

@end

@implementation WMFLoadingIndicatorOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isVisible              = !self.hidden;
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

- (void)setVisible:(BOOL)isVisible animated:(BOOL)animated {
    if (isVisible) {
        self.isVisible = YES;
        if (self.showSpinner) {
            [self.activityIndicator startAnimating];
        }

        [self performAnimations:^{
            self.alpha = self.lastNonZeroAlpha;
        } duration:(animated ? kShowFadeAnimationDuration : 0.0f) completion:nil];
    } else {
        [self performAnimations:^{
            self.alpha = 0.0;
        } duration:(animated ? kHideFadeAnimationDuration : 0.0f) completion:^{
            [self.activityIndicator stopAnimating];
            self.isVisible = NO;
        }];
    }
}

- (void)performAnimations:(dispatch_block_t)animationsBlock
                 duration:(NSTimeInterval)duration
               completion:(dispatch_block_t)completionBlock {
    if (duration == 0) {
        if (animationsBlock) {
            animationsBlock();
        }
        if (completionBlock) {
            completionBlock();
        }
    } else {
        [UIView animateWithDuration:duration
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
}

- (void)setAlpha:(CGFloat)alpha {
    if (self.alpha != 0.0f) {
        self.lastNonZeroAlpha = self.alpha;
    }
    [super setAlpha:alpha];
}

@end
