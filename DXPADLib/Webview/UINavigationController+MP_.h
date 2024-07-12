//
//  UINavigationController+MP_.h
//  mPaas_Poc_Demo
//
//  Created by wyy on 2022/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (MP_)

@property (nonatomic,weak) id<UINavigationControllerDelegate> mp_delegate;

@end

NS_ASSUME_NONNULL_END
