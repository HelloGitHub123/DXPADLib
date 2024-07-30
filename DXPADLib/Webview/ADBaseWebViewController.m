//
//  ADBaseWebViewController.m
//  BOL
//
//  Created by 李标 on 2023/1/6.
//

#import "ADBaseWebViewController.h"
#import "HJADHandelJson.h"
#import "HJ_ADJSHandler.h"
#import "HJADWKWebViewHandler.h"
#import "WKWebView+JSHandler_AD.h"
#import <DXPToolsLib/HJMBProgressHUD+Category.h>
#import <Masonry/Masonry.h>
#import <DXPNetWorkingManagerLib/DCNetAPIClient.h>
#import <DXPToolsLib/SNAlertMessage.h>
#import "UINavigationController+MP_AD.h"

#define LoginSuccess_BaseWebView_Notification    @"LoginSuccess_BaseWebView_Notification"
#define LogOut_BaseWebView_Notification    @"LogOut_BaseWebView_Notification"

#define kSafeTop ([[UIApplication sharedApplication] statusBarFrame].size.height > 20 ? 44 : 20)
// tabBar高度
#define TAB_BAR_HEIGHT       ((kSafeTop == 44) ? (49.f+34.f) : 49.f)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SCREEN_WIDTH             [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT            [UIScreen mainScreen].bounds.size.height
// iPhoneX
#define Is_iPhoneX_Or_More ([UIScreen mainScreen].bounds.size.height >= 812)
#define HOME_INDICATOR_HEIGHT       (Is_iPhoneX_Or_More ? 34.f : 0.f)

#define stringFormat(s, ...)     [NSString stringWithFormat:(s),##__VA_ARGS__]

//判断是否为空
#define objectOrNull(obj)        ((obj) ? (obj) : [NSNull null])
#define objectOrEmptyStr(obj)    ((obj) ? (obj) : @"")
#define isNull(x)                (!x || [x isKindOfClass:[NSNull class]])
#define toInt(x)                 (isNull(x) ? 0 : [x intValue])
#define isEmptyString(x)         (isNull(x) || [x isEqual:@""] || [x isEqual:@"(null)"] || [x isEqual:@"null"])
#define IsNilOrNull(_ref)        (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]))
#define IsArrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref) count] == 0))

@interface ADBaseWebViewController () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, UINavigationControllerDelegate>

@property (nonatomic, strong) NSString *url_temp; //中间存储url,下拉刷新用到
@property (nonatomic, strong) NSTimer *adTimer;

@end

@implementation ADBaseWebViewController

- (void)dealloc {
	NSLog(@"dealloc");
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = self.bgColor?self.bgColor:UIColorFromRGB(0xFFFFFF);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[self initData];
	
	[self initUI];
	
	[self loadWebPage];// 加载页面
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (self.isShowNavBar) {
		[self.navigationController setNavigationBarHidden:NO animated:NO];
	} else {
		[self.navigationController setNavigationBarHidden:YES animated:NO];
	}
}

- (void)initData {
	
}

- (void)initUI {
	[self.view addSubview:self.wkWebview];
	[self.wkWebview mas_makeConstraints:^(MASConstraintMaker *make) {
		if (self.isShowNavBar) {
			make.top.mas_equalTo(0);
		} else {
			make.top.mas_equalTo(kSafeTop);
		}
		make.leading.mas_equalTo(0);
		make.width.mas_equalTo(SCREEN_WIDTH);
		make.bottom.mas_equalTo(-HOME_INDICATOR_HEIGHT);
	}];
}

- (void)refreshWebViewLayout {
	[self.wkWebview mas_updateConstraints:^(MASConstraintMaker *make) {
		if (self.isShowNavBar) {
			make.top.mas_equalTo(0);
		} else {
			make.top.mas_equalTo(kSafeTop);
		}
	}];
}

- (void)loadWebPage {
	if (isEmptyString(self.htmlStr)) {
		if (!isEmptyString(self.loadUrl)) {
			self.url_temp = self.loadUrl;
			NSString *url = [self.loadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
			//原生打开H5页面需要带上时间戳参数，避免有缓存，需要判断一下打开的url，如果url上没参数则拼接 ?timestamp=当前时间戳； 如果url上本来有参数，则拼接 &timestamp=当前时间戳
			NSString *timeSp = [NSString stringWithFormat:@"%.0lf", (double)[[NSDate  date] timeIntervalSince1970]*1000];
			NSURLComponents *components = [NSURLComponents componentsWithString:url];
			NSArray<NSURLQueryItem *> *queryItems = [components queryItems];
			if (queryItems.count > 0) {
				url = stringFormat(@"%@&timestamp=%@", url, timeSp);
			} else {
				url = stringFormat(@"%@?timestamp=%@", url, timeSp);
			}
			
			NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
			//            _loadUrl = @"https://react-vant.3lang.dev/~demo";
			//            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_loadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]]];
			[self.wkWebview loadRequest:request];
			
			[self.wkWebview addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
		}
	} else {
		//        [self.wkWebview loadHTMLString:[self divWithHtml:self.htmlStr] baseURL:[NSURL URLWithString:[DCNetAPIClient sharedClient].baseUrl]];
		[self.wkWebview loadHTMLString:[self divWithHtml:self.htmlStr] baseURL:nil];
	}
}

- (NSString *)divWithHtml:(NSString *)html {
	html = stringFormat(@"<div>%@</div>", html);
	NSString *strCssHead = [NSString stringWithFormat:@"<head>"
							"<link rel=\"stylesheet\" type=\"text/css\" href=\"FAQHtmlCss.css\">"
							"<meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1, minimum-scale=1, width=device-width, user-scalable=no\">"
							"<style>img{max-width:320px !important;}</style>"
							"</head>"];
	NSString *end = [NSString stringWithFormat:@"%@<body>%@</body>", strCssHead, html];
	return end;
}

// 观察
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if ([keyPath isEqualToString:@"URL"]) { // 监听URL的变化
		NSLog(@"当前URL-----%@",self.wkWebview.URL.absoluteString);
		self.url_temp = self.wkWebview.URL.absoluteString;
	}
}

#pragma mark - 通知- 进入后台
- (void)applicationWillEnterBackground {
	[self onPageHiddenHandler];
}

// 退出页面调用
- (void)onPageHiddenHandler {
	[self.wkWebview evaluateJavaScript:[self setJsMethodStrWithMethName:@"onPageHidden" params:@{}] completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
		NSLog(@"evaluateJavaScript --- onPageHiddenHandler");
	}];
}

#pragma mark - 通知- 回到前台
- (void)didBecomeActive {
	[self onPageVisibleHandler];
}

// 进入页面调用
- (void)onPageVisibleHandler {
	[self.wkWebview evaluateJavaScript:[self setJsMethodStrWithMethName:@"onPageVisible" params:@{}] completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
		NSLog(@"evaluateJavaScript --- onPageVisibleHandler");
	}];
}

#pragma mark -- WKNavigationDelegate 主要处理一些跳转、加载处理操作
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
	NSLog(@"%s ---页面开始加载",__func__);
	//    [HJMBProgressHUD showLoading];
	//    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(closeHud) userInfo:nil repeats:NO];
}

//- (void)closeHud {
//    [HJMBProgressHUD hideLoading];
//}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	NSLog(@"%s ---页面加载完成",__func__);
	//    [HJMBProgressHUD hideLoading];
}

// 提交发生错误时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
	NSLog(@"%s ---页面加载失败 \n didFailNavigation error:%@",__func__, [error description]);
	//    [HJMBProgressHUD hideLoading];
}

// 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
// 是否允许页面加载 在这个方法里可以对页面跳转进行拦截处理
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSString * urlStr = navigationAction.request.URL.absoluteString;
	NSLog(@"正在加载请求--------:%@",urlStr);
	if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
		if(navigationAction.targetFrame ==nil|| !navigationAction.targetFrame.isMainFrame) {
			[webView loadRequest:navigationAction.request];
			decisionHandler (WKNavigationActionPolicyCancel);
		}else {
			decisionHandler (WKNavigationActionPolicyAllow);
		}
	}
	else {
		decisionHandler (WKNavigationActionPolicyAllow);
	}
	return;
}

#pragma mark -
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		if (challenge.previousFailureCount == 0) {
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
		} else {
			completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
		}
	} else {
		completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
	}
}

#pragma mark - 执行当前请求中，获取form表单数据
- (void)formDataByWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {
	
	NSString *javascript = @"\
			   var form = document.forms[0];\
			   var formData = new FormData(form);\
			   var data = {};\
			   for (var pair of formData.entries()) {\
				   data[pair[0]] = pair[1];\
			   }\
			   JSON.stringify(data);\
		   ";
	[webView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {
		completionHandler(result, error);
	}];
}

/**
 *  web界面中有弹出警告框时调用
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param completionHandler 警告框消失调用
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Message" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		completionHandler();
	}])];
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - WKScriptMessageHandler
// js 调用 OC 会代理回调
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSLog(@"name:%@\\\\n body:%@\\\\n frameInfo:%@\\\\n",message.name,message.body,message.frameInfo);
}

// JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
	if (prompt) {
		id res = [webView.hj_jsHandler performWithSel:prompt withObject:defaultText];
		completionHandler(res);
	}
}

#pragma mark - 懒加载
- (WKWebView *)wkWebview {
	if (!_wkWebview) {
		WKUserContentController *userContent = [[WKUserContentController alloc] init];
		WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
		config.userContentController = userContent;
		WKPreferences *preferences = [WKPreferences new];
		config.preferences = preferences;
		if ([self getIsPad]) {
			config.applicationNameForUserAgent = @"clp,iPad"; // 浏览器设置UA
		} else {
			config.applicationNameForUserAgent = @"clp"; // 浏览器设置UA
		}
		//是否支持JavaScript
		config.preferences.javaScriptEnabled = YES;
		config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
		// 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
		config.allowsInlineMediaPlayback = YES;
		//设置视频是否需要用户手动播放  设置为NO则会允许自动播放
		config.mediaTypesRequiringUserActionForPlayback = YES;
		//设置是否允许画中画技术 在特定设备上有效
		config.allowsPictureInPictureMediaPlayback = YES;
		//        设置请求的User-Agent信息中应用程序名称 iOS9后可用
		//        config.applicationNameForUserAgent = @"ChinaDailyForiPad";
		_wkWebview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
		_wkWebview.backgroundColor = [UIColor whiteColor];
		_wkWebview.scrollView.backgroundColor = [UIColor whiteColor];
		_wkWebview.UIDelegate = self;// UI代理
		_wkWebview.navigationDelegate = self;// 导航代理
		_wkWebview.allowsBackForwardNavigationGestures = YES;// 是否支持手势返回上一级
		_wkWebview.opaque = NO;
		_wkWebview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		_wkWebview.scrollView.showsHorizontalScrollIndicator = NO;
		_wkWebview.scrollView.showsVerticalScrollIndicator = NO;
		
		[self setjsHandler:userContent];
		
		if (@available(iOS 11.0, *)) {
			_wkWebview.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
		} else {
			self.edgesForExtendedLayout = UIRectEdgeNone;
		}
	}
	return _wkWebview;
}

#pragma mark - 其他方法
- (void)setjsHandler:(WKUserContentController *)userContent {
	HJADWKWebViewHandler *handler = [[HJADWKWebViewHandler alloc] initWithUserContent:userContent];
	[handler configureWithJSExport:[[HJ_ADJSHandler alloc] initWithViewController:self] bindName: @"clp"];
	_wkWebview.hj_jsHandler = handler;
}

- (NSString*)setJsMethodStrWithMethName:(NSString *)jsMethod params:(NSDictionary*)params {
	NSString *method = @"";
	if (params==nil) {
		method = [NSString stringWithFormat:@"%@()",jsMethod];
	}
	if ([params isKindOfClass:[NSDictionary class]]) {
		NSData *data = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		method = [NSString stringWithFormat:@"%@(\'%@\')",jsMethod,string];
		return method;
	}
	return method;
}

// 判断是否ipad
- (BOOL)getIsPad {
	NSString *deviceType = [UIDevice currentDevice].model;
	if([deviceType isEqualToString:@"iPad"]) {
		return YES;
	}
	return NO;
}

@end
