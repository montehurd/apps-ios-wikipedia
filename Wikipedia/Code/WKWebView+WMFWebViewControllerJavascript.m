#import "WKWebView+WMFWebViewControllerJavascript.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "WMFProxyServer.h"
#import <WMF/NSURL+WMFLinkParsing.h>

// Some dialects have complex characters, so we use 2 instead of 10
static int const kMinimumTextSelectionLength = 2;

@implementation WKWebView (WMFWebViewControllerJavascript)

- (void)wmf_setTextSize:(NSInteger)textSize {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.querySelector('body').style['-webkit-text-size-adjust'] = '%ld%%';", (long)textSize] completionHandler:NULL];
}

- (void)wmf_collapseTablesForArticle:(MWKArticle *)article {
    [self evaluateJavaScript:[self tableCollapsingJavascriptForArticle:article] completionHandler:nil];
}

- (void)wmf_addEditPencilsForArticle:(MWKArticle *)article {
    
//do we still need the "anchor.href" line below??? was ios 9?
    
    if (!article.isMain) {
        [self evaluateJavaScript:[NSString stringWithFormat:@""
                                                             "window.wmf.editButtons.add(document);"
                                                             "Array.from(document.querySelectorAll('.pagelib_edit_section_link')).forEach(function(anchor){anchor.href = '%@'});",
                                                            WMFEditPencil]
               completionHandler:nil];
    }
}

- (NSString *)tableCollapsingJavascriptForArticle:(MWKArticle *)article {
    NSString *language = article.url.wmf_language;
    NSString *infoBoxTitle = [WMFLocalizedStringWithDefaultValue(@"info-box-title", language, nil, @"Quick Facts", @"The title of infoboxes – in collapsed and expanded form") wmf_stringByReplacingApostrophesWithBackslashApostrophes];
    NSString *tableTitle = [WMFLocalizedStringWithDefaultValue(@"table-title-other", language, nil, @"More information", @"The title of non-info box tables - in collapsed and expanded form\n{{Identical|More information}}") wmf_stringByReplacingApostrophesWithBackslashApostrophes];
    NSString *closeBoxText = [WMFLocalizedStringWithDefaultValue(@"info-box-close-text", language, nil, @"Close", @"The text for telling users they can tap the bottom of the info box to close it\n{{Identical|Close}}") wmf_stringByReplacingApostrophesWithBackslashApostrophes];
    return
        [NSString stringWithFormat:@"window.wmf.tables.hideTables(document, %d, '%@', '%@', '%@', '%@');",
                                   article.isMain, [article.displaytitle wmf_stringByReplacingApostrophesWithBackslashApostrophes], infoBoxTitle, tableTitle, closeBoxText];
}

- (void)wmf_setLanguage:(MWLanguageInfo *)languageInfo {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.setLanguage('%@', '%@', '%@')",
                                                        languageInfo.code,
                                                        languageInfo.dir,
                                                        [[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr"]
           completionHandler:nil];
}

- (void)wmf_setPageProtected:(BOOL)isProtected {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.setPageProtected(%@)", isProtected ? @"true" : @"false"] completionHandler:nil];
}

- (void)wmf_scrollToFragment:(NSString *)fragment {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.scrollToFragment('%@')", fragment] completionHandler:nil];
}

- (void)wmf_accessibilityCursorToFragment:(NSString *)fragment {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.accessibilityCursorToFragment('%@')", fragment] completionHandler:nil];
    }
}

- (void)wmf_highlightLinkID:(NSString *)linkID {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('%@').classList.add('reference_highlight');", linkID]
           completionHandler:NULL];
}

- (void)wmf_unHighlightLinkID:(NSString *)linkID {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('%@').classList.remove('reference_highlight');", linkID]
           completionHandler:NULL];
}

- (void)wmf_getSelectedText:(void (^)(NSString *text))completion {
    [self evaluateJavaScript:@"window.getSelection().toString()"
           completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
               if ([obj isKindOfClass:[NSString class]]) {
                   NSString *selectedText = [(NSString *)obj wmf_shareSnippetFromText];
                   selectedText = selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
                   completion(selectedText);
               } else {
                   completion(@"");
               }
           }];
}

@end
