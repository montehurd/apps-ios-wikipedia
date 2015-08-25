//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+WMFSendMessagesToXCodeConsoleFromJS.h"
@import JavaScriptCore;

@implementation UIWebView (WMFSendMessagesToXCodeConsoleFromJS)

- (void)wmf_enableSendingMessagesToXcodeConsoleFromJavascriptMethodNamed:(NSString*)jsMethodName {
    NSAssert(jsMethodName && jsMethodName.length > 0, @"Javascript method name not specified.");
    JSContext* jsCtx = [self valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    jsCtx[jsMethodName] = ^(NSString* param1) {
        NSLog(@"%@", param1);
    };
}

@end
