//  Created by Monte Hurd on 11/23/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TopMenuTextFieldClearButtonType) {
    TOP_TEXT_FIELD_CLEAR_BUTTON_UNKNOWN = 0,
    TOP_TEXT_FIELD_CLEAR_BUTTON_X,
    TOP_TEXT_FIELD_CLEAR_BUTTON_LANGS
};

@class TopMenuTextField;

// Protocol for notifying fetchFinishedDelegate that download has completed.
@protocol TopMenuTextFieldClearTappedDelegate <NSObject>
    -(void)clearTapped:(TopMenuTextField *)sender;
@end

@interface TopMenuTextField : UITextField

@property(nonatomic, copy) NSString *placeholder;

@property(nonatomic) TopMenuTextFieldClearButtonType clearButtonType;

// Object to receive "clearTapped:" notifications.
@property (nonatomic, weak) id <TopMenuTextFieldClearTappedDelegate> clearTappedDelegate;

-(void)refreshClearButton;

@end
