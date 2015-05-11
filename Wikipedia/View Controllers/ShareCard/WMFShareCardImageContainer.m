

#import "WMFShareCardImageContainer.h"
#import "UIImage+WMFFocalImageDrawing.h"
#import "WMFGeometry.h"

@interface WMFShareCardImageContainer ()

@property(nonatomic) CGRect faceBounds;

@end

@implementation WMFShareCardImageContainer

- (CGRect)getPrimaryFocalRectFromCanonicalLeadImage {
    // Focal rect info is parked on the article.image which is the originally retrieved lead image.
    // self.image is potentially a larger variant, which is why here the focal rect unit coords are
    // sought on self.image.article.image
    CGRect focalBounds  = CGRectZero;
    NSArray* focalRects = [self.image.article.image focalRectsInUnitCoordinatesAsStrings];
    if (focalRects.count > 0) {
        focalBounds = WMFRectFromUnitRectForReferenceSize(CGRectFromString([focalRects firstObject]), self.image.size);
    }
    return focalBounds;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawGradientBackground];

    CGRect focalBounds = [self getPrimaryFocalRectFromCanonicalLeadImage];

    [[self.image asUIImage] wmf_drawInRect:rect
                               focalBounds:focalBounds
                            focalHighlight:NO
                                 blendMode:kCGBlendModeMultiply
                                     alpha:1.0];
}

// TODO: in follow-up patch, factor drawGradientBackground from
// LeadImageContainer so that it is more generalizable for setting
// gradient segments.
- (void)drawGradientBackground {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = UIGraphicsGetCurrentContext();

    void (^ drawGradient)(CGFloat, CGFloat, CGRect) = ^void (CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
        CGFloat locations[] = {
            0.0,  // Upper color stop.
            1.0   // Bottom color stop.
        };
        CGFloat colorComponents[8] = {
            0.0, 0.0, 0.0, upperAlpha,  // Upper color.
            0.0, 0.0, 0.0, bottomAlpha  // Bottom color.
        };
        CGGradientRef gradient =
            CGGradientCreateWithColorComponents(colorSpace, colorComponents, locations, 2);
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGPoint endPoint   = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGGradientRelease(gradient);
    };

    drawGradient(0.4, 0.6, self.frame);
    CGColorSpaceRelease(colorSpace);
}

@end
