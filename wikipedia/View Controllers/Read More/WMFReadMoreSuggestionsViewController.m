//
//  WMFReadMoreSuggestionsViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 2/18/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFReadMoreSuggestionsViewController.h"

static CGFloat const kWMFReadMoreNumberOfArticles = 3;

@implementation WMFReadMoreSuggestionsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.numberOfResults = kWMFReadMoreNumberOfArticles;
        self.enableSupplementalFullTextSearch = YES;
    }
    return self;
    
}

- (void)awakeFromNib{
    
    [super awakeFromNib];
    self.numberOfResults = kWMFReadMoreNumberOfArticles;
    self.enableSupplementalFullTextSearch = YES;
}

@end
