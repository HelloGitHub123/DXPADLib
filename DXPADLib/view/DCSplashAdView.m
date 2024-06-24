//
//  DCSplashAdView.m
//  DITOApp
//
//  Created by 孙全民 on 2022/11/2.
//

#import "DCSplashAdView.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import "DXPADManager.h"
#import "DXPADHeader.h"

@interface DCSplashAdView()
@property (nonatomic, strong) NSTimer *adTimer;
@property (nonatomic, strong) UIView *timerView;
@property (nonatomic, strong) UILabel *timeLbl;
@property (nonatomic, assign) NSInteger adTimeSecond; // 广告时间
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) DCAdPic *adPic;
@property (nonatomic, strong) DCAdDetail *splashAdDetail;
@end
@implementation DCSplashAdView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH_ad, SCREEN_HEIGHT_ad)]) {
        [self configView];
    }
    return self;
}

- (void)configView {
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.screenImg];
    [self.screenImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(@0);
//        make.top.equalTo(@(kDCADSafeTop));
        make.top.equalTo(@0);
        make.bottom.equalTo(@(-kDCADSafeBottom_ad));
    }];
    
    [self addSubview:self.adImgView];
    [self.adImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.equalTo(@0);
    }];
    
    
    [self addSubview:self.timerView];
    [self.timerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(STATUS_BAR_HEIGHT_ad + 10));
        make.trailing.equalTo(@-10);
    }];
}

// 展示开屏广告
- (void)showSplashAD:(DCAdDetail*)splashAdDetail adpic:(DCAdPic*)adPic {
	
	if (splashAdDetail && adPic) {
		self.adPic = adPic;
		self.splashAdDetail = splashAdDetail;
		// 开启定时器
		DCAdExtData *extData = splashAdDetail.extData;
		NSURL *imgUrl = [[NSURL alloc]initWithString:adPic.adImg];
		
		self.adImgView.hidden = NO;
		[self.adImgView sd_setImageWithURL:imgUrl];
		self.timerView.hidden = NO;
		self.timeLbl.text = [NSString stringWithFormat:@"Skip | %ld",extData.displayTime];
		self.adTimeSecond = extData.displayTime;
		// 开始定时器
		self.adTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.adTimer forMode:NSRunLoopCommonModes];
	}

    // 添加手势，因为将开屏layer放在最前面，导致view失去点击事件
    self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAdGesture:)];
    [[UIApplication sharedApplication].keyWindow addGestureRecognizer:self.tapGesture];
}

// MARK: Methods
- (void)updateTime {
    self.adTimeSecond = self.adTimeSecond -1;
    self.timeLbl.text = [NSString stringWithFormat:@"Skip | %ld",self.adTimeSecond];
    if(self.adTimeSecond <=0) {
        [self closeView];
    }
}

- (void)tapAdGesture:(UITapGestureRecognizer*)tap {
    CGPoint panPoint = [tap locationInView:self.timeLbl];
    BOOL tapSkip = CGRectContainsPoint(self.timeLbl.bounds, panPoint);
    if (tapSkip) { // 跳过广告
        [self closeView];
        return;
    }
	// 点击处理回调
	if (self.clickBlock) {
		self.clickBlock(self.adPic);
	}
	
    [self closeView];
}

- (void)closeView {
    [self.adTimer invalidate];
    self.adTimer = nil;
    [self removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:self.tapGesture];
	if (self.closeBlock) {
		self.closeBlock(@"");
	}
}

// MARK: LAZY
- (UIImageView *)screenImg {
    if (!_screenImg) {
        _screenImg = [UIImageView new];
        _screenImg.image = [UIImage imageNamed:@""];
        _screenImg.contentMode =  UIViewContentModeScaleAspectFill;
    }
    return _screenImg;
}
- (UIImageView *)adImgView {
    if (!_adImgView) {
        _adImgView = [[UIImageView alloc]init];
        _adImgView.image = [UIImage imageNamed:@""];
        _adImgView.hidden = YES;
    }
    return _adImgView;
}

- (UIView *)timerView {
    if (!_timerView) {
        _timerView = [UIView new];
        _timerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        
        _timerView.layer.cornerRadius = 11;
        _timerView.hidden = YES;
        UILabel *timeLbl = [UILabel new];
        timeLbl.font = [UIFont systemFontOfSize:14];
        timeLbl.textColor = [self colorWithHexString:@"#333333"];
        self.timeLbl = timeLbl;
        [_timerView addSubview:timeLbl];
        [timeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_timerView).with.insets(UIEdgeInsetsMake(3, 8, 3, 8));
        }];
    }
    return _timerView;
}

- (UIColor*)colorWithHexString:(NSString *)hexString {
	
	NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	
	// String should be 6 or 8 characters
	if ([cString length] < 6) return nil;
	
	// strip 0X if it appears
	if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
	if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
	if ([cString length] != 6 &&[cString length] != 8) return nil;
	
	// Separate into r, g, b substrings
	NSRange range;
	range.location = 0;
	range.length = 2;
	NSString *rString = [cString substringWithRange:range];
	
	range.location = 2;
	NSString *gString = [cString substringWithRange:range];
	
	range.location = 4;
	NSString *bString = [cString substringWithRange:range];
	
	// Scan values
	unsigned int r, g, b,a=255.0;
	[[NSScanner scannerWithString:rString] scanHexInt:&r];
	[[NSScanner scannerWithString:gString] scanHexInt:&g];
	[[NSScanner scannerWithString:bString] scanHexInt:&b];
	if ([cString length] == 8)
	{
		range.location = 6;
		NSString *aString = [cString substringWithRange:range];
		[[NSScanner scannerWithString:aString] scanHexInt:&a];
	}
	
	return [UIColor colorWithRed:((float) r / 255.0f)
						   green:((float) g / 255.0f)
							blue:((float) b / 255.0f)
						   alpha:((float) a / 255.0f)];
}

- (void)dealloc {
    [self closeView];
}



@end
