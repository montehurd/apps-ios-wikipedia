//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class WebViewController;
@interface ReferencesVC : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController* pageController;

@property (strong, nonatomic) NSDictionary* payload;

@property (weak, nonatomic) WebViewController* webVC;

@property (assign) CGFloat panelHeight;

- (void)reset;

+ (ReferencesVC*)initialViewControllerFromStoryBoard;

@end
