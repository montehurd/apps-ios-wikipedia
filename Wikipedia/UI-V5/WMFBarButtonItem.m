//  Created by Monte Hurd on 6/15/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFBarButtonItem.h"
#import "WikiGlyphLabel.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "UIGestureRecognizer+BlocksKit.h"

@interface WMFBarButtonItem ()
@property(nonatomic, retain) WikiGlyphLabel* label;
@property(nonatomic) WMFBarButtonType type;
@end

@implementation WMFBarButtonItem

- (instancetype)initBarButtonOfType:(WMFBarButtonType)type
                            handler:(void (^)(id sender))action {
    _selected      = NO;
    _disabled      = NO;
    _type          = type;
    _selectedType  = WMF_BUTTON_NONE;
    _color         = [UIColor blackColor];
    _disabledColor = [UIColor lightGrayColor];
    _selectedColor = [UIColor redColor];

    self = [super init];
    if (self) {
        self.label                        = [[WikiGlyphLabel alloc]init];
        self.label.clipsToBounds          = YES;
        self.label.autoresizingMask       = UIViewAutoresizingFlexibleHeight;
        self.label.userInteractionEnabled = YES;
        self.label.frame                  = (CGRect){{0, 0}, {40, 40}};
        [self.label addGestureRecognizer:[[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer* sender, UIGestureRecognizerState state, CGPoint location){
            if (state == UIGestureRecognizerStateEnded && !self.disabled) {
                [self.label animateAndRewindXF:CATransform3DMakeScale(1.25, 1.25, 1.0f)
                                    afterDelay:0.0
                                      duration:0.04f
                                          then:^{
                    if (action) {
                        //action(sender);
                        action(self);
                    }
                }];
            }
        }]];
        self.customView             = self.label;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits    = UIAccessibilityTraitButton;
        [self updateLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    [self updateLabel];
}

- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    [self updateAccessibilityTraits];
    [self updateLabel];
}

- (void)setSelectedType:(WMFBarButtonType)selectedType {
    _selectedType = selectedType;
    [self updateLabel];
}

- (void)setColor:(UIColor*)color {
    _color = color;
    [self updateLabel];
}

- (void)setSelectedColor:(UIColor*)color {
    _selectedColor = color;
    [self updateLabel];
}

- (void)setDisabledColor:(UIColor*)disabledColor {
    _disabledColor = disabledColor;
    [self updateLabel];
}

- (void)updateAccessibilityTraits {
    if (self.disabled) {
        self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitNotEnabled;
    } else {
        self.accessibilityTraits = self.accessibilityTraits & (~UIAccessibilityTraitNotEnabled);
    }
}

- (void)updateLabel {
    UIColor* color = self.color;
    if (self.selected) {
        color = self.selectedColor;
    }
    if (self.disabled) {
        color = self.disabledColor;
    }
    [self.label setWikiText:[self glyphStringForBarButtonType:(self.selected && (self.selectedType != WMF_BUTTON_NONE)) ? self.selectedType : self.type]
                      color:color
                       size:30
             baselineOffset:1.2];
}

+ (NSDictionary*)glyphStrings {
    static NSDictionary* strings = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        strings = @{
            @(WMF_BUTTON_W): @"\ue950",
            @(WMF_BUTTON_SHARE): @"\ue951",
            @(WMF_BUTTON_MAGNIFY): @"\ue952",
            @(WMF_BUTTON_MAGNIFY_BOLD): @"\ue953",
            @(WMF_BUTTON_FORWARD): @"\ue954",
            @(WMF_BUTTON_BACKWARD): @"\ue955",
            @(WMF_BUTTON_DOWN): @"\ue956",
            @(WMF_BUTTON_HEART): @"\ue957",
            @(WMF_BUTTON_HEART_OUTLINE): @"\ue958",
            @(WMF_BUTTON_TOC_COLLAPSED): @"\ue959",
            @(WMF_BUTTON_TOC_EXPANDED): @"\ue95a",
            @(WMF_BUTTON_STAR): @"\ue95b",
            @(WMF_BUTTON_STAR_OUTLINE): @"\ue95c",
            @(WMF_BUTTON_TICK): @"\ue95d",
            @(WMF_BUTTON_X): @"\ue95e",
            @(WMF_BUTTON_DICE): @"\ue95f",
            @(WMF_BUTTON_ENVELOPE): @"\ue960",
            @(WMF_BUTTON_CARET_LEFT): @"\ue961",
            @(WMF_BUTTON_TRASH): @"\ue962",
            @(WMF_BUTTON_FLAG): @"\ue963",
            @(WMF_BUTTON_USER_SMILE): @"\ue964",
            @(WMF_BUTTON_USER_SLEEP): @"\ue965",
            @(WMF_BUTTON_TRANSLATE): @"\ue966",
            @(WMF_BUTTON_PENCIL): @"\ue967",
            @(WMF_BUTTON_LINK): @"\ue968",
            @(WMF_BUTTON_CC): @"\ue969",
            @(WMF_BUTTON_X_CIRCLE): @"\ue96a",
            @(WMF_BUTTON_CITE): @"\ue96b",
            @(WMF_BUTTON_PUBLIC_DOMAIN): @"\ue96c",
            @(WMF_BUTTON_RELOAD): @"\ue96d",
            @(WMF_BUTTON_NONE): @""
        };
    });
    return strings;
}

- (NSString*)glyphStringForBarButtonType:(WMFBarButtonType)type {
    return [WMFBarButtonItem glyphStrings][@(type)];
}

@end
