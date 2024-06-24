//
//  DCAdModel.h
//  DITOApp
//
//  Created by 孙全民 on 2022/10/27.
//  模型类
 
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class DCAdDetail;
@interface DCAdModel : NSObject
@end

@class DCAdPic,DCAdExtData;
@interface DCAdDetail : NSObject
@property (nonatomic, copy) NSString *adId;
@property (nonatomic, copy) NSString *adName;
@property (nonatomic, assign) NSInteger seq;
@property (nonatomic, copy) NSString *effDate; // 作为发布时间 日期格式yyyyMMddHHmmss
@property (nonatomic, copy) NSString *expDate;
@property (nonatomic, copy) NSString *isLogin;
@property (nonatomic, copy) NSString *adType; // 1：Open（开屏广告）2：Popup（弹窗广告）3：Suspension（悬浮广告） 4：Atmosphere（氛围广告）
@property (nonatomic, copy) NSString *state;
@property (nonatomic, strong) DCAdExtData *extData; // 扩展业务
@property (nonatomic, strong) NSArray<DCAdPic*> *adPicList; // 图片列表
@property (nonatomic, copy) NSString *pageUrl; // deeplink


// 非接口字段
@property (nonatomic, copy) NSString *clsName; // 对应控制器vc
@property (nonatomic, assign) BOOL invaild; // 已经展示过了，置为无效
@property (nonatomic, assign)  BOOL showing; // 防止重复展示
@end


@interface DCAdPic : NSObject
@property (nonatomic, copy) NSString *aid;
@property (nonatomic, copy) NSString *adImg;  // 图片
@property (nonatomic, assign) NSInteger seq; // 图片顺序
@property (nonatomic, copy) NSString *adWebUrl; //WEB链接
@property (nonatomic, copy) NSString *schemaType; // 跳转类型
@property (nonatomic, copy) NSString *adAppUrl; // APP链接
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat weight;
@end


@interface DCAdExtData : NSObject
@property (nonatomic, copy) NSString *ruleType; // 1 show everytime 2 show at the first time 3 show some times everyda(后面带一个填几次的输入框) ruleValue传次数

@property (nonatomic, assign) NSInteger ruleValue; // 当ruleType == 3，ruleValue 为次数
@property (nonatomic, copy) NSString *drageFlag; // 悬浮可否拖动
@property (nonatomic, assign) NSInteger displayTime; // 开屏倒计时：秒
// 非接口字段
@property (nonatomic, assign) NSInteger alreadyShowTimes; // 已经展示次数
@end


NS_ASSUME_NONNULL_END
 
