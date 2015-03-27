//  Created by Monte Hurd on 3/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

/**
 *  Overlay view to indicate loading. Can display optional spinner.
 */
@interface WMFLoadingIndicatorOverlay : UIView

/**
 *  Shows/hides the overlay view. A fade animation is used if animated parameter is YES.
 *
 *  @param hidden controls visibility
 *  @param animated controls whether fade animation is used or visibility change happens instantly.
 */
- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 *  Duration of show/hide fade animation used when setHidden:animated: is called.
 */
@property (nonatomic) NSTimeInterval animationDuration;

/**
 *  Control whether a centered "spinner" loading indicator is shown.
 */
@property (nonatomic) BOOL showSpinner;

@end
