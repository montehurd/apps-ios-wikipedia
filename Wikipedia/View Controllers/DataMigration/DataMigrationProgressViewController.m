
#import "DataMigrationProgressViewController.h"

#import "SessionSingleton.h"

#import "OldDataSchemaMigrator.h"
#import "SchemaConverter.h"

#import "ArticleImporter.h"

#import "WikipediaAppUtils.h"
#import "WMFProgressLineView.h"
#import "ArticleDataContextSingleton.h"

#import <BlocksKit/BlocksKit+UIKit.h>

enum {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
} MigrationButtonIndexIds;

@interface DataMigrationProgressViewController ()<OldDataSchemaMigratorProgressDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) WMFDataMigrationCompletionBlock completionBlock;

@property (nonatomic, strong) SchemaConverter* schemaConvertor;
@property (nonatomic, strong) OldDataSchemaMigrator* oldDataSchema;

@end

@implementation DataMigrationProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.progressLabel.text = MWLocalizedString(@"migration-update-progress-label", nil);
}

- (void)runMigrationWithCompletion:(WMFDataMigrationCompletionBlock)completion {
    self.completionBlock = completion;

    UIAlertView* dialog = [UIAlertView bk_alertViewWithTitle:MWLocalizedString(@"migration-prompt-title", nil) message:MWLocalizedString(@"migration-prompt-message", nil)];

    [dialog bk_setCancelButtonWithTitle:MWLocalizedString(@"migration-skip-button-title", nil) handler:^{
        [self moveOldDataToBackupLocation];
        [self dispatchCOmpletionBlockWithStatus:NO];
    }];
    [dialog bk_addButtonWithTitle:MWLocalizedString(@"migration-confirm-button-title", nil) handler:^{
        [self performMigration];
    }];

    [dialog show];
}

- (void)performMigration {
    if ([self.oldDataSchema exists]) {
        [self runNewMigration];
    }
}

- (OldDataSchemaMigrator*)oldDataSchema {
    if (_oldDataSchema == nil) {
        ArticleDataContextSingleton* context = [ArticleDataContextSingleton sharedInstance];
        _oldDataSchema = [[OldDataSchemaMigrator alloc] initWithDatabasePath:context.databasePath];
    }
    return _oldDataSchema;
}

- (SchemaConverter*)schemaConvertor {
    if (!_schemaConvertor) {
        _schemaConvertor = [[SchemaConverter alloc] initWithDataStore:[SessionSingleton sharedInstance].dataStore];
    }
    return _schemaConvertor;
}

- (BOOL)needsMigration {
    return [self.oldDataSchema exists];
}

- (void)moveOldDataToBackupLocation {
    [self.oldDataSchema moveOldDataToBackupLocation];
}

- (void)removeOldDataBackupIfNeeded {
    [self.oldDataSchema removeOldDataIfOlderThanMaximumGracePeriod];
}

- (void)runNewMigration {
    // Middle-Ages Converter
    // From the native app's initial CoreData-based implementation,
    // which now lives in OldDataSchema subproject.

    self.progressIndicator.progress = 0.0;

    self.oldDataSchema.delegate         = self.schemaConvertor;
    self.oldDataSchema.progressDelegate = self;
    self.oldDataSchema.context          = [[ArticleDataContextSingleton sharedInstance] backgroundContext];
    NSLog(@"begin migration");
    [self.oldDataSchema migrateData];
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total {
    NSString* lineOne = MWLocalizedString(@"migration-update-progress-label", nil);

    NSString* lineTwo = MWLocalizedString(@"migration-update-progress-count-label", nil);

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%lu", (unsigned long)completed]];

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$2" withString:[NSString stringWithFormat:@"%lu", (unsigned long)total]];

    NSString* progressString = [NSString stringWithFormat:@"%@\n%@", lineOne, lineTwo];

    self.progressLabel.text = progressString;

    [self.progressIndicator setProgress:((float)completed / (float)total) animated:YES];
}

- (void)oldDataSchemaDidFinishMigration:(OldDataSchemaMigrator*)schema {
    [[SessionSingleton sharedInstance].userDataStore reset];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES completion:^{
        [self dispatchCOmpletionBlockWithStatus:YES];
    }];
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didFinishWithError:(NSError*)error {
    [self displayErrorCondition];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES completion:^{
        [self dispatchCOmpletionBlockWithStatus:YES];
    }];
}

- (void)displayErrorCondition {
    UIActionSheet* actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Migration failure: submit old data to developers to help diagnose?"];
    [actionSheet bk_setDestructiveButtonWithTitle:@"Discard old data" handler:^{
        [self dispatchCOmpletionBlockWithStatus:NO];
    }];
    [actionSheet bk_addButtonWithTitle:@"Submit to developers" handler:^{
        [self submitDataToDevs];
    }];

    [actionSheet showInView:self.view];
}

- (void)submitDataToDevs {
    MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    picker.subject      = [NSString stringWithFormat:@"Feedback:%@", [WikipediaAppUtils versionedUserAgent]];
    picker.toRecipients = @[@"mobile-ios-wikipedia@wikimedia.org"];

    NSString* filename         = @"articleData6.sqlite";
    NSArray* documentPaths     = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = documentPaths[0];
    NSString* filePath         = [documentRootPath stringByAppendingPathComponent:filename];

    NSData* data = [NSData dataWithContentsOfFile:filePath];
    [picker addAttachmentData:data mimeType:@"application/octet-stream" fileName:filename];

    [picker setMessageBody:@"Attached data file is for internal development testing only." isHTML:NO];

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)dispatchCOmpletionBlockWithStatus:(BOOL)completed {
    if (self.completionBlock) {
        self.completionBlock(completed);
    }
    self.completionBlock = NULL;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dispatchCOmpletionBlockWithStatus:NO];
}

@end
