//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextFieldLangButton.h"
#import "WikipediaAppUtils.h"
#import "NSString+FormattedAttributedString.h"
#import "Defines.h"
#import "SessionSingleton.h"
#import "WikiGlyph_Chars.h"

#define LANG_GLYPH WIKIGLYPH_TRANSLATE
#define LANG_GLYPH_COLOR [UIColor lightGrayColor]
#define LANG_GLYPH_SIZE (16.0f * MENUS_SCALE_MULTIPLIER)

@implementation TopMenuTextFieldLangButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.adjustsFontSizeToFitWidth = YES;
    }
    return self;
}

-(void)didMoveToSuperview
{
    self.padding = UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 8.0f);
    self.attributedText = [self getAttributedString];
    self.textAlignment = [WikipediaAppUtils isDeviceLanguageRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
}

-(NSAttributedString *)getAttributedString
{
    NSDictionary *glyphAttributes = @{
                                      NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:LANG_GLYPH_SIZE],
                                      NSForegroundColorAttributeName: LANG_GLYPH_COLOR
                                      //NSBaselineOffsetAttributeName : @2
                                      };
    
    return [@"$1" attributedStringWithAttributes: @{}
                             substitutionStrings: @[LANG_GLYPH]
                          substitutionAttributes: @[glyphAttributes]];
}

@end
