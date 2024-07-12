//
//  UINavigationController+MP_.m
//  mPaas_Poc_Demo
//
//  Created by wyy on 2022/7/19.
//

#import "UINavigationController+MP_.h"
#import <objc/runtime.h>

@implementation UINavigationController (MP_)

+ (void)load
{
    Method origMethod = class_getInstanceMethod([self class],  @selector(setDelegate:));
    Method newMethod = class_getInstanceMethod([self class], @selector(setDelegate_mp:));
    method_exchangeImplementations(origMethod, newMethod);
}


- (void)setDelegate_mp:(id<UINavigationControllerDelegate>)delegate
{
    if ([delegate isKindOfClass:UINavigationController.class] && self.mp_delegate) {
        delegate = self.mp_delegate;
    }
    [self setDelegate_mp:delegate];
}





static const char *key = "mp_delegate";
- (void)setMp_delegate:(id<UINavigationControllerDelegate>)mp_delegate
{
    objc_setAssociatedObject(self, key, mp_delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<UINavigationControllerDelegate>)mp_delegate
{
    return objc_getAssociatedObject(self, key);
}

@end
