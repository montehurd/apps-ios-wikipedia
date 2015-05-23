//
//  WikidataDescriptionEditorViewController.h
//  Wikipedia
//
//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"
#import "FetcherBase.h"

@class PaddedLabel;

@interface WikidataDescriptionEditorViewController : UIViewController <FetchFinishedDelegate>

@property (nonatomic) NavBarMode navBarMode;

@property (nonatomic, weak) IBOutlet PaddedLabel* label;
@property (nonatomic, weak) IBOutlet UITextView* textView;
@property (nonatomic, weak) IBOutlet PaddedLabel* tipsLabel;

@end
