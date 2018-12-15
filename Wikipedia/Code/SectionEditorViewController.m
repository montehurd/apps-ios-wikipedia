#import "SectionEditorViewController.h"
@import WMF.MWLanguageInfo;
@import WMF.AFHTTPSessionManager_WMFCancelAll;
#import "WikiTextSectionFetcher.h"
#import "PreviewAndSaveViewController.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "Wikipedia-Swift.h"

@import WebKit;

#define EDIT_TEXT_VIEW_FONT [UIFont systemFontOfSize:16.0f]
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MIN (25.0f)
#define EDIT_TEXT_VIEW_LINE_HEIGHT_MAX (25.0f)

@interface SectionEditorViewController () <PreviewAndSaveViewControllerDelegate, WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (strong, nonatomic) NSString *unmodifiedWikiText;
@property (nonatomic) CGRect viewKeyboardRect;
@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) WMFTheme *theme;

@property (strong, nonatomic) SectionEditorWebViewWithTestingButtons *webView;

@end

@implementation SectionEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[SectionEditorWebViewWithTestingButtons alloc] init];

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    v.backgroundColor = [UIColor redColor];
    self.webView.inputAccessoryView = v;

    UIView *v2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    v2.backgroundColor = [UIColor yellowColor];
    self.webView.inputView = v2;

    [self.view wmf_addSubviewWithConstraintsToEdges:self.webView];
    self.webView.navigationDelegate = self;
    [self.webView loadHTMLFromAssetsFile:@"mediawiki-extensions-CodeMirror/codemirror-index.html" scrolledToFragment:nil];

    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }

    UIBarButtonItem *buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(xButtonPressed)];
    buttonX.accessibilityLabel = WMFCommonStrings.accessibilityBackTitle;
    self.navigationItem.leftBarButtonItem = buttonX;

    self.rightButton = [[UIBarButtonItem alloc] initWithTitle:[WMFCommonStrings nextTitle]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(rightButtonPressed)];
    self.navigationItem.rightBarButtonItem = self.rightButton;

    self.unmodifiedWikiText = nil;

    [self.editTextView setDelegate:self];

    // Fix for strange ios 7 bug with large pages of text in the edit text view
    // jumping around if scrolled quickly.
    self.editTextView.layoutManager.allowsNonContiguousLayout = NO;

    //    [self loadLatestWikiTextForSectionFromServer];

    if ([self.editTextView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.editTextView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }

    self.editTextView.smartQuotesType = UITextSmartQuotesTypeNo;

    self.viewKeyboardRect = CGRectNull;

    [self applyTheme:self.theme];

    // "loginWithSavedCredentials..." should help ensure the user will only appear to be logged in when
    // they reach the 'publish' screen if they actually still are logged in. (It uses the "currentlyLoggedInUserFetcher"
    // to try to ensure this.)
    [[WMFAuthenticationManager sharedInstance]
        loginWithSavedCredentialsWithSuccess:^(WMFAccountLoginResult *_Nonnull success) {
            DDLogDebug(@"\n\nSuccessfully logged in with saved credentials for user '%@'.\n\n", success.username);
        }
        userAlreadyLoggedInHandler:^(WMFCurrentlyLoggedInUser *_Nonnull currentLoggedInHandler) {
            DDLogDebug(@"\n\nUser '%@' is already logged in.\n\n", currentLoggedInHandler.name);
        }
        failure:^(NSError *_Nonnull error) {
            DDLogDebug(@"\n\nloginWithSavedCredentials failed with error '%@'.\n\n", error);
        }];
}

- (void)xButtonPressed {
    [self.delegate sectionEditorFinishedEditing:self
                                    withChanges:NO];
}

- (void)rightButtonPressed {
    if (![self changesMade]) {
        [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"wikitext-preview-changes-none", nil, nil, @"No changes were made to be previewed.", @"Alert text shown if no changes were made to be previewed.") sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
    } else {
        [self preview];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self highlightProgressiveButton:[self changesMade]];

    [self scrollTextViewSoCursorNotUnderKeyboard:textView];
}

- (BOOL)changesMade {

    // TODO: wire up to new bits when we remove native text view.
    // also when keyboard shows need to make it so can still scroll to bottom of new web view
    return YES;

    if (!self.unmodifiedWikiText) {
        return NO;
    }
    return ![self.unmodifiedWikiText isEqualToString:self.editTextView.text];
}

- (void)highlightProgressiveButton:(BOOL)highlight {
    self.navigationItem.rightBarButtonItem.enabled = highlight;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self registerForKeyboardNotifications];

    [self highlightProgressiveButton:[self changesMade]];

    if ([self changesMade]) {
        // Needed to keep keyboard on screen when cancelling out of preview.
        [self.editTextView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self unRegisterForKeyboardNotifications];

    [self highlightProgressiveButton:NO];

    [super viewWillDisappear:animated];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError *)error {
    if ([sender isKindOfClass:[WikiTextSectionFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                WikiTextSectionFetcher *wikiTextSectionFetcher = (WikiTextSectionFetcher *)sender;
                NSDictionary *resultsDict = (NSDictionary *)fetchedData;
                NSString *revision = resultsDict[@"revision"];
                NSDictionary *userInfo = resultsDict[@"userInfo"];

                self.funnel = [[EditFunnel alloc] initWithUserId:[userInfo[@"id"] intValue]];
                [self.funnel logStart];

                MWKProtectionStatus *protectionStatus = wikiTextSectionFetcher.section.article.protection;

                if (protectionStatus && [[protectionStatus allowedGroupsForAction:@"edit"] count] > 0) {
                    NSArray *groups = [protectionStatus allowedGroupsForAction:@"edit"];
                    NSString *msg;
                    if ([groups indexOfObject:@"autoconfirmed"] != NSNotFound) {
                        msg = WMFLocalizedStringWithDefaultValue(@"page-protected-autoconfirmed", nil, nil, @"This page has been semi-protected.", @"Brief description of Wikipedia 'autoconfirmed' protection level, shown when editing a page that is protected.");
                    } else if ([groups indexOfObject:@"sysop"] != NSNotFound) {
                        msg = WMFLocalizedStringWithDefaultValue(@"page-protected-sysop", nil, nil, @"This page has been fully protected.", @"Brief description of Wikipedia 'sysop' protection level, shown when editing a page that is protected.");
                    } else {
                        msg = WMFLocalizedStringWithDefaultValue(@"page-protected-other", nil, nil, @"This page has been protected to the following levels: %1$@", @"Brief description of Wikipedia unknown protection level, shown when editing a page that is protected. %1$@ will refer to a list of protection levels.");
                    }
                    [[WMFAlertManager sharedInstance] showAlert:msg sticky:NO dismissPreviousAlerts:YES tapCallBack:NULL];
                } else {
                    //[self showAlert:WMFLocalizedStringWithDefaultValue(@"wikitext-download-success", nil, nil, @"Content loaded.", @"Alert text shown when latest revision of the section being edited has been retrieved") type:ALERT_TYPE_TOP duration:1];
                    [[WMFAlertManager sharedInstance] dismissAlert];
                }
                self.unmodifiedWikiText = revision;
                self.editTextView.attributedText = [self getAttributedString:revision];
                //[self.editTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.4f];

                [self.webView setupWithWikitext:revision
                                  useRichEditor:YES
                              completionHandler:^(NSError *_Nullable error) {
                                  if (error) {
                                      DDLogError(@"Error getting wikitext: %@", error);
                                      return;
                                  }
                              }];

            } break;
            case FETCH_FINAL_STATUS_CANCELLED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
            case FETCH_FINAL_STATUS_FAILED: {
                [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];
            } break;
        }
    }
}

- (void)loadLatestWikiTextForSectionFromServer {
    [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"wikitext-downloading", nil, nil, @"Loading content...", @"Alert text shown when obtaining latest revision of the section being edited") sticky:YES dismissPreviousAlerts:YES tapCallBack:NULL];

    [[QueuesSingleton sharedInstance].sectionWikiTextDownloadManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[WikiTextSectionFetcher alloc] initAndFetchWikiTextForSection:self.section
                                                                 withManager:[QueuesSingleton sharedInstance].sectionWikiTextDownloadManager
                                                          thenNotifyDelegate:self];
    }];
}

- (NSAttributedString *)getAttributedString:(NSString *)string {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.maximumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MIN;
    paragraphStyle.minimumLineHeight = EDIT_TEXT_VIEW_LINE_HEIGHT_MAX;

    paragraphStyle.headIndent = 10.0;
    paragraphStyle.firstLineHeadIndent = 10.0;
    paragraphStyle.tailIndent = -10.0;

    return
        [[NSAttributedString alloc] initWithString:string
                                        attributes:@{
                                            NSParagraphStyleAttributeName: paragraphStyle,
                                            NSFontAttributeName: EDIT_TEXT_VIEW_FONT,
                                            NSForegroundColorAttributeName: self.theme.colors.primaryText
                                        }];
}

- (void)preview {
    [self.webView getWikitextWithCompletionHandler:^(NSString *wikitext, NSError *_Nullable error) {
        if (error) {
            DDLogError(@"Error getting wikitext: %@", error);
            return;
        }
        PreviewAndSaveViewController *previewVC = [PreviewAndSaveViewController wmf_initialViewControllerFromClassStoryboard];
        previewVC.section = self.section;
        previewVC.wikiText = wikitext; // self.editTextView.text;
        previewVC.funnel = self.funnel;
        previewVC.savedPagesFunnel = self.savedPagesFunnel;
        previewVC.delegate = self;
        [previewVC applyTheme:self.theme];
        [self.navigationController pushViewController:previewVC animated:YES];
    }];
}

- (void)previewViewControllerDidSave:(PreviewAndSaveViewController *)previewViewController {
    [self.delegate sectionEditorFinishedEditing:self withChanges:YES];
}

#pragma mark Keyboard

// Ensure the edit text view can scroll whatever text it is displaying all the
// way so the bottom of the text can be scrolled to the top of the screen.
// More info here:
// https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unRegisterForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];

    CGRect windowKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect viewKeyboardRect = [self.view.window convertRect:windowKeyboardRect toView:self.view];

    self.viewKeyboardRect = viewKeyboardRect;

    // This makes it so you can always scroll to the bottom of the text view's text
    // even if the keyboard is onscreen.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, viewKeyboardRect.size.height, 0.0);
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;

    // Mark the text view as needing a layout update so the inset changes above will
    // be taken in to account when the cursor is scrolled onscreen.
    [self.editTextView setNeedsLayout];
    [self.editTextView layoutIfNeeded];

    // Scroll cursor onscreen if needed.
    [self scrollTextViewSoCursorNotUnderKeyboard:self.editTextView];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.editTextView.contentInset = contentInsets;
    self.editTextView.scrollIndicatorInsets = contentInsets;

    self.viewKeyboardRect = CGRectNull;
}

- (void)scrollTextViewSoCursorNotUnderKeyboard:(UITextView *)textView {
    // If cursor is hidden by keyboard, scroll the text view so cursor is onscreen.
    if (!CGRectIsNull(self.viewKeyboardRect)) {
        CGRect cursorRectInTextView = [textView caretRectForPosition:textView.selectedTextRange.start];
        CGRect cursorRectInView = [textView convertRect:cursorRectInTextView toView:self.view];
        if (CGRectIntersectsRect(self.viewKeyboardRect, cursorRectInView)) {
            CGFloat margin = -20;
            // Margin here is the amount the cursor will be scrolled above the top of the keyboard.
            cursorRectInTextView = CGRectInset(cursorRectInTextView, 0, margin);

            [textView scrollRectToVisible:cursorRectInTextView animated:YES];
        }
    }
}

#pragma mark Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // [self.webView toggleRichEditor];
    // [self.webView becomeFirstResponder];

    //    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    //    v.backgroundColor = [UIColor redColor];
    //    self.webView.inputAccessoryView = v;

    //    self.webView.inputAccessoryView = nil;
    //    NSLog(@"self.webView.inputAccessoryView = %@", );
    NSLog(@"HI");

    //    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    //    v.backgroundColor = [UIColor blueColor];
    //    self.webView.inputAccessoryView = v;
    //
    //
    //    UIView* v2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    //    v2.backgroundColor = [UIColor yellowColor];
    //    self.webView.inputView = v2;

    self.webView.inputView = nil;

    [self.webView reloadInputViews];
}

- (void)webView:(SectionEditorWebViewWithTestingButtons *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self loadLatestWikiTextForSectionFromServer];
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape {
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

#pragma mark WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.editTextView.backgroundColor = theme.colors.paperBackground;
    self.editTextView.textColor = theme.colors.primaryText;
    self.view.backgroundColor = theme.colors.paperBackground;
}

@end
