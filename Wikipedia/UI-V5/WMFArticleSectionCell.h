//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class PaddedLabel;
@interface WMFArticleSectionCell : UITableViewCell

@property (strong, nonatomic) IBOutlet PaddedLabel* titleLabel;
@property (strong, nonatomic) NSNumber* level;

@end
