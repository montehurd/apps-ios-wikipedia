//  Created by Monte Hurd on 11/23/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextField.h"
#import "Defines.h"
#import "TopMenuTextFieldLangButton.h"

#define BUTTON_HEIGHT (25.0f * MENUS_SCALE_MULTIPLIER)
#define CLEAR_BUTTON_WIDTH (30.0f * MENUS_SCALE_MULTIPLIER)
#define LANG_BUTTON_WIDTH (50.0f * MENUS_SCALE_MULTIPLIER)
#define CLEAR_BUTTON_FRAME CGRectMake(0.0f, 0.0f, CLEAR_BUTTON_WIDTH, BUTTON_HEIGHT)
#define LANG_BUTTON_FRAME CGRectMake(0.0f, 0.0f, LANG_BUTTON_WIDTH, BUTTON_HEIGHT)

@interface TopMenuTextField ()

@property (nonatomic) CGSize langButtonSize;

@end

@implementation TopMenuTextField

@synthesize placeholder = _placeholder;

-(void)setClearButtonType:(TopMenuTextFieldClearButtonType)clearButtonType
{
    if (_clearButtonType == clearButtonType) return;

    _clearButtonType = clearButtonType;
    
    switch (clearButtonType) {
        case TOP_TEXT_FIELD_CLEAR_BUTTON_X:{
            UIButton *clearButton = [[UIButton alloc] initWithFrame:CLEAR_BUTTON_FRAME];
            clearButton.backgroundColor = [UIColor clearColor];
            [clearButton setImage:[UIImage imageNamed:@"text_field_x_circle_gray.png"] forState:UIControlStateNormal];
            //clearButton.layer.borderWidth = 1;
            self.rightView = clearButton;
        }
            break;
        case TOP_TEXT_FIELD_CLEAR_BUTTON_LANGS:{
            TopMenuTextFieldLangButton *searchLangSwitcherButton = [[TopMenuTextFieldLangButton alloc] initWithFrame:LANG_BUTTON_FRAME];
            searchLangSwitcherButton.userInteractionEnabled = YES;
            //searchLangSwitcherButton.layer.borderWidth = 1;
            self.rightView = searchLangSwitcherButton;
        }
            break;
        default:
            break;
    }

    [self.rightView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clearTapped)]];
}

-(void)refreshClearButton
{
    // Force lang button to refesh to show new lang selection.
    // Note: if the lang button isn't showing the lang code, this will
    // not really do anything.
    TopMenuTextFieldClearButtonType previousType = self.clearButtonType;
    self.clearButtonType = TOP_TEXT_FIELD_CLEAR_BUTTON_UNKNOWN;
    self.clearButtonType = previousType;
}

-(void)clearTapped
{
    [self.clearTappedDelegate clearTapped:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clearButtonType = TOP_TEXT_FIELD_CLEAR_BUTTON_X;
        self.clearButtonMode = UITextFieldViewModeNever;
        self.rightViewMode = UITextFieldViewModeAlways;
        self.borderStyle = UITextBorderStyleNone;
        self.layer.cornerRadius = 6.0f * MENUS_SCALE_MULTIPLIER;
        self.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }
    return self;
}

// Adds left padding without messing up leftView or rightView.
// From: http://stackoverflow.com/a/14357720
- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect rect = [super textRectForBounds:bounds];
    return CGRectInset(rect, 10.0f * MENUS_SCALE_MULTIPLIER, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

-(void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.attributedPlaceholder = [self getAttributedPlaceholderForString:(!placeholder) ? @"": placeholder];
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];
    
    [str addAttributes: @{
                          NSForegroundColorAttributeName : SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR
                          }
                 range: NSMakeRange(0, string.length)];
    return str;
}

/*
// Draw separator line at bottom for iOS 6.

- (void)drawRect:(CGRect)rect {
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
        CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);
    }
}
*/

@end
