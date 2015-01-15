//
//  WikidataDescriptionEditorView.h
//  Wikipedia
//
//  Created by Monte Hurd on 1/15/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PaddedLabel;

@interface WikidataDescriptionEditorView : UIView

@property (nonatomic, strong) IBOutlet PaddedLabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITextField *descriptionTextField;

@end
