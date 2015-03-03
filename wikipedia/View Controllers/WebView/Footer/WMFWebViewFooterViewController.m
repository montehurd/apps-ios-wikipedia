//  Created by Monte Hurd on 3/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFWebViewFooterViewController.h"
#import "UIViewController+WMFChildViewController.h"
#import "WMFOptionsFooterViewController.h"
#import "WMFLegalFooterViewController.h"
#import "WMFReadMoreViewController.h"
#import "MWKArticle.h"
#import "MWKTitle.h"

@interface WMFWebViewFooterViewController ()

@property (strong, nonatomic) WMFOptionsFooterViewController* optionsController;
@property (strong, nonatomic) WMFReadMoreViewController* readMoreViewController;
@property (strong, nonatomic) WMFLegalFooterViewController* legalViewController;

@property (weak, nonatomic) IBOutlet UIView* containerContainer;

@property (weak, nonatomic) IBOutlet UIView* readMoreContainerView;
@property (weak, nonatomic) IBOutlet UIView* optionsContainerView;
@property (weak, nonatomic) IBOutlet UIView* legalContainerView;

@end

@implementation WMFWebViewFooterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubFooterContainers];
}

- (void)setupSubFooterContainers {
    self.readMoreViewController = [[WMFReadMoreViewController alloc] init];
    [self wmf_addChildController:self.readMoreViewController andConstrainToEdgesOfContainerView:self.readMoreContainerView];

    self.optionsController = [[WMFOptionsFooterViewController alloc] init];
    [self wmf_addChildController:self.optionsController andConstrainToEdgesOfContainerView:self.optionsContainerView];

    self.legalViewController = [[WMFLegalFooterViewController alloc] init];
    [self wmf_addChildController:self.legalViewController andConstrainToEdgesOfContainerView:self.legalContainerView];
}

- (CGFloat)footerHeight {
    // Find the overall height of the content shown by the web footer.
    // Note: can't just use self.view's height because it extends down farther than the sub-containers' content.
    // We need the containerContainer's height plus any top padding, which the line below provides.
    CGPoint p = [self.containerContainer convertPoint:CGPointMake(0, self.containerContainer.frame.size.height) toView:self.view];
    return p.y;
}

- (void)search {
}

- (void)updateReadMoreForArticle:(MWKArticle*)article {
    self.readMoreViewController.searchString                 = article.title.text;
    self.readMoreViewController.articlesToExcludeFromResults = @[article];
    [self.readMoreViewController search];
}

- (void)updateLanguageCount:(NSInteger)count {
    [self.optionsController updateLanguageCount:count];
}

- (void)updateLastModifiedDate:(NSDate*)date userName:(NSString*)userName {
    [self.optionsController updateLastModifiedDate:date userName:userName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
