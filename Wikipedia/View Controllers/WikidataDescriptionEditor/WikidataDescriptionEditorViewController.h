//  Created by Monte Hurd on 5/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "FetcherBase.h"
#import "TopMenuViewController.h"

@class PaddedLabel;

@interface WikidataDescriptionEditorViewController : UIViewController <FetchFinishedDelegate>

@property (nonatomic) NavBarMode navBarMode;
@property (weak, nonatomic) TopMenuViewController* topMenuViewController;

@end
