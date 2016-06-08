//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WKWebView+LoadAssetsHtml.h"
#import "Wikipedia-Swift.h"


























@interface NSString (WMFImageProxy)

- (NSString*)wmf_stringWithLocalhostProxyPrefix;
- (NSString*)wmf_srcsetValueWithLocalhostProxyPrefixes;

@end

@implementation NSString (WMFImageProxy)

- (NSString*)wmf_stringWithLocalhostProxyPrefix {
    
    
    NSString* string = [self copy];
    if ([string hasPrefix:@"https:"]) {
        string = [self wmf_safeSubstringFromIndex:6];
    }
    
    
    return [NSString stringWithFormat:@"http://localhost:8080/imageProxy?originalSrc=%@", [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString*)wmf_srcsetValueWithLocalhostProxyPrefixes {
    NSArray *pairs = [self componentsSeparatedByString:@","];
    NSMutableArray* output = [[NSMutableArray alloc] init];
    for (NSString* pair in pairs) {
        NSString* trimmedPair = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray* parts = [trimmedPair componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (parts.count == 2) {
            NSString* url = parts[0];
            NSString* density = parts[1];
            [output addObject:[NSString stringWithFormat:@"%@ %@", [url wmf_stringWithLocalhostProxyPrefix], density]];
        }else{
            [output addObject:pair];
        }
    }
    return [output componentsJoinedByString:@", "];
}

@end

@interface NSMutableString (WMFImageProxy)

- (void)wmf_replaceImgTagSrcValuesWithLocalhostProxyURLs;

@end

@implementation NSMutableString (WMFImageProxy)

- (void)wmf_replaceImgTagSrcValuesWithLocalhostProxyURLs{
    NSError *error;
    NSString *pattern = @"(<img.+src\\=)(?:\")(.+?)(?:\")(.+?)(\\>)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSInteger offset = 0;
    for (NSTextCheckingResult* result in [regex matchesInString:self
                                                        options:0
                                                          range:NSMakeRange(0, [self length])]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        /*
        NSString* entireTag = [regex replacementStringForResult:result
                                                       inString:self
                                                         offset:offset
                                                       template:@"$0"];
        */
        
        NSString* opener = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$1"];
        
        NSString* srcURL = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$2"];
        
        NSString* other = [regex replacementStringForResult:result
                                                   inString:self
                                                     offset:offset
                                                   template:@"$3"];
        
        NSString* closer = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$4"];
        
        NSMutableString* mutableOther = [other mutableCopy];
        [mutableOther wmf_replaceImgTagSrcsetValuesWithLocalhostProxyURLs];
        
        NSString* replacement = [NSString stringWithFormat:@"%@\"%@\"%@%@",
                                 opener,
                                 [srcURL wmf_stringWithLocalhostProxyPrefix],
                                 mutableOther,
                                 closer
                                 ];
        
        [self replaceCharactersInRange:resultRange withString:replacement];
        
        offset += [replacement length] - resultRange.length;
    }
}

- (void)wmf_replaceImgTagSrcsetValuesWithLocalhostProxyURLs{
    NSError *error;
    NSString *pattern = @"(.+?)(srcset\\=)(?:\")(.+?)(?:\")(.+?)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSInteger offset = 0;
    for (NSTextCheckingResult* result in [regex matchesInString:self
                                                        options:0
                                                          range:NSMakeRange(0, [self length])]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        /*
        NSString* entireTag = [regex replacementStringForResult:result
                                                       inString:self
                                                         offset:offset
                                                       template:@"$0"];
        */
        
        NSString* before = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$1"];
        
        NSString* srcsetKey = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$2"];
        
        NSString* srcsetValue = [regex replacementStringForResult:result
                                                   inString:self
                                                     offset:offset
                                                   template:@"$3"];
        
        NSString* after = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$4"];
        
        
        NSString* replacement = [NSString stringWithFormat:@"%@%@\"%@\"%@",
                                 before,
                                 srcsetKey,
                                 [srcsetValue wmf_srcsetValueWithLocalhostProxyPrefixes],
                                 after
                                 ];
        
        [self replaceCharactersInRange:resultRange withString:replacement];
        
        offset += [replacement length] - resultRange.length;
    }
}

@end

/*
 
- problem? all images now routed to sd web image cache, but it doesn't seem to hangle svgs... the tiny tangent math images...
  (cold start w/o internet connection)
 
*/

























@implementation WKWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment {
    [self loadFileURLFromPath:[[self getAssetsPath] stringByAppendingPathComponent:fileName] scrolledToFragment:fragment];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment topPadding:(NSUInteger)topPadding {
    if (!string) {
        string = @"";
    }

    
    
    
    
    NSMutableString* mutableString = [string mutableCopy];
    [mutableString wmf_replaceImgTagSrcValuesWithLocalhostProxyURLs];
    string = mutableString;
    
    
    
    
/*
// http://stackoverflow.com/a/8058771/135557
string = [string stringByReplacingOccurrencesOfString:@" srcset=" withString:@" wmf_useLocalhost_srcset="];
string = [string stringByReplacingOccurrencesOfString:@" src=" withString:@" wmf_useLocalhost_src="];
*/

    
    
    
    
    

    NSString* path = [[self getAssetsPath] stringByAppendingPathComponent:fileName];

    NSString* fileContents = [NSMutableString stringWithContentsOfFile:path
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];

    NSNumber* fontSize   = [[NSUserDefaults standardUserDefaults] wmf_readingFontSize];
    NSString* fontString = [NSString stringWithFormat:@"%ld%%", fontSize.integerValue];

    NSAssert([fileContents componentsSeparatedByString:@"%@"].count == (3 + 1), @"\nHTML template file does not have required number of percent-ampersand occurences (3).\nNumber of percent-ampersands must match number of values passed to  'stringWithFormat:'");

    // index.html and preview.html have three "%@" subsitition markers. Replace both of these with actual content.
    NSString* templateAndContent = [NSString stringWithFormat:fileContents, fontString, @(topPadding), string];

    // Get temp file name. For a fileName of "index.html" the temp file name would be "index.temp.html"
    NSString* tempFileName = [[[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"temp"] stringByAppendingPathExtension:[fileName pathExtension]];

    // Get path to tempFileName
    NSString* tempFilePath = [[[NSURL fileURLWithPath:path] URLByDeletingLastPathComponent] URLByAppendingPathComponent:tempFileName isDirectory:NO].absoluteString;

    // Remove "file://" from beginning of tempFilePath
    tempFilePath = [tempFilePath substringFromIndex:7];

    NSError* error = nil;
    [templateAndContent writeToFile:tempFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        [self loadFileURLFromPath:tempFilePath scrolledToFragment:fragment];
    } else {
        NSAssert(NO, @"\nTemp file could not be written: \n%@\n", tempFilePath);
    }
}

- (void)loadFileURLFromPath:(NSString*)filePath scrolledToFragment:(NSString*)fragment {
    // TODO: add iOS 8 fallback here...

    if (!fragment) {
        fragment = @"";
    }

    NSAssert([fragment rangeOfString:@" "].location == NSNotFound, @"Fragment cannot contain spaces before it is passed to 'fileURLWithPath:'!");
    fragment = [fragment stringByReplacingOccurrencesOfString:@" " withString:@"_"];

    // Attach hash fragment to file url. http://stackoverflow.com/a/7218674/135557
    // This, in combination with "loadFileURL:", will cause the web view to load
    // automatically scrolled to "fragment" section.
    NSURL* fileUrlWithHashFragment =
        [NSURL URLWithString:[[[NSURL fileURLWithPath:filePath].absoluteString stringByAppendingString:@"#"] stringByAppendingString:fragment]];

    [self loadFileURL:fileUrlWithHashFragment allowingReadAccessToURL:[fileUrlWithHashFragment URLByDeletingLastPathComponent]];
}

- (NSString*)getAssetsPath {
    NSArray* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

@end