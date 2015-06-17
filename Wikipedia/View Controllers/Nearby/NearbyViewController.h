//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PullToRefreshViewController.h"

@interface NearbyViewController : PullToRefreshViewController <UICollectionViewDataSource, UICollectionViewDelegate, CLLocationManagerDelegate, UIActionSheetDelegate, FetchFinishedDelegate>

+ (NearbyViewController*)initialViewControllerFromStoryBoard;

@end
