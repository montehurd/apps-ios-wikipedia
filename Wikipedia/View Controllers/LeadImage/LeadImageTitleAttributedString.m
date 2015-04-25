//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageTitleAttributedString.h"
#import "Defines.h"
#import "NSString+Extras.h"

static NSString* const kFont = @"Times New Roman";

static CGFloat const kFontSizeTitle       = 34.0f;
static CGFloat const kFontSizeDescription = 17.0f;

static CGFloat const kLineSpacingTitle       = 0.0f;
static CGFloat const kLineSpacingDescription = 2.0f;

static CGFloat const kSpacingAboveDescription = 4.0f;

static NSString* const kHTMLFormatString = @"<span style='font-family:%@;font-size:%f;'>%@</span>%@";

@implementation LeadImageTitleAttributedString

+ (NSAttributedString*)attributedStringWithTitle:(NSString*)title
                                     description:(NSString*)description {
    CGFloat adjustedTitleFontSize = [self getTitleFontSizeForTitleOfLength:title.length];

    NSMutableAttributedString* attributedTitle = nil;
    NSAttributedString* attributedDescription  = nil;
    BOOL isIOS6                                = (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1);

    if (isIOS6) {
        title = [title getStringWithoutHTML];
        if (description.length > 0) {
            title = [title stringByAppendingString:@"\n"];
        }
        NSMutableDictionary* titleAttribs = [self titleAttribs].mutableCopy;
        titleAttribs[NSFontAttributeName] = [UIFont fontWithName:kFont size:adjustedTitleFontSize];
        attributedTitle                   = [[NSAttributedString alloc] initWithString:title attributes:titleAttribs].mutableCopy;
    } else {
        // Set font and size via html span *not* via NSFontAttributeName. This is so we can apply
        // titleAttribs after creating attributed string via NSHTMLTextDocumentType *without* blasting
        // any substring italic styling resulting from that NSHTMLTextDocumentType parsing.
        // Reminder: setting NSFontAttributeName resets any substring italic font attributes.
        title = [NSString stringWithFormat:kHTMLFormatString, kFont, adjustedTitleFontSize, title, (description.length > 0) ? @"<br>" : @""];
        NSError* error = nil;
        attributedTitle =
            [[NSAttributedString alloc] initWithData:[title dataUsingEncoding:NSUTF8StringEncoding]
                                             options:@{
                 NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                 NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
             }
                                  documentAttributes:nil
                                               error:&error].mutableCopy;

        [attributedTitle addAttributes:[self titleAttribs] range:NSMakeRange(0, attributedTitle.length)];
    }

    NSMutableAttributedString* output = attributedTitle;

    if (description.length > 0) {
        attributedDescription = [[NSAttributedString alloc] initWithString:description attributes:[self descAttribs]];
        [output appendAttributedString:attributedDescription];
    }

    return output;
}

+ (NSShadow*)shadow {
    static NSShadow* shadow = nil;
    if (!shadow) {
        CGFloat shadowBlurRadius = 0.5;
        shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:CGSizeMake(0.0, 1.0)];
        [shadow setShadowBlurRadius:shadowBlurRadius];
    }
    return shadow;
}

+ (NSMutableParagraphStyle*)titleParagraphStyle {
    static NSMutableParagraphStyle* style = nil;
    if (!style) {
        style             = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = kLineSpacingTitle * MENUS_SCALE_MULTIPLIER;
    }
    return style;
}

+ (NSMutableParagraphStyle*)descParagraphStyle {
    static NSMutableParagraphStyle* style = nil;
    if (!style) {
        style                        = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing            = kLineSpacingDescription * MENUS_SCALE_MULTIPLIER;
        style.paragraphSpacingBefore = kSpacingAboveDescription * MENUS_SCALE_MULTIPLIER;
    }
    return style;
}

+ (NSDictionary*)titleAttribs {
    static NSDictionary* attribs = nil;
    if (!attribs) {
        attribs = @{
            NSShadowAttributeName: [self shadow],
            NSParagraphStyleAttributeName: [self titleParagraphStyle]
        };
    }
    return attribs;
}

+ (NSDictionary*)descAttribs {
    static NSDictionary* attribs = nil;
    if (!attribs) {
        attribs = @{
            NSShadowAttributeName: [self shadow],
            NSFontAttributeName: [UIFont fontWithName:kFont size:kFontSizeDescription * MENUS_SCALE_MULTIPLIER],
            NSParagraphStyleAttributeName: [self descParagraphStyle]
        };
    }
    return attribs;
}

+ (CGFloat)getTitleFontSizeForTitleOfLength:(NSUInteger)length {
    CGFloat titleFontSizeMultiplier = [self getSizeReductionMultiplierForTitleOfLength:length];
    return floor(kFontSizeTitle * MENUS_SCALE_MULTIPLIER * titleFontSizeMultiplier);
}

+ (CGFloat)getSizeReductionMultiplierForTitleOfLength:(NSUInteger)length {
    // Quick hack for shrinking long titles in rough proportion to their length.

    CGFloat multiplier = 1.0f;

    // Assume roughly title 28 chars per line. Note this doesn't take in to account
    // interface orientation, which means the reduction is really not strictly
    // in proportion to line count, rather to string length. This should be ok for
    // now. Search for "lopado" and you'll see an insanely long title in the search
    // results, which is nice for testing, and which this seems to handle.
    // Also search for "list of accidents" for lots of other long title articles,
    // many with lead images.

    CGFloat charsPerLine = 28;
    CGFloat lines        = ceil(length / charsPerLine);

    // For every 2 "lines" (after the first 2) reduce title text size by 10%.
    if (lines > 2) {
        CGFloat linesAfter2Lines = lines - 2;
        multiplier = 1.0f - (linesAfter2Lines * 0.1f);
    }

    // Don't shrink below 60%.
    return MAX(multiplier, 0.6f);
}

@end
