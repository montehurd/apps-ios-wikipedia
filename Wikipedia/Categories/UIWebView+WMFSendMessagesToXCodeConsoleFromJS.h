//  Created by Monte Hurd on 8/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIWebView (WMFSendMessagesToXCodeConsoleFromJS)

- (void)wmf_enableSendingMessagesToXcodeConsoleFromJavascriptMethodNamed:(NSString*)jsMethodName;

@end
