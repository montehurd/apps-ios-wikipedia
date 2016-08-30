//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class WMFZeroMessage;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFZeroDispositionDidChange;

extern NSString* const ZeroOnDialogShownOnce;
extern NSString* const ZeroWarnWhenLeaving;

@interface ZeroConfigState : NSObject

/**
 *  This is currently unused, as apparently Varnish will figure this out from your IP address.
 */
@property (atomic, copy, nullable) NSString* partnerXCarrier;
@property (atomic, copy, nullable) NSString* partnerXCarrierMeta;

@property (nonatomic, strong, nullable, readonly) WMFZeroMessage* zeroMessage;;

/**
 *  Whether or not the user is on a Wikipedia-Zero-rated network.
 */
@property (atomic) BOOL disposition;

/**
 *  Whether or not the user prefers to see a modal alert before going to a non-zero-rated URL (i.e. off of Wikipedia).
 */
@property (nonatomic) BOOL warnWhenLeaving;

@end

NS_ASSUME_NONNULL_END
