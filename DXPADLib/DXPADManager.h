//
//  DXPADManager.h
//  DCADSdk
//
//  Created by 李标 on 2024/6/5.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DCAdModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DXPADManager : NSObject

// 必传，不能为空 唯一性 (eg:号码 或者用户的id)
@property (nonatomic, copy, nonnull) NSString *userKey;
// 广告显示回调
@property (nonatomic, copy) void (^onAdsShowBlock)(DCAdPic *adPic);
// 广告点击事件回调
@property (nonatomic, copy) void (^onAdsClick)(DCAdPic *adPic);
// 关闭回调
@property (nonatomic, copy) void (^onAdsFinish)(void);
// 广告skip被点击事件
@property (nonatomic, copy) void (^onSkipClickBlock)(void);
// 浮动广告点击事件
@property (nonatomic, copy) void (^floatViewClickBlock)(DCAdPic *adPic);
// 浮动广告关闭事件
@property (nonatomic, copy) void (^floatViewCloseBlock)(void);
// 浮动广告显示事件
@property (nonatomic, copy) void (^floatViewShowBlock)(void);
// 弹窗广告
@property (nonatomic, copy) void (^alertViewClickBlock)(DCAdPic *adPic);
// 弹框广告关闭
@property (nonatomic, copy) void (^alertViewCloseBlock)(void);
// 弹框广告显示事件
@property (nonatomic, copy) void (^alertViewShowBlock)(void);


+ (instancetype)sharedMgr;

// 启动
- (void)startConfig;

// 设置默认启动图片
- (void)setLaunchImg:(NSString*)img;

// 具体vc展示
//- (void)showAdWith:(UIViewController*)vc;
- (void)showAdWith:(NSString *)pageUrl;

// 清除
- (void)clearAd;

// 是否支持内置webview。 不设置 默认false (不推荐使用) 内置WebView 比较简单,无法囊括各种定制化需求
- (void)setUseDefaultWebView:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
