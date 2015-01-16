//
//  ShareOptionsView.m
//  Wikipedia
//
//  Created by Adam Baso on 1/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"

static const int kCornerRadius = 4.2f;

@implementation WMFShareOptionsView

-(void) didMoveToSuperview
{
    // http://stackoverflow.com/questions/10316902/rounded-corners-only-on-top-of-a-uiview
    CAShapeLayer *topRoundingMaskLayer = [CAShapeLayer layer];
    topRoundingMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.cardImageViewContainer.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){kCornerRadius, kCornerRadius}].CGPath;
    self.cardImageViewContainer.layer.mask = topRoundingMaskLayer;
    CAShapeLayer *bottomRoundingMaskLayer = [CAShapeLayer layer];
    bottomRoundingMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.shareAsCardLabel.bounds byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: (CGSize){kCornerRadius, kCornerRadius}].CGPath;
    self.shareAsCardLabel.layer.mask = bottomRoundingMaskLayer;
    self.shareAsTextLabel.layer.cornerRadius = kCornerRadius;
    self.shareAsTextLabel.layer.masksToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

@end
