//
//  WikidataDescriptionEditorViewController.m
//  Wikipedia
//
//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WikidataDescriptionEditorViewController.h"
#import "UIViewController+ModalPop.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"
#import "PaddedLabel.h"
#import "WikidataDescriptionUploader.h"
#import "QueuesSingleton.h"
#import "UIViewController+Alert.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "NSString+FormattedAttributedString.h"

@interface WikidataDescriptionEditorViewController ()

@end

@implementation WikidataDescriptionEditorViewController

- (NavBarMode)navBarMode {
    return NAVBAR_MODE_EDIT_ARTICLE_DESCRIPTION;
}

- (NSString*)title {
//TODO: i18n
    return @"Edit Description";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSString* title = [self article].displaytitle;

    self.label.text = [NSString stringWithFormat:@"Short description of '%@':", [title wmf_stringByRemovingHTML]];

    self.tipsLabel.attributedText = [self getTipsAttributedString];

    self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.textView.text = [[self article].entityDescription wmf_stringByCapitalizingFirstCharacter];

    self.textView.layer.cornerRadius = 3.0f;
}

- (NSAttributedString*)getTipsAttributedString {
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 5;
    //paragraphStyle.lineSpacing = 8;

    NSDictionary* attributes =
        @{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor blackColor]
    };

    NSDictionary* italicAttributes =
        @{
        NSFontAttributeName: [UIFont italicSystemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor blackColor]
    };

    return
        [@"$1\n$2\n\n$3\n$4" attributedStringWithAttributes:nil
                                        substitutionStrings:@[
             @"Description tip:",
             @"Keep it concise - aim for one line between 2 and 12 words.",
             @"Example description for 'Unicorn':",
             @"mythical creature, horse-like with horn on its head"
         ]
                                     substitutionAttributes:@[attributes, attributes, attributes, italicAttributes]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navItemTappedNotification:)
                                                 name:@"NavItemTapped"
                                               object:nil];


    [self.textView becomeFirstResponder];
}

- (MWKArticle*)article {
    return [SessionSingleton sharedInstance].currentArticle;
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    UIView* tappedItem     = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModalToRoot];
            break;
        case NAVBAR_BUTTON_SAVE: {
            NSLog(@"SAVE");


            NSString* token = nil;

            (void)[[WikidataDescriptionUploader alloc] initAndUploadWikidataDescription:self.textView.text
                                                                           forPageTitle:[self article].title
                                                                                  token:token
                                                                            withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                                     thenNotifyDelegate:self];




            break;
        }
        default:
            break;
    }
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    switch (status) {
        case FETCH_FINAL_STATUS_SUCCEEDED: {
            // show succeess alert (w 5 second timeout) and hide modal.

//TODO: i18n
            [self showAlert:@"Description saved" type:ALERT_TYPE_TOP duration:5];

            WebViewController* webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
            [webVC reloadCurrentArticle];

            [self performSelector:@selector(popModalToRoot) withObject:nil afterDelay:1.0f];




            break;
        }
        default:
            // show alert with error info if any
            [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];

            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"NavItemTapped"
                                                  object:nil];
}

/*
   #pragma mark - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   }
 */

@end
