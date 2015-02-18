//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface SearchResultsController : UIViewController <UITableViewDelegate>

@property (nonatomic, strong, readonly) IBOutlet UITableView *searchResultsTable;

@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSString *searchString;

@property (assign, nonatomic) NSUInteger numberOfResults;
@property (assign, nonatomic) BOOL enableSupplementalFullTextSearch;

-(void)search;
-(void)clearSearchResults;
-(void)saveSearchTermToRecentList;
-(void)doneTapped;

@end
