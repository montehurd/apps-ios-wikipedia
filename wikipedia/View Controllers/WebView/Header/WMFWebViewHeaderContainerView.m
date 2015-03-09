//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFWebViewHeaderContainerView.h"

@interface WMFWebViewHeaderContainerView ()

@property (nonatomic) CGFloat height;

@end

@implementation WMFWebViewHeaderContainerView

- (instancetype)initWithHeight:(CGFloat)height {
    self = [super init];
    if (self) {
        self.height          = height;
        self.backgroundColor = [UIColor whiteColor];




/*
   [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil
                                                   queue:[NSOperationQueue mainQueue]
                                              usingBlock:^(NSNotification* note) {
    // Repeated calls to getFaceBounds returns next face bounds each time.


   self.height -= 50.0f;

    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
   }];
 */
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    NSLog(@"ASDFASDFASDFASDFASDFASD");

    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

@end
