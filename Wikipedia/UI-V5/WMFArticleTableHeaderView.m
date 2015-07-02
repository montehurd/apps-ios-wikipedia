//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleTableHeaderView.h"
#import "UIButton+WMFButton.h"
#import "NSString+Extras.h"
#import "PaddedLabel.h"

#import "Wikipedia-Swift.h"
#import "WMFImageInfoController.h"
#import "AnyPromise+WMFExtensions.h"
#import "NSString+Extras.h"

// Note: copied "LeadImageTitleAttributedString.h" from old native lead image code. Will need to clean it up.
#import "LeadImageTitleAttributedString.h"

@interface WMFArticleTableHeaderView ()

@property (strong, nonatomic) IBOutlet UIButton* saveButton;
@property (strong, nonatomic) IBOutlet PaddedLabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView* image;

@end

@implementation WMFArticleTableHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.saveButton wmf_setButtonType:WMFButtonTypeHeart];
}

- (BOOL)isSaved {
    return [self.savedPages isSaved:self.article.title];
}

- (IBAction)toggleSave:(id)sender {
    [self.savedPages toggleSavedPageForTitle:self.article.title];
    [self.savedPages save];
    [self updateSavedButtonState];
}

- (void)updateSavedButtonState {
    self.saveButton.selected = [self isSaved];
}

- (void)updateUIElements {
    [self updateSavedButtonState];

// Note: Not sure why this nil check is needed... Didn't have this problem when the lead image / title was a table cell (vs table header)
    if (self.article.title == nil) {
        return;
    }

    self.titleLabel.attributedText = [LeadImageTitleAttributedString attributedStringWithTitle:[self.article.title.text wmf_stringByRemovingHTML] description:[self.article.entityDescription wmf_stringByCapitalizingFirstCharacter]];

    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]].then(^(UIImage* image){
        self.image.image = image;
    });
}

@end

