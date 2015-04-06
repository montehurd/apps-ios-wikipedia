//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PaddedLabel.h"

@interface SearchDidYouMeanButton : PaddedLabel

- (void)showWithText:(NSString*)text term:(NSString*)term;
- (void)hide;

@end
