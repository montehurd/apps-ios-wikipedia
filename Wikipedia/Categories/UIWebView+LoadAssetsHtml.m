//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+LoadAssetsHtml.h"

@implementation UIWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString*)fileName {
    NSString* filePath = [[self getAssetsPath] stringByAppendingPathComponent:fileName];
    NSData* fileData   = [[NSFileManager defaultManager] contentsAtPath:filePath];

    [self loadData:fileData
             MIMEType:@"text/html"
     textEncodingName:@"UTF-8"
              baseURL:[NSURL URLWithString:filePath]];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName leadImageHeight:(NSNumber *)leadImageHeight{
    if (!string) {
        string = @"";
    }

    NSString* path = [[self getAssetsPath] stringByAppendingPathComponent:fileName];

    NSString* fileContents =
        [NSString stringWithContentsOfFile:path
                                         encoding:NSUTF8StringEncoding
                                            error:nil];

NSLog(@"leadImageHeight = %@", leadImageHeight);

    fileContents = [NSString stringWithFormat:fileContents, leadImageHeight, string];

    [self loadHTMLString:fileContents
                 baseURL:[NSURL URLWithString:path]];
}

- (NSString*)getAssetsPath {
    NSArray* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

@end
