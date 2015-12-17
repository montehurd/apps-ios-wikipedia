
#import <Foundation/Foundation.h>
@class MWKTitle, MWKSearchResult;

@interface WMFTitlesSearchResults : NSObject

@property (nonatomic, strong, readonly) NSArray<MWKTitle*>* titles;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult*>* results;

- (instancetype)initWithTitles:(NSArray<MWKTitle*>*)titles results:(NSArray*)results;

@end
