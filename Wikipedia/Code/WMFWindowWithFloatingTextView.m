#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>

@interface WMFWindowWithFloatingTextView()

@property (nonatomic, strong)UITextView* textView;

@end

@implementation WMFWindowWithFloatingTextView

- (void)layoutSubviews {
    [super layoutSubviews];
    //HAX: Needed so transition animations don't go in from of the label.
    [self bringSubviewToFront:self.textView];
}

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    
    if (self) {

        self.textView = [[UITextView alloc] init];
        self.textView.alpha = 0.8;
        self.textView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.layer.cornerRadius = 3;
        self.textView.font = [UIFont systemFontOfSize:10];
        self.textView.clipsToBounds = YES;

        [self addSubview:self.textView];
        
        [self.textView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.centerX.equalTo(self.textView.superview);
            make.top.equalTo(self.textView.superview).with.offset(2.f);
            make.width.mas_equalTo(220.f);
            make.height.mas_equalTo(320.f);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMessage:) name:WMFFloatingTextViewShowMessage object:nil];

    }
    return self;
}

-(void)showMessage:(NSNotification*)notification {
    NSString* message = [NSString stringWithFormat:@"\n\n%@", notification.object];
    self.textView.text = [self.textView.text stringByAppendingString: message];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
