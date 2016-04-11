#import <UIKit/UIKit.h>

static NSString* const WMFZeroBadgeShow = @"WMFZeroBadgeShow";

static NSString* const WMFZeroBadgeHide = @"WMFZeroBadgeHide";

static NSString* const WMFZeroBadgeToggle = @"WMFZeroBadgeToggle";

@interface WMFWindowWithZeroBadge : UIWindow

@property (nonatomic, readonly) BOOL isBadgeVisible;

@end
