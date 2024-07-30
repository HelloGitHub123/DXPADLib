//
//  ADBaseWebViewController.h
//  BOL
//
//  Created by 李标 on 2023/1/6.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADBaseWebViewController : UIViewController

@property (nonatomic, strong) WKWebView *wkWebview;
@property (nonatomic, strong) NSString *loadUrl; //h5加载
@property (nonatomic, strong) NSString *htmlStr; //html加载
#pragma mark -- 设置
@property (nonatomic, assign) BOOL isShowNavBar;// YES:显示   NO: 默认不显示
#pragma mark -- 属性
@property (nonatomic, strong) UIColor *bgColor;

- (void)refreshWebViewLayout;
@end

NS_ASSUME_NONNULL_END
