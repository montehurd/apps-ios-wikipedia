//
//  OptionsFooterViewController.m
//  Wikipedia
//
//  Created by Monte Hurd on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "OptionsFooterViewController.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "MWLanguageInfo.h"
#import "WikiGlyph_Chars.h"
#import "WikiGlyphLabel.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"

static const CGFloat kGlyphButtonFontSize = 28.0f;

@interface OptionsFooterViewController ()

@property (nonatomic, weak) IBOutlet WikiGlyphLabel *langGlyphLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel *langLabel;

@property (nonatomic, weak) IBOutlet WikiGlyphLabel *lastModGlyphLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel *lastModLabel;

@end

@implementation OptionsFooterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self roundGlyphButtonCorners];
    
    [self adjustConstraintsScaleForViews:
        @[self.langGlyphLabel, self.langLabel, self.lastModGlyphLabel, self.lastModLabel]];
}

-(void)roundGlyphButtonCorners
{
    self.langGlyphLabel.layer.cornerRadius = self.langGlyphLabel.frame.size.width / 2.0f;
    self.lastModGlyphLabel.layer.cornerRadius = self.langGlyphLabel.frame.size.width / 2.0f;
    self.langGlyphLabel.clipsToBounds = YES;
    self.lastModGlyphLabel.clipsToBounds = YES;
}

-(void)updateLanguageCount:(NSInteger)count
{
    NSString *icon = @"";
    NSString *text = @"";

    if (count > 0) {
        icon = WIKIGLYPH_TRANSLATE;
        text = [NSString localizedStringWithFormat:MWLocalizedString(@"language-button-text", nil), (int)count];
    }

    [self.langGlyphLabel setWikiText: icon
                               color: [UIColor whiteColor]
                                size: kGlyphButtonFontSize * MENUS_SCALE_MULTIPLIER
                      baselineOffset: 2.0];

    self.langLabel.text = text;
    self.langLabel.textColor = [UIColor grayColor];
    self.langGlyphLabel.backgroundColor = self.langLabel.textColor;
}

-(void)updateLastModifiedDate:(NSDate *)date userName:(NSString *)userName
{
    NSString *ts = [WikipediaAppUtils relativeTimestamp:date];
    BOOL isRecent = (fabs([date timeIntervalSinceNow]) < 60*60*24);
    NSString *lm = @"";
    
    if (userName) {
        lm = [[MWLocalizedString(@"lastmodified-by-user", nil)
               stringByReplacingOccurrencesOfString:@"$1" withString:ts]
                stringByReplacingOccurrencesOfString:@"$2" withString:userName];
    } else {
        lm = [MWLocalizedString(@"lastmodified-by-anon", nil)
              stringByReplacingOccurrencesOfString:@"$1" withString:ts];
    }

    [self.lastModGlyphLabel setWikiText: WIKIGLYPH_PENCIL
                                  color: [UIColor whiteColor]
                                   size: kGlyphButtonFontSize * MENUS_SCALE_MULTIPLIER
                         baselineOffset: 2.0];

    self.lastModLabel.text = lm;
    self.lastModLabel.textColor = isRecent ? WMF_COLOR_GREEN : [UIColor grayColor];
    self.lastModGlyphLabel.backgroundColor = self.lastModLabel.textColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
