//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIButton+WMFButton.h"
#import "UIControl+BlocksKit.h"
#import "UIFont+WMFStyle.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "WikipediaAppUtils.h"

@implementation UIButton (WMFGlyph)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type handler:(void (^)(id sender))action {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];

    button.frame = (CGRect){{0, 0}, {40, 40}};

    void (^ configForState)(UIControlState, WMFGlyphs, NSNumber*, UIColor*) = ^void (UIControlState state, WMFGlyphs glyph, NSNumber* offset, UIColor* color) {
        [button setAttributedTitle:[self attributedStringForGlyph:glyph baselineOffset:offset color:color]
                          forState:state];
    };

    switch (type) {
        case WMF_BUTTON_W:
            configForState(UIControlStateNormal, WMF_GLYPH_W, @(2.0), nil);
            break;
        case WMF_BUTTON_SHARE:
            configForState(UIControlStateNormal, WMF_GLYPH_SHARE, @(0.2), nil);
            break;
        case WMF_BUTTON_FORWARD:
            configForState(UIControlStateNormal, WMF_GLYPH_FORWARD, nil, nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_FORWARD, nil, [UIColor lightGrayColor]);
            break;
        case WMF_BUTTON_BACKWARD:
            configForState(UIControlStateNormal, WMF_GLYPH_BACKWARD, nil, nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_BACKWARD, nil, [UIColor lightGrayColor]);
            break;
        case WMF_BUTTON_HEART:
            configForState(UIControlStateNormal, WMF_GLYPH_HEART_OUTLINE, nil, nil);
            configForState(UIControlStateSelected, WMF_GLYPH_HEART, nil, [UIColor redColor]);
            break;
        case WMF_BUTTON_TOC:
            configForState(UIControlStateNormal, WMF_GLYPH_TOC_COLLAPSED, @(2.0), nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_TOC_COLLAPSED, @(2.0), [UIColor lightGrayColor]);
            configForState(UIControlStateSelected, WMF_GLYPH_TOC_EXPANDED, @(2.0), nil);
            break;
        case WMF_BUTTON_X:
            configForState(UIControlStateNormal, WMF_GLYPH_X, @(2.8), nil);
            break;
        case WMF_BUTTON_X_WHITE:
            configForState(UIControlStateNormal, WMF_GLYPH_X, @(2.8), [UIColor whiteColor]);
            break;
        case WMF_BUTTON_TRASH:
            configForState(UIControlStateNormal, WMF_GLYPH_TRASH, nil, nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_TRASH, nil, [UIColor lightGrayColor]);
            break;
        case WMF_BUTTON_TRANSLATE:
            configForState(UIControlStateNormal, WMF_GLYPH_TRANSLATE, @(1.4), nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_TRANSLATE, @(1.4), [UIColor lightGrayColor]);
            break;
        case WMF_BUTTON_MAGNIFY:
            configForState(UIControlStateNormal, WMF_GLYPH_MAGNIFY, @(1.0), nil);
            break;
        case WMF_BUTTON_RELOAD:
            configForState(UIControlStateNormal, WMF_GLYPH_RELOAD, nil, nil);
            configForState(UIControlStateDisabled, WMF_GLYPH_RELOAD, nil, [UIColor lightGrayColor]);
            break;
        case WMF_BUTTON_CARET_LEFT:
            configForState(UIControlStateNormal, WMF_GLYPH_CARET_LEFT, nil, nil);
            break;
        default:
            break;
    }

    [self mirrorButton:button ifNecessaryForType:type];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
    } forControlEvents:UIControlEventTouchDown];

    [button bk_addEventHandler:^(UIButton* sender){
        sender.highlighted = !sender.selected; // Prevent annoying flicker.
        [sender animateAndRewindXF:CATransform3DMakeScale([self xMirroringMultiplierForButtonType:type] * 1.25, 1.25, 1.0f)
                        afterDelay:0.0
                          duration:0.04f
                              then:^{
            if (action) {
                action(sender);
            }
        }];
    } forControlEvents:UIControlEventTouchUpInside];

    return button;
}

+ (void)mirrorButton:(UIButton*)button ifNecessaryForType:(WMFButtonType)type {
    button.transform = CGAffineTransformMakeScale(1.0* [self xMirroringMultiplierForButtonType:type], 1.0);
}

+ (CGFloat)xMirroringMultiplierForButtonType:(WMFButtonType)type {
    return [self shouldMirrorButtonType:type] ? 1.0 : -1.0;
}

+ (BOOL)shouldMirrorButtonType:(WMFButtonType)type {
    if (![WikipediaAppUtils isDeviceLanguageRTL]) {
        return NO;
    }
    switch (type) {
        case WMF_BUTTON_W:
        case WMF_BUTTON_TRANSLATE:
        case WMF_BUTTON_MAGNIFY:
        case WMF_BUTTON_RELOAD:
            return NO;
            break;
        default:
            return YES;
    }
}

typedef NS_ENUM (NSInteger, WMFGlyphs) {
    WMF_GLYPH_W,
    WMF_GLYPH_SHARE,
    WMF_GLYPH_MAGNIFY,
    WMF_GLYPH_MAGNIFY_BOLD,
    WMF_GLYPH_FORWARD,
    WMF_GLYPH_BACKWARD,
    WMF_GLYPH_DOWN,
    WMF_GLYPH_HEART,
    WMF_GLYPH_HEART_OUTLINE,
    WMF_GLYPH_TOC_COLLAPSED,
    WMF_GLYPH_TOC_EXPANDED,
    WMF_GLYPH_STAR,
    WMF_GLYPH_STAR_OUTLINE,
    WMF_GLYPH_TICK,
    WMF_GLYPH_X,
    WMF_GLYPH_DICE,
    WMF_GLYPH_ENVELOPE,
    WMF_GLYPH_CARET_LEFT,
    WMF_GLYPH_TRASH,
    WMF_GLYPH_FLAG,
    WMF_GLYPH_USER_SMILE,
    WMF_GLYPH_USER_SLEEP,
    WMF_GLYPH_TRANSLATE,
    WMF_GLYPH_PENCIL,
    WMF_GLYPH_LINK,
    WMF_GLYPH_CC,
    WMF_GLYPH_X_CIRCLE,
    WMF_GLYPH_CITE,
    WMF_GLYPH_PUBLIC_DOMAIN,
    WMF_GLYPH_RELOAD
};

+ (NSDictionary*)glyphStrings {
    static NSDictionary* strings = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        strings = @{
            @(WMF_GLYPH_W): @"\ue950",
            @(WMF_GLYPH_SHARE): @"\ue951",
            @(WMF_GLYPH_MAGNIFY): @"\ue952",
            @(WMF_GLYPH_MAGNIFY_BOLD): @"\ue953",
            @(WMF_GLYPH_FORWARD): @"\ue954",
            @(WMF_GLYPH_BACKWARD): @"\ue955",
            @(WMF_GLYPH_DOWN): @"\ue956",
            @(WMF_GLYPH_HEART): @"\ue957",
            @(WMF_GLYPH_HEART_OUTLINE): @"\ue958",
            @(WMF_GLYPH_TOC_COLLAPSED): @"\ue959",
            @(WMF_GLYPH_TOC_EXPANDED): @"\ue95a",
            @(WMF_GLYPH_STAR): @"\ue95b",
            @(WMF_GLYPH_STAR_OUTLINE): @"\ue95c",
            @(WMF_GLYPH_TICK): @"\ue95d",
            @(WMF_GLYPH_X): @"\ue95e",
            @(WMF_GLYPH_DICE): @"\ue95f",
            @(WMF_GLYPH_ENVELOPE): @"\ue960",
            @(WMF_GLYPH_CARET_LEFT): @"\ue961",
            @(WMF_GLYPH_TRASH): @"\ue962",
            @(WMF_GLYPH_FLAG): @"\ue963",
            @(WMF_GLYPH_USER_SMILE): @"\ue964",
            @(WMF_GLYPH_USER_SLEEP): @"\ue965",
            @(WMF_GLYPH_TRANSLATE): @"\ue966",
            @(WMF_GLYPH_PENCIL): @"\ue967",
            @(WMF_GLYPH_LINK): @"\ue968",
            @(WMF_GLYPH_CC): @"\ue969",
            @(WMF_GLYPH_X_CIRCLE): @"\ue96a",
            @(WMF_GLYPH_CITE): @"\ue96b",
            @(WMF_GLYPH_PUBLIC_DOMAIN): @"\ue96c",
            @(WMF_GLYPH_RELOAD): @"\ue96d"
        };
    });
    return strings;
}

+ (NSAttributedString*)attributedStringForGlyph:(WMFGlyphs)glyph baselineOffset:(NSNumber*)offset color:(UIColor*)color {
    if (!color) {
        color = [UIColor blackColor];
    }
    if (!offset) {
        offset = @(1.2);
    }
    return [[NSAttributedString alloc] initWithString:[self glyphStrings][@(glyph)]
                                           attributes:@{
                NSFontAttributeName: [UIFont wmf_glyphFontOfSize:32],
                NSBaselineOffsetAttributeName: offset,
                NSForegroundColorAttributeName: color
            }];
}

@end
