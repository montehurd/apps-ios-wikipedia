//  Created by Monte Hurd on 3/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
/**
 * A transparent view which can fade to a given color and alpha
 * to indicate loading. An optional spinner may be shown.
 */
@interface WMFFadedLoadingIndicator : UIView

/**
 *  Fade to given color and alpha to indicate loading with optional spinner.
 *
 *  @param color      Color to fade to
 *  @param alpha      Alpha to fade to
 *  @param useSpinner If YES spinner will be shown as well
 */
- (void)fadeFromTransparentToColor:(UIColor*)color
                             alpha:(CGFloat)alpha
                        useSpinner:(BOOL)useSpinner;

/**
 *  Fade back to transparent
 */
- (void)fadeToTransparent;

@property (nonatomic, readonly) BOOL isTransparent;

@end
