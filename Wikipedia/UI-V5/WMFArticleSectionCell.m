//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleSectionCell.h"
#import "PaddedLabel.h"

@implementation WMFArticleSectionCell

- (void)setLevel:(NSNumber*)level {
    self.titleLabel.padding = UIEdgeInsetsMake(0, (level.integerValue - 2) * 10, 0, 0);
}

@end
