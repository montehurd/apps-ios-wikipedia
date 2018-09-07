#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/CIDetector+WMFFaceDetection.h>
#import "UIImage+WMFNormalization.h"
#import <WMF/MWKImage.h>
#import <WMF/WMFImageURLParsing.h>

@interface WMFFaceDetectionCache ()

@property (nonatomic, strong) NSCache *faceDetectionBoundsKeyedByURL;

@end

@implementation WMFFaceDetectionCache

- (instancetype)init {
    self = [super init];
    if (self) {
        self.faceDetectionBoundsKeyedByURL = [[NSCache alloc] init];
    }
    return self;
}

+ (WMFFaceDetectionCache *)sharedCache {
    static WMFFaceDetectionCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[WMFFaceDetectionCache alloc] init];
    });
    return sharedCache;
}

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL *)url {
    return ([self faceDetectionBoundsForURL:url] == nil);
}

- (BOOL)imageRequiresFaceDetection:(MWKImage *)imageMetadata {
    return ![imageMetadata didDetectFaces];
}

- (NSValue *)faceBoundsForURL:(NSURL *)url {
    return [[self faceDetectionBoundsForURL:url] firstObject];
}

- (NSValue *)faceBoundsForImageMetadata:(MWKImage *)imageMetadata {
    return [imageMetadata.allNormalizedFaceBounds firstObject];
}

- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU URL:(NSURL *)url failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
    NSArray *savedBounds = [self faceDetectionBoundsForURL:url];
    if (savedBounds) {
        success([savedBounds firstObject]);
    } else {
        [self getFaceBoundsInImage:image
                             onGPU:onGPU
                           failure:failure
                           success:^(NSArray *faceBounds) {
                               [self cacheFaceDetectionBounds:faceBounds forURL:url];
                               success([faceBounds firstObject]);
                           }];
    }
}

- (void)detectFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU imageMetadata:(MWKImage *)imageMetadata failure:(WMFErrorHandler)failure success:(WMFSuccessNSValueHandler)success {
    NSArray *savedBounds = imageMetadata.allNormalizedFaceBounds;
    if (savedBounds) {
        success([savedBounds firstObject]);
    } else {
        [self getFaceBoundsInImage:image
                             onGPU:onGPU
                           failure:failure
                           success:^(NSArray *faceBounds) {
                               imageMetadata.allNormalizedFaceBounds = faceBounds;
                               success([faceBounds firstObject]);
                           }];
    }
}

- (void)getFaceBoundsInImage:(UIImage *)image onGPU:(BOOL)onGPU failure:(WMFErrorHandler)failure success:(WMFSuccessIdHandler)success {
    CIDetector *detector = onGPU ? [CIDetector wmf_sharedGPUFaceDetector] : [CIDetector wmf_sharedCPUFaceDetector];
    [detector wmf_detectFeaturelessFacesInImage:image
                                    withFailure:failure
                                        success:^(NSArray *features) {
                                            NSArray<NSValue *> *faceBounds = [image wmf_normalizeAndConvertBoundsFromCIFeatures:features];
                                            success(faceBounds);
                                        }];
}

#pragma mark - Cache methods

- (void)cacheFaceDetectionBounds:(NSArray *)bounds forURL:(NSURL *)url {
    NSParameterAssert(url);
    if (!url) {
        return;
    }
    if (!bounds) {
        bounds = @[];
    }
    NSLog(@"SET CACHE KEY = %@ bounds = %@", url.absoluteString, bounds);

    NSURL *key = [self keyForURL:url];
    
    [self.faceDetectionBoundsKeyedByURL setObject:bounds forKey:key];
}

- (NSArray *)faceDetectionBoundsForURL:(NSURL *)url {

    NSURL *key = [self keyForURL:url];

    return [self.faceDetectionBoundsKeyedByURL objectForKey:key];
}

- (void)clearCache {
    [self.faceDetectionBoundsKeyedByURL removeAllObjects];
}

// Face bounds are stored as unit rects so no need to recalculate for size variants.
- (NSURL *)keyForURL: (NSURL *)url {
    NSString *imgNameWithoutSizePrefix = WMFParseImageNameFromSourceURL(url.absoluteString);
    if (imgNameWithoutSizePrefix) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@|%@", url.host, imgNameWithoutSizePrefix]];
    }
    return url;
}

@end
