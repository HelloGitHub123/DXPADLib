//
//  DXPADHeader.h
//  Pods
//
//  Created by 李标 on 2024/6/6.
//

#ifndef DXPADHeader_h
#define DXPADHeader_h


#define isNull_ad(x)                (!x || [x isKindOfClass:[NSNull class]])
#define isEmptyString_ad(x)         (isNull_ad(x) || [x isEqual:@""] || [x isEqual:@"(null)"] || [x isEqual:@"null"])
#define IsArrEmpty_ad(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref) count] == 0))

#define SCREEN_WIDTH_ad             [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT_ad            [UIScreen mainScreen].bounds.size.height

#define kDCADSafeBottom_ad ([[UIApplication sharedApplication] statusBarFrame].size.height>20?34:0)
#define kDCADSafeTop_ad ([[UIApplication sharedApplication] statusBarFrame].size.height>20?44:20)

#define Is_iPhoneX_Or_More_ad ([UIScreen mainScreen].bounds.size.height >= 812)
// 状态栏高度
#define STATUS_BAR_HEIGHT_ad       (Is_iPhoneX_Or_More_ad ? 44.f : 20.f)

#define SMALLHEIGHT_ad self.frame.size.height
#define SMALLWIDTH_ad self.frame.size.width

#define animateDuration_ad  0.3       //位置改变动画时间


#endif /* DXPADHeader_h */
