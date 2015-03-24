//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@class PaddedLabel;

@interface SavedPagesResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet PaddedLabel* savedItemLabel;
@property (nonatomic) BOOL useField;

@end
