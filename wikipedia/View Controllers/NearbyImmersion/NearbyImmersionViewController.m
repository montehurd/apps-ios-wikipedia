//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyImmersionViewController.h"
#import "NearbyFetcher.h"
#import "QueuesSingleton.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "NSString+Extras.h"
#import <MapKit/MapKit.h>
#import "Defines.h"
#import "NSString+Extras.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface NearbyImmersionViewController ()

@property (strong, nonatomic) NSArray *nearbyDataArray;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *deviceLocation;
@property (strong, nonatomic) CLHeading *deviceHeading;
@property (nonatomic) BOOL headingAvailable;
@property (nonatomic) BOOL refreshNeeded;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation NearbyImmersionViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.headingAvailable = [CLLocationManager headingAvailable];
        self.deviceLocation = nil;
        self.deviceHeading = nil;
        self.nearbyDataArray = @[@[]];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.activityType = CLActivityTypeFitness;
        self.refreshNeeded = YES;

        // Needed by iOS 8.
        SEL selector = NSSelectorFromString(@"requestWhenInUseAuthorization");
        if ([self.locationManager respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[self.locationManager class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:self.locationManager];
            [invocation invoke];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.locationManager.delegate = self;

    self.locationManager.headingFilter = 1.5;
    self.locationManager.distanceFilter = 1.0;

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
}

-(void)viewDidAppear:(BOOL)animated
{

    [self.locationManager startUpdatingLocation];
    if (self.headingAvailable) {
        [self.locationManager startUpdatingHeading];
    }

}

-(void)hide
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.locationManager stopUpdatingLocation];

    if (self.headingAvailable) {
        [self.locationManager stopUpdatingHeading];
    }

    [[QueuesSingleton sharedInstance].nearbyFetchManager.operationQueue cancelAllOperations];

    [super viewWillDisappear:animated];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[NearbyFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:{
                
                //[self showAlert:MWLocalizedString(@"nearby-loaded", nil) type:ALERT_TYPE_TOP duration:-1];
                [self fadeAlert];
                
                self.nearbyDataArray = @[fetchedData];

                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"initialDistance"
                                                                               ascending: YES];
                NSArray *arraySortedByDistance = [self.nearbyDataArray[0] sortedArrayUsingDescriptors:@[sortDescriptor]];
                self.nearbyDataArray = @[arraySortedByDistance];
                
                [self setupNearbyItemViews];
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
                NSLog(@"nearby op error = %@", error);
                //[self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
            case FETCH_FINAL_STATUS_FAILED:
                NSLog(@"nearby op error = %@", error);
                [self showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
                break;
        }
    }
}

-(void)downloadData
{
    [self showAlert:MWLocalizedString(@"nearby-loading", nil) type:ALERT_TYPE_TOP duration:-1];

    [[QueuesSingleton sharedInstance].nearbyFetchManager.operationQueue cancelAllOperations];

    (void)[[NearbyFetcher alloc] initAndFetchNearbyForLatitude: self.deviceLocation.coordinate.latitude
                                                     longitude: self.deviceLocation.coordinate.longitude
                                                   withManager: [QueuesSingleton sharedInstance].nearbyFetchManager
                                            thenNotifyDelegate: self];
}

- (void)locationManager: (CLLocationManager *)manager
	 didUpdateLocations: (NSArray *)locations
{
    if (locations.count == 0) return;
    
    self.deviceLocation = locations[0];

    if (self.refreshNeeded) {
        [self downloadData];
        self.refreshNeeded = NO;
    }else{
        [self updateDistancesAndAnglesOfRowData];
        [self updateNearbyItemViews];
    }  
}

- (void)locationManager: (CLLocationManager *)manager
       didUpdateHeading: (CLHeading *)newHeading
{
    self.deviceHeading = newHeading;

    [self updateDistancesAndAnglesOfRowData];
    [self updateNearbyItemViews];
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *errorMessage = MWLocalizedString(@"nearby-location-general-error", nil); //error.localizedDescription;

    switch (error.code) {
        case kCLErrorDenied:
            errorMessage = [NSString stringWithFormat:@"\n%@\n\n%@\n\n%@\n\n",
                            MWLocalizedString(@"nearby-location-updates-denied", nil),
                            MWLocalizedString(@"nearby-location-updates-enable", nil),
                            MWLocalizedString(@"nearby-location-updates-settings-menu", nil)];
            break;
        default:
            break;
    }
    
    [self showAlert:errorMessage type:ALERT_TYPE_TOP duration:-1];
}

-(void)setupNearbyItemViews
{
    NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
    if (!rowsData || (rowsData.count == 0)) return;
    for (NSMutableDictionary *rowData in rowsData.copy){
        UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){{0,0},{320,80}}];
        label.alpha = 0.8;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.backgroundColor = [UIColor whiteColor];
        label.hidden = YES;
        label.text = rowData[@"title"];
        rowData[@"itemView"] = label;
        [self.view addSubview:label];
    }
}

-(void)updateNearbyItemViews
{
    NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
    if (!rowsData || (rowsData.count == 0)) return;
    for (NSMutableDictionary *rowData in rowsData.copy){
        UILabel *label = rowData[@"itemView"];
        label.hidden = NO;
        
        NSNumber *distanceNumber = rowData[@"distance"];
        NSNumber *angleNumber = rowData[@"angle"];

        CLLocationDistance distance = distanceNumber.doubleValue;
        double angle = angleNumber.doubleValue;
        
        // Account for 90º (π/2) offset and get opposite/adjacent vectors
        float depth = sin(angle - M_PI_2) * distance;
        float side = cos(angle - M_PI_2) * distance;
        
        CATransform3D transform = CATransform3DIdentity;
        
        label.layer.anchorPoint = CGPointMake(0.5, 0.5);
        
        transform.m34 = 1.0 / -500;
        transform = CATransform3DScale(transform, 0.75, 0.75, 0.75);
        // -200 is the initial depth, then moves back given the distance
        transform = CATransform3DTranslate(transform, side * 10, 60.0, -200 + (depth * 2));
        // Reverse rotation about the y-axis
        transform = CATransform3DRotate(transform, angle, 0.0, -1.0, 0.0);
        
        label.layer.transform = transform;
        [label setNeedsDisplay];
    }
}

-(void)updateDistancesAndAnglesOfRowData
{
    // Keep this as fast as possible. Needs to update distances and angles for
    // *all* row data items so we can do an immersive presentation of nearby
    // items. For an immersive layout we determine what's visible based on the
    // distance and angle of the item relative to the user, so having these at
    // the ready in the rowData makes things much easier.

    NSMutableDictionary *rowsData = (NSMutableDictionary *)self.nearbyDataArray[0];
    if (!rowsData || (rowsData.count == 0)) return;
    for (NSMutableDictionary *rowData in rowsData.copy){

        NSValue *coordVal = rowData[@"coordinate"];
        CLLocationCoordinate2D coord = [self getCoordinateFromNSValue:coordVal];

        CLLocationDistance distance = [self getDistanceToCoordinate:coord];
        rowData[@"distance"] = @(distance);

        double angle = [self getAngleToCoordinate:coord];
        rowData[@"angle"] = @(angle);
    }
}

-(CLLocationCoordinate2D)getCoordinateFromNSValue:(NSValue *)value
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(0, 0);
    if(value)[value getValue:&coord];
    return coord;
}

-(CLLocationDistance)getDistanceToCoordinate:(CLLocationCoordinate2D)coord
{
    CLLocation *articleLocation =
        [[CLLocation alloc] initWithLatitude: coord.latitude
                                   longitude: coord.longitude];
    
    return [self.deviceLocation distanceFromLocation:articleLocation];
}

-(double)getAngleToCoordinate:(CLLocationCoordinate2D)coord
{
    return [self getAngleFromLocation: self.deviceLocation.coordinate
                           toLocation: coord
                     adjustForHeading: self.deviceHeading.trueHeading
                 adjustForOrientation: self.interfaceOrientation];
}

-(double)headingBetweenLocation: (CLLocationCoordinate2D)loc1
                    andLocation: (CLLocationCoordinate2D)loc2
{
    // From: http://www.movable-type.co.uk/scripts/latlong.html
	double dy = loc2.longitude - loc1.longitude;
	double y = sin(dy) * cos(loc2.latitude);
	double x = cos(loc1.latitude) * sin(loc2.latitude) - sin(loc1.latitude) * cos(loc2.latitude) * cos(dy);
	return atan2(y, x);
}

-(double)getAngleFromLocation: (CLLocationCoordinate2D)fromLocation
                   toLocation: (CLLocationCoordinate2D)toLocation
             adjustForHeading: (CLLocationDirection)deviceHeading
         adjustForOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    // Get angle between device and article coordinates.
    double angleRadians = [self headingBetweenLocation:fromLocation andLocation:toLocation];

    // Adjust for device rotation (deviceHeading is in degrees).
    double angleDegrees = RADIANS_TO_DEGREES(angleRadians);
    angleDegrees -= deviceHeading;

    if (angleDegrees > 360.0) {
        angleDegrees -= 360.0;
    }else if (angleDegrees < 0.0){
        angleDegrees += 360.0;
    }

    // Adjust for interface orientation.
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            angleDegrees += 90.0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angleDegrees -= 90.0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angleDegrees += 180.0;
            break;
        default: //UIInterfaceOrientationPortrait
            break;
    }

    //NSLog(@"angle = %f", angleDegrees);

    return DEGREES_TO_RADIANS(angleDegrees);
}

@end
