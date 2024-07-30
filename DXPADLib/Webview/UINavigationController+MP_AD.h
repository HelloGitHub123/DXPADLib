//
//  UINavigationController+MP_AD.h
//  mPaas_Poc_Demo
//
//  Created by wyy on 2022/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (MP_AD)

@property (nonatomic,weak) id<UINavigationControllerDelegate> mp_delegate;

@end

NS_ASSUME_NONNULL_END
