#import "WMFWindow.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>

@interface WMFWindow()

@property (nonatomic, strong)UILabel* label;

@end

@implementation WMFWindow

- (void)layoutSubviews {
    [super layoutSubviews];
    //HAX: Needed so transition animations don't go in from of the label.
    [self bringSubviewToFront:self.label];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        //_window.clipsToBounds = YES;
        self.label = [[UILabel alloc] init];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        self.label.backgroundColor = [UIColor redColor];
        self.label.layer.cornerRadius = 3;
        self.label.clipsToBounds = YES;
        [self addSubview:self.label];
        [self bringSubviewToFront:self.label];
        
        
        [self.label mas_makeConstraints:^(MASConstraintMaker* make) {
//            make.leading.and.trailing.equalTo(self.label.superview);
//            make.top.equalTo(self.label.superview.mas_bottom);
            make.leading.and.bottom.equalTo(self.label.superview);
//            make.top.equalTo(self.label.superview.mas_bottom);

        }];
    

//        static CGRect origFrame;
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            origFrame = frame;
//        });

        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]
                                                    queue:nil
                                               usingBlock:^(NSNotification *notif){

                                                   
                                                   if (self.label.text.length == 0){
                                                       [self setBottomAlertText:@"Z"];
                                                   }else{
                                                       [self setBottomAlertText:@""];
                                                   }
                                                   
//                                                   CGFloat height = [self heightForLabel];
//                                                   
//                                                   self.frame = (self.label.text.length == 0) ? origFrame : CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height - (height));

                                                   
                                               }];
         
        
    }
    return self;
}

-(void)setBottomAlertText:(NSString*)text {
    self.label.text = text;
    
//    //self.frame = self.frame;
//    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
//
//
//    NSLayoutConstraint* heightConstraint = [currentWindow.constraints bk_match:^BOOL (NSLayoutConstraint* constraint) {
//        return (constraint.firstAttribute == NSLayoutAttributeBottom);
//    }];
//
//    NSLog(@"heightConstraint = %@", heightConstraint);
//    CGFloat labelHeight = [self heightForLabel];
//    heightConstraint.constant = labelHeight;
//    
//    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

/*
-(void)setFrame:(CGRect)frame {

    static CGFloat lastHeightAdjustment;

    frame = [UIScreen mainScreen].bounds;
    
    CGFloat labelHeight = [self heightForLabel];

    CGFloat heightAdjustment = 0;
    
    heightAdjustment = (self.label.text.length == 0) ? 0 : -labelHeight;
    
    id<UICoordinateSpace> currentCoordSpace = [[UIScreen mainScreen] coordinateSpace];
    id<UICoordinateSpace> portraitCoordSpace = [[UIScreen mainScreen] fixedCoordinateSpace];
    frame = [portraitCoordSpace convertRect:frame toCoordinateSpace:currentCoordSpace];

    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - lastHeightAdjustment + heightAdjustment);

    frame = [currentCoordSpace convertRect:frame toCoordinateSpace:portraitCoordSpace];
    
    lastHeightAdjustment = heightAdjustment;

    NSLog(@"frame = %@", NSStringFromCGRect(frame));

self.bounds = frame;
    
    [super setFrame:frame];
}
*/

- (CGFloat)heightForLabel{
    [self.label setNeedsUpdateConstraints];
    [self.label updateConstraintsIfNeeded];
    [self.label setNeedsLayout];
    [self.label layoutIfNeeded];
    return [self.label systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

@end
