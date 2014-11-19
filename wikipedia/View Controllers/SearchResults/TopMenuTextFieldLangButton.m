//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchLangSwitcherButton.h"
#import "WikiGlyphLabel.h"
#import "PaddedLabel.h"

@interface SearchLangSwitcherButton()

@property (strong, nonatomic) WikiGlyphLabel *glyphLabel;
@property (strong, nonatomic) PaddedLabel *domainLabel;

@property (nonatomic) BOOL enabled;

@property (strong, nonatomic) NSString *glyphChar;
@property (strong, nonatomic) UIColor *glyphColor;
@property (nonatomic) CGFloat glyphSize;

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) UIColor *domainColor;
@property (nonatomic) CGFloat domainSize;

@end

@implementation SearchLangSwitcherButton

-(void)showGlyph: (NSString *)glyphChar
      glyphColor: (UIColor *)glyphColor
       glyphSize: (CGFloat)glyphSize
          domain: (NSString *)domain
     domainColor: (UIColor *)domainColor
      domainSize: (CGFloat)domainSize
{
    self.domainColor = domainColor;
    self.domainSize = domainSize;
    self.domain = domain;

    self.glyphColor = glyphColor;
    self.glyphSize = glyphSize;
    self.glyphChar = glyphChar;
}


-(void)setGlyphChar:(NSString *)glyphChar
{
    _glyphChar = glyphChar;

    [self.glyphLabel setWikiText: glyphChar
                           color: self.glyphColor
                            size: self.glyphSize
                  baselineOffset: 0];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.enabled = YES;
    self.clipsToBounds = YES;
    self.glyphLabel = [[WikiGlyphLabel alloc] init];
    self.glyphLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    [self addSubview:self.glyphLabel];

    self.domainLabel = [[PaddedLabel alloc] init];
    self.domainLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.domainLabel];

    [self constrainLabels];
}

-(void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.alpha = (enabled) ? 1.0 : 0.2;
    if (enabled) {
        self.accessibilityTraits = self.accessibilityTraits & (~UIAccessibilityTraitNotEnabled);
    } else {
        self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitNotEnabled;
    }
}

-(void)constrainLabels
{
    NSDictionary *metrics = @{
    };
    
    NSDictionary *views = @{
        @"glyphLabel": self.glyphLabel,
        @"domainLabel": self.domainLabel
    };

    NSArray *constraintArrays = @
        [

         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[glyphLabel][domainLabel]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views],

         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[glyphLabel]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views],

         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[domainLabel]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views]

     ];

    [self addConstraints:[constraintArrays valueForKeyPath:@"@unionOfArrays.self"]];

}

@end
