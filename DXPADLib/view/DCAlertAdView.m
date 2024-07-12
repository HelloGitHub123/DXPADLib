//
//  DCAlertAdView.m
//  DITOApp
//
//  Created by 孙全民 on 2022/10/31.
//

#import "DCAlertAdView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/SDWebImage.h>
#import "DXPADManager.h"
#import "DXPADHeader.h"

@interface DCAlertAdView()

@property (nonatomic, strong) UIImageView *alertImgView;
@property (nonatomic, assign) NSInteger showTimes; //
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) DCAdDetail *adDetail;
@end

@implementation DCAlertAdView

- (instancetype)initWith:(DCAdDetail*)adDetail {
    self.adDetail = adDetail;
    if (self = [self initWithFrame:CGRectZero]) {
        [self configView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH_ad, SCREEN_HEIGHT_ad)]) {
        [self configView];
        [self configData];
    }
    return self;
}

// 配置页面
- (void)configView {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self addSubview:self.alertImgView];
    [self addSubview:self.closeBtn];
    [self.alertImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).offset(-20);
        make.centerX.mas_equalTo(self);
		// make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH - 84, 248));
    }];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.alertImgView.mas_bottom).offset(10);
        make.centerX.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
}

- (void)configData {
    DCAdPic *adPic = [self.adDetail.adPicList firstObject];
	[self.alertImgView sd_setImageWithURL:[NSURL URLWithString:adPic.adImg] placeholderImage:[UIImage imageNamed:@""] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
		CGSize imgSize = image.size;
		[self.alertImgView mas_updateConstraints:^(MASConstraintMaker *make) {
			make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH_ad - 84, (SCREEN_WIDTH_ad - 84) / imgSize.width * imgSize.height));
		}];
	}];
	
}

- (void)showWithADArr:(NSArray *)adList {
    self.showTimes = 1;
}

// 点击事件
- (void)tapAdAction {
    DCAdPic *adPic = [self.adDetail.adPicList firstObject];
	
	if (self.clickBlock) {
		self.clickBlock(adPic);
	}
	
    self.adDetail.showing = NO;
    [self removeFromSuperview];
}

- (void)closeView {
    self.adDetail.showing = NO;
    [self removeFromSuperview];
	if (self.closeBlock) {
		self.closeBlock();
	}
}


// MARK: LAZY
- (UIImageView *)alertImgView {
    if (!_alertImgView) {
        _alertImgView = [UIImageView new];
//        _alertImgView.backgroundColor = [UIColor whiteColor];
        _alertImgView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAdAction)];
        [_alertImgView addGestureRecognizer:tapGesture];
    }
    return _alertImgView;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
        [_closeBtn setBackgroundImage:[UIImage imageNamed:@"ic_close_ad"] forState:UIControlStateNormal];
    }
    return _closeBtn;
}


@end
