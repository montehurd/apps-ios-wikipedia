//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikidataDescriptionEditorViewController.h"
#import "UIViewController+ModalPop.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"
#import "WikidataDescriptionUploader.h"
#import "QueuesSingleton.h"
#import "UIViewController+Alert.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "NSString+FormattedAttributedString.h"
#import "CentralAuthTokenFetcher.h"
#import "WikidataEditTokenFetcher.h"
#import "Defines.h"
#import "MenuButton.h"
#import "WikipediaAppUtils.h"

@interface WikidataDescriptionEditorViewController ()

@property (nonatomic, weak) IBOutlet PaddedLabel* label;
@property (nonatomic, weak) IBOutlet UITextView* textView;
@property (nonatomic, weak) IBOutlet PaddedLabel* tipsLabel;
@property (nonatomic, weak) IBOutlet UIView* textViewContainer;

@end

@implementation WikidataDescriptionEditorViewController

- (NavBarMode)navBarMode {
    return NAVBAR_MODE_EDIT_ARTICLE_DESCRIPTION;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString* title = [self article].displaytitle;

    self.label.text = [MWLocalizedString(@"description-editor-prompt", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[title wmf_stringByRemovingHTML]];

    self.tipsLabel.attributedText = [self getTipsAttributedString];

    self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.textView.text = [self article].entityDescription;

    self.textViewContainer.backgroundColor = CHROME_COLOR;

    self.textViewContainer.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.textViewContainer.layer.borderWidth = 1.0f;


    self.textViewContainer.layer.cornerRadius = 2.0f;
}

- (NSAttributedString*)getTipsAttributedString {
    return
        [@"$1\n$2\n\n$3\n$4"
         attributedStringWithAttributes:nil
                    substitutionStrings:@[
             MWLocalizedString(@"description-editor-tip-title", nil),
             MWLocalizedString(@"description-editor-tip-details", nil),
             MWLocalizedString(@"description-editor-example-title", nil),
             MWLocalizedString(@"description-editor-example-details", nil)
         ]
                 substitutionAttributes:@[
             @{
                 NSFontAttributeName: [UIFont boldSystemFontOfSize:16],
                 NSForegroundColorAttributeName: [UIColor grayColor]
             },
             @{
                 NSFontAttributeName: [UIFont systemFontOfSize:14],
                 NSForegroundColorAttributeName: [UIColor lightGrayColor]
             },
             @{
                 NSFontAttributeName: [UIFont boldSystemFontOfSize:16],
                 NSForegroundColorAttributeName: [UIColor grayColor]
             },
             @{
                 NSFontAttributeName: [UIFont italicSystemFontOfSize:14],
                 NSForegroundColorAttributeName: [UIColor lightGrayColor]
             }]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navItemTappedNotification:)
                                                 name:@"NavItemTapped"
                                               object:nil];

    [self.textView becomeFirstResponder];
}

- (MWKArticle*)article {
    return [SessionSingleton sharedInstance].currentArticle;
}

- (void)updateDescriptionUsingWikiDataEditToken:(NSString*)token centralAuthToken:(NSString*)centralAuthToken {
    (void)[[WikidataDescriptionUploader alloc] initAndUploadWikidataDescription:self.textView.text
                                                                   forPageTitle:[self article].title
                                                              wikidataEditToken:token
                                                               centralAuthToken:centralAuthToken
                                                                    withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                             thenNotifyDelegate:self];
}

- (void)navItemTappedNotification:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    UIView* tappedItem     = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self popModalToRoot];
            break;
        case NAVBAR_BUTTON_SAVE: {
            MenuButton* button = (MenuButton*)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_SAVE];
            button.enabled = YES;

            [self showAlert:MWLocalizedString(@"description-editor-saving-message", nil) type:ALERT_TYPE_TOP duration:-1];

            BOOL userIsloggedIn = [SessionSingleton sharedInstance].keychainCredentials.userName ? YES : NO;
            if (!userIsloggedIn) {
                [self updateDescriptionUsingWikiDataEditToken:@"+\\" centralAuthToken:nil];
            } else {
                (void)[[CentralAuthTokenFetcher alloc] initAndFetchCentralAuthTokenForSite:[self article].title.site
                                                                                  userData:nil
                                                                               withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                                        thenNotifyDelegate:self];
            }

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
    if ([sender isKindOfClass:[WikidataEditTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                WikidataEditTokenFetcher* wikidataEditTokenFetcher = (WikidataEditTokenFetcher*)sender;

                (void)[[CentralAuthTokenFetcher alloc] initAndFetchCentralAuthTokenForSite:[self article].title.site
                                                                                  userData:wikidataEditTokenFetcher
                                                                               withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                                        thenNotifyDelegate:self];
                break;
            }
            default:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    } else if ([sender isKindOfClass:[CentralAuthTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                CentralAuthTokenFetcher* centralAuthTokenFetcher = (CentralAuthTokenFetcher*)sender;

                if (!centralAuthTokenFetcher.userData) {
                    (void)[[WikidataEditTokenFetcher alloc] initAndFetchEditTokenWithCentralAuthToken:centralAuthTokenFetcher.token
                                                                                          withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                                                   thenNotifyDelegate:self];
                } else if ([centralAuthTokenFetcher.userData isKindOfClass:[WikidataEditTokenFetcher class]]) {
                    WikidataEditTokenFetcher* wikidataEditTokenFetcher = (WikidataEditTokenFetcher*)centralAuthTokenFetcher.userData;

                    [self updateDescriptionUsingWikiDataEditToken:wikidataEditTokenFetcher.editToken centralAuthToken:centralAuthTokenFetcher.token];
                }

                break;
            }
            default:
                // Use anonymous token if central auth token not retrieved.
                [self updateDescriptionUsingWikiDataEditToken:@"+\\" centralAuthToken:nil];

                break;
        }
    } else if ([sender isKindOfClass:[WikidataDescriptionUploader class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                [self showAlert:MWLocalizedString(@"description-editor-saved-message", nil) type:ALERT_TYPE_TOP duration:5];

                WebViewController* webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];

                // Update the dom so we don't have to reload article to see the new description.
                [webVC.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById( 'lead_image_description' ).innerHTML = '%@';", [[self.textView.text wmf_stringByCapitalizingFirstCharacter] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]]];

                // Also update data record so we don't have to reload article to new description if we immediately try to edit the description again.
                self.article.entityDescription = self.textView.text;
                [self.article save];

                [self performSelector:@selector(popModalToRoot) withObject:nil afterDelay:1.0f];

                break;
            }
            default:
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"NavItemTapped"
                                                  object:nil];
}

@end
