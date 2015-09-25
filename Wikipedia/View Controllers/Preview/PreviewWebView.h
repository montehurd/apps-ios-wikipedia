//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "WMFOpenExternalLinkProtocol.h"

@interface PreviewWebView : UIWebView <UIWebViewDelegate>

@property (nonatomic, weak) id <WMFOpenExternalLinkProtocol> externalLinksOpenerDelegate;

@end
