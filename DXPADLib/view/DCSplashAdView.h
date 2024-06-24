//
//  DCSplashAdView.h
//  DITOApp
//
//  Created by 孙全民 on 2022/11/2.
//

#import <UIKit/UIKit.h>
#import "DCAdModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCSplashAdView : UIView

@property (nonatomic, strong) UIImageView *screenImg;
@property (nonatomic, strong) UIImageView *adImgView;
@property (nonatomic, assign) BOOL splashAdShowing; // 正在展示
@property (nonatomic, copy) void (^clickBlock)(DCAdPic *adPic); // 广告点击事件
@property (nonatomic, copy) void (^closeBlock)(NSString *str); // 关闭

// 展示开屏广告
- (void)showSplashAD:(DCAdDetail*)splashAdDetail adpic:(DCAdPic*)adPic;
@end

NS_ASSUME_NONNULL_END
