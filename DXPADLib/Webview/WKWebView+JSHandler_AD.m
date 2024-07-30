//
//  WKWebView+JSHandler_AD.m
//
//
//  DITOApp
//
//  Created by mac on 2021/6/22.

#import "WKWebView+JSHandler_AD.h"

#import <objc/runtime.h>


@implementation WKWebView (JSHandler_AD)

- (HJADWKWebViewHandler *)hj_jsHandler{
    return objc_getAssociatedObject(self, @selector(hj_jsHandler));
}
- (void)setHj_jsHandler:(HJADWKWebViewHandler *)hz_jsHandler{
    objc_setAssociatedObject(self, @selector(hj_jsHandler), hz_jsHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//+ (BOOL)handlesURLScheme:(NSString *)urlScheme
//{
//    return NO;
//}

@end
