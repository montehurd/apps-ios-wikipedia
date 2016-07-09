#import "WKScriptMessage+WMFScriptMessage.h"

@implementation WKScriptMessage (WMFScriptMessage)

+ (WMFWKScriptMessageType)wmf_typeForMessageName:(NSString*)name {
    if ([name isEqualToString:@"peek"]) {
        return WMFWKScriptMessagePeek;
    } else if ([name isEqualToString:@"sendJavascriptConsoleLogMessageToXcodeConsole"]) {
        return WMFWKScriptMessageConsoleMessage;
    } else if ([name isEqualToString:@"clicks"]) {
        return WMFWKScriptMessageClicks;
    } else if ([name isEqualToString:@"lateJavascriptTransform"]) {
        return WMFWKScriptMessageLateJavascriptTransform;
    } else if ([name isEqualToString:@"articleState"]) {
        return WMFWKScriptMessageArticleState;
    } else{
        return WMFWKScriptMessageUnknown;
    }
}

+ (Class)wmf_expectedMessageBodyClassForType:(WMFWKScriptMessageType)type {
    switch (type) {
        case WMFWKScriptMessagePeek:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageConsoleMessage:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageClicks:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageLateJavascriptTransform:
            return [NSString class];
            break;
        case WMFWKScriptMessageArticleState:
            return [NSString class];
            break;
        case WMFWKScriptMessageUnknown:
            return [NSNull class];
            break;
    }
}

@end
