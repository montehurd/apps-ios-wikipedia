#import "MTLValueTransformer+WMFColorTransformer.h"
@import WMF;

@implementation MTLValueTransformer (WMFColorTransformer)

+ (instancetype)wmf_forwardHexColorTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        unsigned int hexValue;
        if ([value isKindOfClass:[NSString class]] && [value length] > 1 && [value hasPrefix:@"#"] && [[NSScanner scannerWithString:[value substringFromIndex:1]] scanHexInt:&hexValue]) {
            return [UIColor wmf_colorWithHex:hexValue alpha:1.0];
        } else {
            WMFSafeAssign(success, NO);
            WMFSafeAssign(error, [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType userInfo:nil]);
            return nil;
        }
    }];
}

@end
