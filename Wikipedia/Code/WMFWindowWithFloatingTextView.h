#import <UIKit/UIKit.h>

// usage:
// [[NSNotificationCenter defaultCenter] postNotificationName:WMFFloatingTextViewShowMessage object:@"test message"];

static NSString* const WMFFloatingTextViewShowMessage = @"WMFFloatingTextViewShowMessage";

@interface WMFWindowWithFloatingTextView : UIWindow

@end
