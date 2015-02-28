//  Created by Monte Hurd on 3/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface WMFWebViewFooterViewController : UIViewController

@property (strong, nonatomic) NSString *searchString;
@property (strong, nonatomic) NSArray *articlesToExcludeFromResults;
-(void)search;

-(void)updateLanguageCount:(NSInteger)count;
-(void)updateLastModifiedDate:(NSDate *)date userName:(NSString *)userName;

@property (nonatomic, readonly) CGFloat scrollLimitingNativeSubContainerY;

@end
