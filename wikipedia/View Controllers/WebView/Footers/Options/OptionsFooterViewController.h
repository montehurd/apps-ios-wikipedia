//
//  OptionsFooterViewController.h
//  Wikipedia
//
//  Created by Monte Hurd on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionsFooterViewController : UIViewController

-(void)updateLanguageCount:(NSInteger)count;
-(void)updateLastModifiedDate:(NSDate *)date userName:(NSString *)userName;

@end
