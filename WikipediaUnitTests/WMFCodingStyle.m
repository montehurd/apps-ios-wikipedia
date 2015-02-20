// WMFCodingStyle.h

#import <Foundation/Foundation.h>

extern NSString* const WMFCodingStyleConstant;

typedef NS_ENUM (NSInteger, WMFCodingStyle) {
    WMFCodingStyleDefault = 0,
    WMFCodingStyleValue = 1
};

extern NSString* WMFCodingStyleAsString(WMFCodingStyle style);

@interface WMFCodingStyleModel : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString* modelIdentifier;

@property (nonatomic, readonly) WMFCodingStyle codingStyle;
@property (nonatomic, readonly) NSString* codingStyleString;

- (instancetype)initWithModelIdentifier:(NSString*)modelIdentifier
                            codingStyle:(WMFCodingStyle)codingStyle;

- (BOOL)isEqualToCodingStyleModel:(WMFCodingStyleModel*)otherModel;

- (NSString*)codingStyleDefaultString;

@end

// WMFCodingStyle.m

NSString* const WMFCodingStyleConstant = @"WMFCodingStyleConstant";

NSString* WMFCodingStyleAsString(WMFCodingStyle style) {
    switch (style) {
        case WMFCodingStyleDefault: {
            return @"default";
        }
        case WMFCodingStyleValue: {
            return @"value";
        }
    }
}

@implementation WMFCodingStyleModel

- (instancetype)initWithModelIdentifier:(NSString*)modelIdentifier
                            codingStyle:(WMFCodingStyle)codingStyle {
    self = [super init];
    if (self) {
        _modelIdentifier = [modelIdentifier copy];
        _codingStyle = codingStyle;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    }
    else if ([other isKindOfClass:[WMFCodingStyleModel class]]) {
        return [self isEqualToCodingStyleModel:other];
    }
    else {
        return NO;
    }
}

- (BOOL)isEqualToCodingStyleModel:(WMFCodingStyleModel*)other {
    return self.modelIdentifier == other.modelIdentifier && [self.modelIdentifier isEqualToString:other.modelIdentifier]
           && self.codingStyle == other.codingStyle;
}

- (NSString*)codingStyleDefaultString {
    return WMFCodingStyleAsString(self.codingStyle);
}

- (instancetype)copyWithZone:(NSZone*)zone {
    return [[[self class] allocWithZone:zone] initWithModelIdentifier:self.modelIdentifier
                                                          codingStyle:self.codingStyle];
}

@end

