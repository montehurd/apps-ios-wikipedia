//
//  UINavigationBar+WMFRTLMirror.m
//  Wikipedia
//
//  Created by Monte Hurd on 6/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UINavigationBar+WMFRTLMirror.h"
#import "UIView+WMFRecursivelyMirrorLabelSubviews.h"
#import "WikipediaAppUtils.h"

@implementation UINavigationBar (WMFRTLMirror)

- (void)wmf_mirrorIfDeviceRTL {
    if ([WikipediaAppUtils isDeviceLanguageRTL]) {
        // Mirror the nav bar.
        self.transform = CGAffineTransformMakeScale(-1, 1);
        // Flip labels back so their text isn't mirrored.
        [self wmf_recursivelyMirrorSubviewLabels];
    }
}

@end
