//
//  DCFloatingAdView.h
//  DITOApp
//
//  Created by 孙全民 on 2022/10/27.
//  悬浮广告View

#import <UIKit/UIKit.h>
#import "DCAdModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCFloatingAdView : UIView

// 广告点击事件回调
@property (nonatomic, copy) void (^clickBlock)(void);

- (instancetype)initWith:(DCAdDetail*)adDetail;
@end

NS_ASSUME_NONNULL_END
