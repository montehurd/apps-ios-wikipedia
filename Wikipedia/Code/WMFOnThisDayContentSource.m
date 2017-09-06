#import <WMF/WMFOnThisDayContentSource.h>
#import <WMF/WMFOnThisDayEventsFetcher.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFTaskGroup.h>
#import <WMF/EXTScope.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFArticle+Extensions.h>
#import <WMF/WMFFeedOnThisDayEvent.h>
#import <WMF/WMFFeedArticlePreview.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFOnThisDayContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong) WMFOnThisDayEventsFetcher *fetcher;

@end

@implementation WMFOnThisDayContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
    }
    return self;
}

- (WMFOnThisDayEventsFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFOnThisDayEventsFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
}

- (void)stopUpdating {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    if (days < 1) {
        if (completion) {
            completion();
        }
        return;
    }

    NSDate *now = [NSDate date];

    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    WMFTaskGroup *group = [WMFTaskGroup new];

    for (NSUInteger i = 0; i < days; i++) {
        [group enter];
        NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:-i toDate:now options:NSCalendarMatchStrictly];
        [self loadContentForDate:date
            inManagedObjectContext:moc
                             force:force
                        completion:^{
                            [group leave];
                        }];
    }

    [group waitInBackgroundWithCompletion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSURL *siteURL = self.siteURL;

    if (!siteURL) {
        if (completion) {
            completion();
        }
        return;
    }
    [moc performBlock:^{
        NSURL *contentGroupURL = [WMFContentGroup onThisDayContentGroupURLForSiteURL:siteURL midnightUTCDate:date.wmf_midnightUTCDateFromLocalDate];
        WMFContentGroup *existingGroup = [moc contentGroupForURL:contentGroupURL];
        if (existingGroup) {
            if (completion) {
                completion();
            }
            return;
        }

        NSDateComponents *components = [[NSCalendar wmf_gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        NSInteger month = [components month];
        NSInteger day = [components day];
        NSInteger year = [components year];
        @weakify(self)
            [self.fetcher fetchOnThisDayEventsForURL:self.siteURL
                month:month
                day:day
                failure:^(NSError *error) {
                    if (completion) {
                        completion();
                    }
                }
                success:^(NSArray<WMFFeedOnThisDayEvent *> *onThisDayEvents) {
                    @strongify(self);
                    if (onThisDayEvents.count < 1 || !self) {
                        if (completion) {
                            completion();
                        }
                        return;
                    }

                    [moc performBlock:^{
                        [onThisDayEvents enumerateObjectsUsingBlock:^(WMFFeedOnThisDayEvent *_Nonnull event, NSUInteger idx, BOOL *_Nonnull stop) {
                            __block NSInteger countOfImages = 0;
                            [event.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull articlePreview, NSUInteger idx, BOOL *_Nonnull stop) {
                                if (articlePreview.imageURLString) {
                                    countOfImages += 1;
                                }
                                [moc fetchOrCreateArticleWithURL:[articlePreview articleURL] updatedWithFeedPreview:articlePreview pageViews:nil];
                            }];
                            

                            
                            
//NSRegularExpression* enMahemRegex = [NSRegularExpression regularExpressionWithPattern:
//@"\\b(kill(s|ed|ers|ing)?|explosion(s)?|bomb(s|ers|ing|ings|ed)?|slaughter(s|ed|ing)?|massacre(d)?|die|dead|death(s)?|attack(ing|ers|ed)?|murder(s|ing|ers|ed)?|execute(d)?|terror(ist|ism|ize|izing)?|war(s)?|fatal(ity|ly)?|crash(ing|ed)?|battle(d)?|coup|riot(ing|ers|ed|s)?)\\b"
//                                                                       options:NSRegularExpressionCaseInsensitive error:nil];
//NSUInteger mayhemWordCount = [enMahemRegex numberOfMatchesInString:event.text options:0 range: NSMakeRange(0, [event.text length])];
//NSNumber *imageScore = @(@(countOfImages).floatValue * 0.2);
//NSNumber *overallScore = @(imageScore.floatValue - mayhemWordCount);
//event.score = overallScore;
                            event.score = @(countOfImages);
                            event.index = @(idx);
                        }];

                        NSInteger featuredEventIndex = NSNotFound;

                        NSArray *eventsSortedByScore = [onThisDayEvents sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
                        if (eventsSortedByScore.count > 0) {
                            NSInteger index = ((year % 10) % eventsSortedByScore.count);
//NSInteger index = 0;
                            WMFFeedOnThisDayEvent *featuredEvent = eventsSortedByScore[index];

NSLog(@"\n\n%ld-%ld\n%@ - %@\n\n\n", month, day, featuredEvent.year, featuredEvent.text);

                            featuredEventIndex = featuredEvent.index.integerValue;
                        }

                        WMFContentGroup *group = [self onThisDayForDate:date inManagedObjectContext:moc];
                        if (group == nil) {
                            group = [moc createGroupOfKind:WMFContentGroupKindOnThisDay forDate:date withSiteURL:self.siteURL associatedContent:onThisDayEvents];
                            if (featuredEventIndex >= 0 && featuredEventIndex < onThisDayEvents.count) {
                                group.featuredContentIndex = featuredEventIndex;
                            }
                        }

                        if (completion) {
                            completion();
                        }
                    }];

                }];
    }];
}

- (nullable WMFContentGroup *)onThisDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindOnThisDay forDate:date siteURL:self.siteURL];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindOnThisDay];
}

@end

NS_ASSUME_NONNULL_END
