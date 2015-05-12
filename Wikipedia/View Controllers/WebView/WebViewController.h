//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "CenterNavController.h"
#import "PullToRefreshViewController.h"
#import "ArticleFetcher.h"

// TODO: rename the WebViewControllerVariableNames once we rename this class
extern NSString* const WebViewControllerTextWasHighlighted;
extern NSString* const WebViewControllerWillShareNotification;
extern NSString* const WebViewControllerShareBegin;
extern NSString* const WebViewControllerShareSelectedText;

@class BottomMenuViewController, CommunicationBridge;

@interface WebViewController : PullToRefreshViewController <UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, FetchFinishedDelegate>

@property (weak, nonatomic) IBOutlet UIWebView* webView;
@property (nonatomic) BOOL bottomMenuHidden;
@property (nonatomic) BOOL referencesHidden;
@property (nonatomic) BOOL scrollingToTop;

/**
 * Currently-selected text in the webview, if there is any.
 * @return The selection if it's longer than `kMinimumTextSelectionLength`, otherwise an empty string.
 */
@property (nonatomic, strong, readonly) NSString* selectedText;

@property (weak, nonatomic) BottomMenuViewController* bottomMenuViewController;

- (void)referencesShow:(NSDictionary*)payload;
- (void)referencesHide;

- (void)reloadCurrentArticle;

- (void)navigateToPage:(MWKTitle*)title
       discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

- (void)tocScrollWebViewToSectionWithElementId:(NSString*)elementId
                                      duration:(CGFloat)duration
                                   thenHideTOC:(BOOL)hideTOC;

- (void)tocHide;
- (void)tocToggle;
- (void)saveWebViewScrollOffset;

@end
