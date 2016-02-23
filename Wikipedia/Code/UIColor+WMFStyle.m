
#import "UIColor+WMFStyle.h"
#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMFStyle)

+ (instancetype)wmf_summaryTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.118 green:0.118 blue:0.118 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_licenseTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x565656 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_licenseLinkColor {
    return [self wmf_blueTintColor];
}

+ (instancetype)wmf_lightGrayColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.870588 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderLightGrayColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.975 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageTintColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.96 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_articleListBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xEAECF0 alpha:1.0];
        ;
    });
    return c;
}

+ (instancetype)wmf_articleBackgroundColor {
    return [self wmf_articleListBackgroundColor];
}

+ (instancetype)wmf_tableOfContentsHeaderTextColor {
    return [self wmf_tableOfContentsSectionTextColor];
}

+ (instancetype)wmf_tableOfContentsSelectionBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.929 green:0.929 blue:0.929 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.192 green:0.334 blue:0.811 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSectionTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSubsectionTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_exploreSectionHeaderTitleColor {
    return [UIColor wmf_customGray];
}

+ (instancetype)wmf_exploreSectionHeaderSubTitleColor {
    return [UIColor wmf_customGray];
}

+ (instancetype)wmf_exploreSectionFooterTextColor {
    return [self wmf_customGray];
}

+ (instancetype)wmf_exploreSectionHeaderIconTintColor {
    return [UIColor wmf_colorWithHex:0x9CA1A7 alpha:1.0];
}

+ (instancetype)wmf_exploreSectionHeaderIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xF5F5F5 alpha:1.0];
}

+ (instancetype)wmf_exploreSectionHeaderLinkTextColor {
    return [self wmf_blueTintColor];
}

+ (instancetype)wmf_blueTintColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithHue:0.611 saturation:0.75 brightness:0.8 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_lightBlueTintColor {
    return [UIColor colorWithRed:0.92 green:0.95 blue:1.0 alpha:1.0];
}

+ (instancetype)wmf_tapHighlightColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:238.0f / 255.0f green:238.0f / 255.0f blue:238.0f / 255.0f alpha:1];
    });
    return c;
}

+ (instancetype)wmf_nearbyArrowColor {
    return [UIColor blackColor];
}

+ (instancetype)wmf_nearbyTickColor {
    return [UIColor wmf_999999Color];
}

+ (instancetype)wmf_nearbyTitleColor {
    return [UIColor blackColor];
}

+ (instancetype)wmf_nearbyDescriptionColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x666666 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_nearbyDistanceBackgroundColor {
    return [UIColor wmf_colorWithHex:0xAAAAAA alpha:1.0];
}

+ (instancetype)wmf_999999Color {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x999999 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_customGray {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x9AA0A7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_readerWGray {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x444444 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_nearbyDistanceTextColor {
    return [UIColor whiteColor];
}

+ (instancetype)wmf_emptyGrayTextColor {
    return [self wmf_999999Color];
}

+ (instancetype)wmf_settingsBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    });
    return c;
}

- (instancetype)wmf_copyWithAlpha:(CGFloat)alpha {
    CGFloat r, g, b, _;
    [self getRed:&r green:&g blue:&b alpha:&_];
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

- (instancetype)wmf_colorByApplyingDim {
    // NOTE(bgerstle): 0.6 is hand-tuned to roughly match UIImageView's default tinting amount
    return [self wmf_colorByScalingComponents:0.6];
}

- (instancetype)wmf_colorByScalingComponents:(CGFloat)amount {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r * amount green:g * amount blue:b * amount alpha:a];
}

+ (instancetype)wmf_green {
    static UIColor* c = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x00AF89 alpha:1.0];
    });
    return c;
}

@end
