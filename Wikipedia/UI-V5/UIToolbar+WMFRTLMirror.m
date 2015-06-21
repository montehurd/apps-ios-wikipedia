//
//  UIToolbar+WMFRTLMirror.m
//  Wikipedia
//
//  Created by Monte Hurd on 6/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIToolbar+WMFRTLMirror.h"
#import "UIView+WMFRecursivelyMirrorLabelSubviews.h"
#import "WikipediaAppUtils.h"

@implementation UIToolbar (WMFRTLMirror)

- (void)wmf_mirrorIfDeviceRTL {
    if ([WikipediaAppUtils isDeviceLanguageRTL]) {
        // Mirror the toolbar.
        self.transform = CGAffineTransformMakeScale(-1, 1);
        // Flip labels back so their text isn't mirrored.
        [self wmf_recursivelyMirrorSubviewLabels];
    }
}

@end
