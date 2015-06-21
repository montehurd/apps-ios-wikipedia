//
//  UIView+WMFRecursivelyMirrorLabelSubviews.m
//  Wikipedia
//
//  Created by Monte Hurd on 6/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIView+WMFRecursivelyMirrorLabelSubviews.h"

@implementation UIView (WMFRecursivelyMirrorLabelSubviews)

- (void)wmf_recursivelyMirrorSubviewLabels {
    for (UIView* subView in self.subviews.copy) {
        if ([subView isKindOfClass:[UILabel class]]) {
            subView.transform = CGAffineTransformMakeScale(-1, 1);
        }
        [subView wmf_recursivelyMirrorSubviewLabels];
    }
}

@end
