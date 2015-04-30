//  Created by Monte Hurd on 4/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIImage (WMFAdjustAlpha)

- (UIImage *)wmf_imageByApplyingAlpha:(CGFloat) alpha;

- (UIImage *)wmf_imageByChangingAlphaToColor:(UIColor *) color;

@end
