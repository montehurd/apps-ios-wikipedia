//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface ProgressLine : NSObject

@property (nonatomic) CGFloat progress;

-(id)initWithView: (UIView *)view
            color: (UIColor *)color
       lineHeight: (CGFloat)lineHeight;

-(void)drawWithDuration: (CGFloat)duration
                  delay: (CGFloat)delay;

-(void)clear;

@end
