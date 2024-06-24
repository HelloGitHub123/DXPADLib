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
// 广告点击事件回调
@property (nonatomic, copy) void (^clickBlock)(void);
// 关闭回调
@property (nonatomic, copy) void (^closeBlock)(void);
// 浮动广告点击事件
@property (nonatomic, copy) void (^floatViewClickBlock)(void);
// 弹窗广告
@property (nonatomic, copy) void (^alertViewClickBlock)(void);

+ (instancetype)sharedMgr;

// 启动
- (void)startConfig;

// 设置默认启动图片
- (void)setLaunchImg:(NSString*)img;

// 具体vc展示
- (void)showAdWith:(UIViewController*)vc;

// 清除
- (void)clearAd;

@end

NS_ASSUME_NONNULL_END
