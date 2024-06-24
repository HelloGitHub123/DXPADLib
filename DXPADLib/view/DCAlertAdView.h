//
//  DCAlertAdView.h
//  DITOApp
//
//  Created by 孙全民 on 2022/10/31.
//

#import <UIKit/UIKit.h>
#import "DCAdModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCAlertAdView : UIView

// 广告点击事件回调
@property (nonatomic, copy) void (^clickBlock)(void);

- (instancetype)initWith:(DCAdDetail*)adDetail;
@end

NS_ASSUME_NONNULL_END
