//
//  WKWebView+JSHandler.h
//  
//
//  DITOApp
//
//  Created by mac on 2021/6/22.


#import <WebKit/WebKit.h>
#import "HJWKWebViewHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (JSHandler)

@property (nonatomic, strong) HJWKWebViewHandler *hj_jsHandler;
@end

NS_ASSUME_NONNULL_END
