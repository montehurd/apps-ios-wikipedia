//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ProgressLine.h"

@interface ProgressLine()

@property (weak, nonatomic) UIView *view;

@property (strong, nonatomic) CAShapeLayer *shape1;

@property (strong, nonatomic) CAShapeLayer *shape2;

@property (nonatomic) bool flip;

@property (strong, nonatomic) UIColor *color;

@property (nonatomic) CGFloat lineHeight;

@end

@implementation ProgressLine

-(id)initWithView: (UIView *)view
            color: (UIColor *)color
       lineHeight: (CGFloat)lineHeight
{
    self = [super init];
    if (self) {
        self.view = view;
        self.color = color;
        self.lineHeight = lineHeight;
        self.shape1 = [CAShapeLayer layer];
        self.shape2 = [CAShapeLayer layer];
        self.progress = 0.0f;
        self.flip = NO;
    }
    return self;
}

-(void)clear
{
    [self.shape1 removeFromSuperlayer];
    [self.shape2 removeFromSuperlayer];
    [self.view.layer removeAllAnimations];
}

-(void)drawWithDuration: (CGFloat)duration
                  delay: (CGFloat)delay
{
    if ((duration == 0.0) || (self.progress == 0)) {
        [self clear];
    }
    
    void(^drawLine)(CAShapeLayer *) = ^(CAShapeLayer *pathLayer){
        CGFloat width = self.view.frame.size.width * self.progress;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0.0f, 0.0f)];
        [path addLineToPoint:CGPointMake(width, 0.0f)];
        
        pathLayer.path = path.CGPath;

        pathLayer.frame = self.view.bounds;
        pathLayer.strokeColor = [self.color CGColor];
        pathLayer.lineWidth = self.lineHeight;
        
        [self.view.layer addSublayer:pathLayer];
        
        [pathLayer removeAllAnimations];
        
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = duration;
        pathAnimation.fromValue = @(0);
        pathAnimation.toValue = @(1);
        
        pathAnimation.fillMode = kCAFillModeBackwards;
        pathAnimation.removedOnCompletion = NO;
        [pathAnimation setBeginTime:CACurrentMediaTime() + delay];
        
        [pathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
    };
    
    drawLine(self.flip ? self.shape1 : self.shape2);
    
    self.flip = !self.flip;
}

@end
