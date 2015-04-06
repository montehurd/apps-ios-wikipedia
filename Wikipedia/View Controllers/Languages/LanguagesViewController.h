//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "TopMenuViewController.h"
#import "FetcherBase.h"

@class LanguagesViewController;

// Protocol for notifying languageSelectionDelegate that selection was made.
@protocol LanguageSelectionDelegate <NSObject>
- (void)languageSelected:(NSDictionary*)langData sender:(LanguagesViewController*)sender;
@end

@interface LanguagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FetchFinishedDelegate>

@property (nonatomic) BOOL downloadLanguagesForCurrentArticle;

@property (nonatomic) NavBarMode navBarMode;

@property (nonatomic, weak) id invokingVC;

@property (weak, nonatomic) id truePresentingVC;

@property (strong, nonatomic) IBOutlet UITableView* tableView;

// Object to receive "languageSelected:sender:" notifications.
@property (nonatomic, weak) id <LanguageSelectionDelegate> languageSelectionDelegate;

@end
