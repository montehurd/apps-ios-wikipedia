
#import "WMFArticleViewController.h"
#import <Masonry/Masonry.h>
#import "WMFArticlePresenter.h"
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "UIButton+WMFButton.h"

#import "WMFArticleTableHeaderView.h"
#import "WMFArticleSectionCell.h"
#import "PaddedLabel.h"
#import "WMFArticleSectionHeaderCell.h"
#import "WMFArticleExtractCell.h"
#import "NSString+Extras.h"

#import "MWKArticle+WMFSharing.h"

@interface WMFArticleViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UIView* cardBackgroundView;
@property (strong, nonatomic) IBOutlet UITableView* table;

@end

@implementation WMFArticleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureForDynamicCellHeight];
}

- (void)configureForDynamicCellHeight {
    self.table.rowHeight                    = UITableViewAutomaticDimension;
    self.table.estimatedRowHeight           = 80;
    self.table.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.table.estimatedSectionHeaderHeight = 80;
}

#pragma mark - Accessors

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

// Note: Not sure why updateHeaderView needs to be in viewWillAppear - seems the card handler needs it? Didn't have this problem when the lead image / title was a table cell (vs table header)
    [self updateHeaderView];
}

- (void)updateHeaderView {
    WMFArticleTableHeaderView* headerView = (WMFArticleTableHeaderView*)self.table.tableHeaderView;
    headerView.savedPages = self.savedPages;
    headerView.article    = self.article;
    [headerView updateUIElements];
}

- (void)setArticle:(MWKArticle*)article {
    if ([_article isEqual:article]) {
        return;
    }

    _article = article;

    NSLog(@"\n");
    NSLog(@"%@", article.title.text);
    NSLog(@"%@", article.entityDescription); //not saved? only seeing it in search results not saved panels
    NSLog(@"%@", article.thumbnailURL);
    NSLog(@"%ld", article.sections.count);

    [self updateHeaderView];

    [self.table reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.article.sections.count - 1;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        static NSString* cellID     = @"WMFArticleExtractCell";
        WMFArticleExtractCell* cell = (WMFArticleExtractCell*)[tableView dequeueReusableCellWithIdentifier:cellID];

        [cell setExtractText:[self.article shareSnippet]];

        return cell;
    } else {
        static NSString* cellID     = @"WMFArticleSectionCell";
        WMFArticleSectionCell* cell = (WMFArticleSectionCell*)[tableView dequeueReusableCellWithIdentifier:cellID];

        cell.level           = self.article.sections[indexPath.row + 1].level;
        cell.titleLabel.text = [self.article.sections[indexPath.row + 1].line wmf_stringByRemovingHTML];

        return cell;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString* cellID           = @"WMFArticleSectionHeaderCell";
    WMFArticleSectionHeaderCell* cell = (WMFArticleSectionHeaderCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    [self configureHeaderCell:cell inSection:section];
    return cell;
}

- (void)configureHeaderCell:(WMFArticleSectionHeaderCell*)cell inSection:(NSInteger)section {
    switch (section) {
        case 0:
            cell.sectionHeaderLabel.text = @"Summary";
            break;
        case 1:
            cell.sectionHeaderLabel.text = @"Table of contents";
            break;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section != 0) {
    }
}

- (IBAction)readButtonTapped:(id)sender {
    // Temp "read" button for debugging
    [[WMFArticlePresenter sharedInstance] presentArticleWithTitle:self.article.title discoveryMethod:MWKHistoryDiscoveryMethodSearch];
}

@end
