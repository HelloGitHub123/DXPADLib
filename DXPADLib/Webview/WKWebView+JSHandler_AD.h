//
//  WKWebView+JSHandler_AD.h
//  
//
//  DITOApp
//
//  Created by mac on 2021/6/22.


#import <WebKit/WebKit.h>
#import "HJADWKWebViewHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (JSHandler_AD)

@property (nonatomic, strong) HJADWKWebViewHandler *hj_jsHandler;
@end

NS_ASSUME_NONNULL_END
