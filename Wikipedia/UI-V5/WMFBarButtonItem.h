//  Created by Monte Hurd on 6/15/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

typedef NS_ENUM (NSInteger, WMFBarButtonType) {
    WMF_BUTTON_NONE,
    WMF_BUTTON_W,
    WMF_BUTTON_SHARE,
    WMF_BUTTON_MAGNIFY,
    WMF_BUTTON_MAGNIFY_BOLD,
    WMF_BUTTON_FORWARD,
    WMF_BUTTON_BACKWARD,
    WMF_BUTTON_DOWN,
    WMF_BUTTON_HEART,
    WMF_BUTTON_HEART_OUTLINE,
    WMF_BUTTON_TOC_COLLAPSED,
    WMF_BUTTON_TOC_EXPANDED,
    WMF_BUTTON_STAR,
    WMF_BUTTON_STAR_OUTLINE,
    WMF_BUTTON_TICK,
    WMF_BUTTON_X,
    WMF_BUTTON_DICE,
    WMF_BUTTON_ENVELOPE,
    WMF_BUTTON_CARET_LEFT,
    WMF_BUTTON_TRASH,
    WMF_BUTTON_FLAG,
    WMF_BUTTON_USER_SMILE,
    WMF_BUTTON_USER_SLEEP,
    WMF_BUTTON_TRANSLATE,
    WMF_BUTTON_PENCIL,
    WMF_BUTTON_LINK,
    WMF_BUTTON_CC,
    WMF_BUTTON_X_CIRCLE,
    WMF_BUTTON_CITE,
    WMF_BUTTON_PUBLIC_DOMAIN,
    WMF_BUTTON_RELOAD
};

@interface WMFBarButtonItem : UIBarButtonItem

- (instancetype)initBarButtonOfType:(WMFBarButtonType)type
                            handler:(void (^)(id sender))action;

/**
 *  Color. Defaults to black;
 */
@property(nonatomic, retain) UIColor* color;

/**
 *  Color when selected is YES. Defaults to red;
 */
@property(nonatomic, retain) UIColor* selectedColor;

/**
 *  Swaps between using type and selectedType button.
 */
@property (nonatomic) BOOL selected;

/**
 *  Button to swap to when selected is YES.
 */
@property(nonatomic) WMFBarButtonType selectedType;

/**
 *  No longer fires action when disabled.
 */
@property (nonatomic) BOOL disabled;

/**
 *  Color of button when disabled is YES;
 */
@property(nonatomic, retain) UIColor* disabledColor;

@end
