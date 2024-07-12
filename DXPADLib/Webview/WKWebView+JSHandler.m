//
//  WKWebView+JSHandler.m
//  
//
//  DITOApp
//
//  Created by mac on 2021/6/22.

#import "WKWebView+JSHandler.h"

#import <objc/runtime.h>


@implementation WKWebView (JSHandler)

- (HJWKWebViewHandler *)hj_jsHandler{
    return objc_getAssociatedObject(self, @selector(hj_jsHandler));
}
- (void)setHj_jsHandler:(HJWKWebViewHandler *)hz_jsHandler{
    objc_setAssociatedObject(self, @selector(hj_jsHandler), hz_jsHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//+ (BOOL)handlesURLScheme:(NSString *)urlScheme
//{
//    return NO;
//}

@end
