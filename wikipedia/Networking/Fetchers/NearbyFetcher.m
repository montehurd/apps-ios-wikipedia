//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "NSString+Extras.h"

@interface NearbyFetcher()

@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;

@end

@implementation NearbyFetcher

-(instancetype)initAndFetchNearbyForLatitude: (CLLocationDegrees)latitude
                                   longitude: (CLLocationDegrees)longitude
                                 withManager: (AFHTTPRequestOperationManager *)manager
                          thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.latitude = latitude;
        self.longitude = longitude;

        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSString *url = [SessionSingleton sharedInstance].searchApiUrl;

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        //NSLog(@"responseObject: %@", responseObject);
        //NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        //NSLog(@"responseString: %@", responseString);
        //NSLog(@"response length: %lu", (unsigned long)[responseObject length]);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        
        // Convert the raw NSData response to a dictionary.
        if (![self isDataResponseValid:responseObject]){
            // Fake out an error if bad response received.
            responseObject = @{@"error": @{@"info": @"Nearby data not found."}};
        }else{
            // Should be able to proceed with dictionary conversion.
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonError];
            responseObject = jsonError ? @{} : responseObject;
        }

        //NSLog(@"NEARBY DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Nearby Fetcher"
                                        code: NEARBY_FETCH_ERROR_API
                                    userInfo: errorDict];
        }

        NSMutableArray *output = @[].mutableCopy;
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        if (output.count == 0) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            
            errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"nearby-none", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Nearby Fetcher" code:NEARBY_FETCH_ERROR_NO_RESULTS userInfo:errorDict];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"NEARBY FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    NSString *coords =
        [NSString stringWithFormat:@"%f|%f", self.latitude, self.longitude];
    return @{
             @"action": @"query",
             @"prop": @"coordinates|pageimages|pageterms",
             @"colimit": @"50",
             @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
             @"pilimit": @"50",
             @"wbptterms": @"description",
             @"generator": @"geosearch",
             @"ggscoord": coords,
             @"codistancefrompoint": coords,
             @"ggsradius": @"10000",
             @"ggslimit": @"50",
             @"format": @"json"
             };
}

-(NSMutableArray *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSMutableArray *nearbyResults = @[].mutableCopy;
    NSDictionary *jsonDict = (NSDictionary *)rawResponse;
    
    if (jsonDict.count > 0) {
        NSDictionary *pages = jsonDict[@"query"][@"pages"];
        if (pages) {
            for (NSDictionary *pageId in pages) {
                NSDictionary *page = pages[pageId];
                NSArray *coordsArray = page[@"coordinates"];
                NSDictionary *coords = coordsArray.firstObject;
                NSNumber *pageId = page[@"pageid"];
                NSString *pageImage = page[@"pageimage"];
                NSDictionary *thumbnail = page[@"thumbnail"];
                NSString *title = page[@"title"];

// Temp hack for testing. API is rounding coords.
// This is ok to leave for now, but once the API stops rounding
// coordinates we can remove it. In the mean time, at least
// these 2 items will be 100% accurate for testing :)
if ([title isEqualToString:@"Wikimedia Foundation"]) {
    NSMutableDictionary *mutableCoords = coords.mutableCopy;
    mutableCoords[@"lat"] = @"37.78697";
    mutableCoords[@"lon"] = @"-122.399677";
    coords = mutableCoords;
}else if ([title isEqualToString:@"140 New Montgomery"]) {
    NSMutableDictionary *mutableCoords = coords.mutableCopy;
    mutableCoords[@"lat"] = @"37.787";
    mutableCoords[@"lon"] = @"-122.4";
    coords = mutableCoords;
}
                
                NSMutableDictionary *d = @{}.mutableCopy;

                NSNumber *lat = coords[@"lat"];
                NSNumber *lon = coords[@"lon"];
                if(lat && lon){
                    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue);
                    d[@"coordinate"] = [NSValue value:&coordinates withObjCType:@encode(CLLocationCoordinate2D)];
                }

                NSNumber *dist = coords[@"dist"];
                if(dist)d[@"initialDistance"] = dist;
                if(pageId)d[@"pageid"] = pageId;
                if(pageImage)d[@"pageimage"] = pageImage;
                if(thumbnail)d[@"thumbnail"] = thumbnail;
                if(title)d[@"title"] = title;

                NSString *description = @"";
                NSDictionary *terms = page[@"terms"];
                if(terms && terms[@"description"]){
                    NSArray *descriptions = terms[@"description"];
                    if (descriptions && (descriptions.count > 0)) {
                        description = descriptions[0];
                        description = [description capitalizeFirstLetter];
                    }
                }
                d[@"description"] = description;

                [nearbyResults addObject:d];
            }
        }
    }
    return nearbyResults;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING LOGIN TOKEN FETCHER!");
}
*/

@end
