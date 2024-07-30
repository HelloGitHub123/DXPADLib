//
//  HJADHandelJson.h
//  youcaoping
//
//  Created by 在野 on 2018/11/29.
//  Copyright © 2018年 Leo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HJADHandelJson : NSObject
//json转字典
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
//字典转json
+ (NSString *)convert2JSONWithDictionary:(NSDictionary *)dic;
//数组转json
+ (NSString *)arrayToJSONString:(NSMutableArray *)array;

@end

NS_ASSUME_NONNULL_END
