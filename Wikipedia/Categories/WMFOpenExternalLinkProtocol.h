//  Created by Monte Hurd on 9/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.

#import <Foundation/Foundation.h>

@protocol WMFOpenExternalLinkProtocol

- (void)wmf_externalUrlOpener:(NSURL*)url;

@end
