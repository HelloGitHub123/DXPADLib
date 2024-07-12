//
//  HJ_JSHandler.h
//
//
//  DITOApp
//
//  Created by mac on 2021/6/22.

#import <Foundation/Foundation.h>
#import "HJWKWebViewHandler.h"
#import "BaseWebViewController.h"

NS_ASSUME_NONNULL_BEGIN


@protocol ZXXE_JavaScriptExport <HJJavaScriptExport>

// 返回到当前控制器根目录
- (void)goBackHome;
// 关闭当前H5堆栈
- (void)closePage;
// 隐藏原生导航栏
- (void)hiddenNavigationBar;
// 显示原生导航栏
- (void)showNavigationBar;
// 获取定位以及地理位置信息
- (void)getLocation;
// 调用原生分享功能进行第三方社媒分享
- (void)shareBySystem:(NSString *)url;
// 保存图片到相册
- (void)saveImageToGallery:(NSString *)params;
// 发邮件
- (void)sendMail:(NSString *)paramsStr;
// 设置手机 状态栏颜色
- (void)changeStatusBarColor:(NSString *)paramsStr;

@end


@interface HJ_JSHandler : NSObject<ZXXE_JavaScriptExport>

@property (nonatomic, weak) BaseWebViewController *webViewController;

- (instancetype)initWithViewController:(BaseWebViewController *)webViewController;

@end

NS_ASSUME_NONNULL_END
