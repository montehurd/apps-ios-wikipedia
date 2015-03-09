//  Created by Monte Hurd on 3/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFWebViewHeaderViewController.h"
#import "UIViewController+WMFChildViewController.h"

@interface WMFWebViewHeaderViewController ()

@property (weak, nonatomic) IBOutlet UIView* container;

@property (weak, nonatomic) IBOutlet UIView* leadImageSubContainerView;

@end

@implementation WMFWebViewHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubHeaderContainers];
}

- (void)setupSubHeaderContainers {
    self.leadImageController = [[WMFLeadImageViewController alloc] init];
    [self wmf_addChildController:self.leadImageController andConstrainToEdgesOfContainerView:self.leadImageSubContainerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
