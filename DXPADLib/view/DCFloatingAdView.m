//
//  DCFloatingAdView.m
//  DITOApp
//
//  Created by 孙全民 on 2022/10/27.
//

#import "DCFloatingAdView.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>
#import "DXPADManager.h"
#import "DXPADHeader.h"

@interface DCFloatingAdView()

@property (nonatomic, strong) DCAdDetail *adDetail;
@property (nonatomic, strong) UIImageView *floatImgView;
@property (nonatomic, strong) UIButton *closeBtn;
@end


@implementation DCFloatingAdView
- (instancetype)initWith:(DCAdDetail*)adDetail {
    self.adDetail = adDetail;
    if (self = [self initWithFrame:CGRectZero]) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectMake(SCREEN_WIDTH_ad -50, SCREEN_HEIGHT_ad - 300,50 ,80)]) {
        [self configView];
    }
    return self;
}

- (void)configView {
    if ([@"Y" isEqualToString:self.adDetail.extData.drageFlag]) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(changeLocation:)];
        [self addGestureRecognizer:pan];
    }
    self.backgroundColor = [UIColor clearColor];
 
    [self addSubview:self.floatImgView];
    [self.floatImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.equalTo(@0);
        make.height.equalTo(@50);
    }];
    
    [self addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.floatImgView.mas_bottom).offset(10);
        make.centerX.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];
    
    
    DCAdPic *adPic = [self.adDetail.adPicList firstObject];
    [self.floatImgView sd_setImageWithURL:[NSURL URLWithString:adPic.adImg]];
    
}

// MARK: 事件
- (void)tapAdAction {
    DCAdPic *adPic = [self.adDetail.adPicList firstObject];
//    [DXPADManager adJumpWithPic:adPic];
	if (self.clickBlock) {
		self.clickBlock();
	}
    self.adDetail.showing = NO;
}

- (void)closeView {
    self.adDetail.showing = NO;
    [self removeFromSuperview];
}


- (void)changeLocation:(UIPanGestureRecognizer *)pan {
    CGPoint panPoint = [pan locationInView:[self superview]];
    if(pan.state == UIGestureRecognizerStateBegan) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeStatus) object:nil];
    }
    if(pan.state == UIGestureRecognizerStateChanged) {
        self.center = CGPointMake(panPoint.x, panPoint.y);
    } else if(pan.state == UIGestureRecognizerStateEnded){
        if (panPoint.x <= SCREEN_WIDTH_ad/2) {
            if(panPoint.y <= 40 + SMALLHEIGHT_ad/2 && panPoint.x >= 20 + SMALLWIDTH_ad/2){
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(panPoint.x, SMALLHEIGHT_ad/2);
                }];
            } else if(panPoint.y >= SCREEN_HEIGHT_ad - SMALLHEIGHT_ad/2 - 40 && panPoint.x >= 20 + SMALLWIDTH_ad/2){
                
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(panPoint.x, SCREEN_HEIGHT_ad - SMALLHEIGHT_ad/2);
                }];
            } else if (panPoint.x < SMALLWIDTH_ad/2+20 && panPoint.y > SCREEN_HEIGHT_ad-SMALLHEIGHT_ad/2) {
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(SMALLWIDTH_ad/2, SCREEN_HEIGHT_ad-SMALLHEIGHT_ad/2);
                }];
            }else {
                CGFloat pointy = panPoint.y < SMALLHEIGHT_ad/2 ? SMALLHEIGHT_ad/2 :panPoint.y;
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(SMALLWIDTH_ad/2, pointy);
                }];
            }
        }else if(panPoint.x > SCREEN_WIDTH_ad/2) {
            
            if(panPoint.y <= 40 + SMALLHEIGHT_ad/2 && panPoint.x < SCREEN_WIDTH_ad - SMALLWIDTH_ad/2-20 ){
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(panPoint.x, SMALLHEIGHT_ad/2);
                }];
            }else if(panPoint.y >= SCREEN_HEIGHT_ad - 40 - SMALLHEIGHT_ad/2 && panPoint.x < SCREEN_WIDTH_ad - SMALLWIDTH_ad/2 - 20){
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(panPoint.x, SCREEN_HEIGHT_ad - SMALLHEIGHT_ad/2);
                  }];
             } else if (panPoint.x > SCREEN_WIDTH_ad- SMALLWIDTH_ad/2-20 && panPoint.y < SMALLHEIGHT_ad/2){
                
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(SCREEN_WIDTH_ad - SMALLWIDTH_ad/2, SMALLHEIGHT_ad/2);
                }];
            }else{
                
                CGFloat pointy = panPoint.y > SCREEN_HEIGHT_ad - SMALLHEIGHT_ad/2 ? SCREEN_HEIGHT_ad- SMALLHEIGHT_ad/2 :panPoint.y;
                [UIView animateWithDuration:animateDuration_ad animations:^{
                    self.center = CGPointMake(SCREEN_WIDTH_ad - SMALLWIDTH_ad/2, pointy);
                }];
            }
        }
    }
}



-  (void)changeStatus {
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat x = self.center.x < 20 + SMALLWIDTH_ad/2 ? 0 :  self.center.x > SCREEN_WIDTH_ad - 20 - SMALLWIDTH_ad/2 ? SCREEN_WIDTH_ad : self.center.x;
        CGFloat y = self.center.y < 40 + SMALLHEIGHT_ad/2 ? 0 : self.center.y > SCREEN_HEIGHT_ad - 40 - SMALLHEIGHT_ad/2 ? SCREEN_HEIGHT_ad : self.center.y;
        //禁止停留在4个角
        if((x == 0 && y ==0) || (x == SCREEN_WIDTH_ad && y == 0) || (x == 0 && y == SCREEN_HEIGHT_ad) || (x == SCREEN_WIDTH_ad && y == SCREEN_HEIGHT_ad)){
            y = self.center.y;
        }
        self.center = CGPointMake(x, y);
    }];
}

- (UIImageView *)floatImgView {
    if (!_floatImgView) {
        _floatImgView = [UIImageView new];
        _floatImgView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAdAction)];
        [_floatImgView addGestureRecognizer:tap];
    }
    return _floatImgView;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
        [_closeBtn setBackgroundImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
    }
    return _closeBtn;
}
@end
