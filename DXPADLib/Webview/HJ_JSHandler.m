//
//  HJ_JSHandler.m
//
//
//  DITOApp
//
//  Created by mac on 2021/6/22.

#import "HJ_JSHandler.h"
#import "HJHandelJson.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <DXPToolsLib/HJMBProgressHUD+Category.h>
#import <QuickLook/QuickLook.h>
#import <DXPNetWorkingManagerLib/DCNetAPIClient.h>
#import <DXPToolsLib/HJTool.h>

typedef enum {
    SchemeType_APP = 1,
    SchemeType_WebView_Nav,
    SchemeType_WebView_NoneNav,
    SchemeType_Safari,
    SchemeType_MiniApps, // 小程序
} SchemeType;

typedef enum {
    OpenMode_NewPage = 1,      // 直接打开新页面(不传默认)
    OpenMode_CloseCurrentPage, // 关闭当前页打开新页面
    OpenMode_BackHomeClosePage, // 回APP首页后打开新页面
    OpenMode_OpenNativePage     // 打开新的原生页面
} OpenMode;

//判断是否为空
#define objectOrNull(obj)        ((obj) ? (obj) : [NSNull null])
#define objectOrEmptyStr(obj)    ((obj) ? (obj) : @"")
#define isNull(x)                (!x || [x isKindOfClass:[NSNull class]])
#define toInt(x)                 (isNull(x) ? 0 : [x intValue])
#define isEmptyString(x)         (isNull(x) || [x isEqual:@""] || [x isEqual:@"(null)"] || [x isEqual:@"null"])
#define IsNilOrNull(_ref)        (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]))
#define IsArrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref) count] == 0))


@interface HJ_JSHandler ()<UIImagePickerControllerDelegate,UIActionSheetDelegate,UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate,CLLocationManagerDelegate,MFMailComposeViewControllerDelegate,QLPreviewControllerDataSource, QLPreviewControllerDelegate>
//@property (nonatomic, weak) BaseWebViewController *webViewController;
// openAppUrl
@property (nonatomic, assign) SchemeType schemeType;
@property (nonatomic, assign) OpenMode openMode;
// 定位
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geoCoder;
@property (nonatomic, strong) CLLocation *myLocation;
@end

@implementation HJ_JSHandler

- (instancetype)initWithViewController:(BaseWebViewController *)webViewController{
    if (self = [super init]) {
        _webViewController = webViewController;
    }
    return self;
}

#pragma mark -- 返回到当前控制器根目录
- (void)goBackHome {
    [self.webViewController.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark -- 返回到当前控制器根目录
- (void)closePage {
    [self.webViewController.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- 隐藏原生导航栏
- (void)hiddenNavigationBar {
    self.webViewController.isShowNavBar = NO;
    [self.webViewController refreshWebViewLayout];
    [self.webViewController.navigationController setNavigationBarHidden:YES animated:NO];
}

#pragma mark -- 显示原生导航栏
- (void)showNavigationBar {
    self.webViewController.isShowNavBar = YES;
    [self.webViewController refreshWebViewLayout];
    [self.webViewController.navigationController setNavigationBarHidden:NO animated:NO];
}

#pragma mark -- 获取定位以及地理位置信息
- (void)getLocation {
    [self startLocation];
}

// 开始定位
- (void)startLocation {
    // 初始化定位管理者
    self.locationManager = [[CLLocationManager alloc] init];
    // 判断设备是否能够进行定位
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.delegate = self;
        // 精确度获取到米
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // 设置过滤器为无
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        // 取得定位权限
        [self.locationManager requestWhenInUseAuthorization];
        // 开始获取定位
        [self.locationManager startUpdatingLocation];
        // 地理信息
        self.geoCoder = [[CLGeocoder alloc] init];
    } else {
        NSLog(@"error");
    }
}

// CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"%lu", (unsigned long)locations.count);
    self.myLocation = locations.lastObject;
    NSLog(@"经度:%f 维度:%f", _myLocation.coordinate.longitude, _myLocation.coordinate.latitude);
    [self.geoCoder reverseGeocodeLocation:self.myLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            CLPlacemark *placeMark = [placemarks objectAtIndex:0];
            NSLog(@"%@",placeMark.name);
            NSString *city = placeMark.locality;
            if (!city) {
                city = placeMark.administrativeArea;
            }
            NSString *name = isEmptyString(placeMark.name)? @"" : placeMark.name;
            NSString *thoroughfare = isEmptyString(placeMark.thoroughfare) ? @"" : placeMark.thoroughfare;
            NSString *subThoroughfare = isEmptyString(placeMark.subThoroughfare) ? @"": placeMark.subThoroughfare;
            NSString *locality = isEmptyString(placeMark.locality) ? @"": placeMark.locality;
            NSString *subLocality = isEmptyString(placeMark.subLocality) ? @"" : placeMark.subLocality;
            NSString *country = isEmptyString(placeMark.country) ? @"" : placeMark.country ;
            NSLog(@"位置名称:%@,街道:%@,子街道:%@,市:%@,区:%@,国家:%@",name,thoroughfare,subThoroughfare,locality,subLocality,country);
        
            [self.webViewController.wkWebview evaluateJavaScript:[self setJsMethodStrWithMethName:@"setLocation" params:@{@"lat":[NSNumber numberWithDouble:self.myLocation.coordinate.latitude],@"lng":[NSNumber numberWithDouble:self.myLocation.coordinate.longitude],@"name":name,@"thoroughfare":thoroughfare,@"subThoroughfare":subThoroughfare,@"locality":locality,@"subLocality":subLocality,@"country":country}] completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
                NSLog(@"地址反馈完成");
            }];
            
        } else if (error == nil && [placemarks count] == 0) {
            // 未查找到结果
            NSLog(@"未查找到结果");
        } else if (error != nil) {
            // error
            NSLog(@"出错:%@",error);
        }
        [self.locationManager stopUpdatingLocation];
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"出错:%@",error);
}

#pragma mark -- 调用原生分享功能进行第三方社媒分享
- (void)shareBySystem:(NSString *)url {
    NSDictionary *parmasDic = [HJHandelJson dictionaryWithJsonString:url];
    if ([parmasDic allKeys] == 0) {
        return;
    }
    // 图片链接
    NSString *shareImageUrl = isEmptyString([parmasDic objectForKey:@"shareImageUrl"])?@"":[parmasDic objectForKey:@"shareImageUrl"];
    // 链接
    NSString *shareLink = isEmptyString([parmasDic objectForKey:@"shareLink"])?@"":[parmasDic objectForKey:@"shareLink"];
    // 内容
    NSString *shareContent = isEmptyString([parmasDic objectForKey:@"shareContent"])?@"":[parmasDic objectForKey:@"shareContent"];
    
    // 判断分享的图片
    NSArray *activityItems = @[];
    if (!isEmptyString(shareImageUrl)) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[parmasDic objectForKey:@"shareImageUrl"]]];
        if (data) {
            UIImage *result = [UIImage imageWithData:data];
            UIImage *imageToShare = result;
            activityItems = @[shareContent, imageToShare, shareLink];
        } else {
            activityItems = @[shareContent, shareLink];
        }
    } else {
        if(!isEmptyString(shareContent)) {
            activityItems = @[shareContent, shareLink];
        } else {
            activityItems = @[shareLink];
        }
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
    [self.webViewController presentViewController:activityVC animated:YES completion:nil];
    //分享之后的回调
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed) {
            NSLog(@"completed");
        } else  {
            NSLog(@"cancled");
        }
    };
}

#pragma mark -- 保存图片到相册
- (void)saveImageToGallery:(NSString *)params {
    NSDictionary *parmasDic = [HJHandelJson dictionaryWithJsonString:params];
    if ([parmasDic allKeys] == 0) {
        return;
    }
    NSString *imagebase64 = [parmasDic objectForKey:@"imagebase64"];
    if (isEmptyString(imagebase64)) {
        return;
    }
    
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imagebase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *photo = [UIImage imageWithData:imageData];
    [self saveImageToPhotos:photo];
}

- (void)saveImageToPhotos:(UIImage*)savedImage {
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

// 保存图片到相册 -- 指定回调方法
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    NSString *msg = nil ;
    if (error != NULL) {
        msg = @"保存图片失败";
    } else {
        msg = @"保存图片成功";
    }
}



#pragma mark -- 发邮件
- (void)sendMail:(NSString *)paramsStr {
    NSDictionary *parmasDic = [HJHandelJson dictionaryWithJsonString:paramsStr];
    if ([parmasDic allKeys] == 0) {
        return;
    }
    NSString *emailAddress = isEmptyString([parmasDic objectForKey:@"emailAddress"])?@"":[parmasDic objectForKey:@"emailAddress"]; // 指定发送邮箱地址
    NSString *emailSubject = isEmptyString([parmasDic objectForKey:@"emailSubject"])?@"":[parmasDic objectForKey:@"emailSubject"]; // 邮件主题
    NSString *emailContent = isEmptyString([parmasDic objectForKey:@"emailContent"])?@"":[parmasDic objectForKey:@"emailContent"]; // 邮件正文
    
    //先验证邮箱能否发邮件，不然会崩溃
    if (![MFMailComposeViewController canSendMail]) {
        NSURL *url = [NSURL URLWithString:@"mailto://"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                // Fallback on earlier versions
            }
        }
        return;
    }
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    // 设置picker的委托方法，完成之后会自动调用成功或失败的方法
    picker.mailComposeDelegate = self;
    // 添加主题
    [picker setSubject:emailSubject];
    // 内容
    [picker setMessageBody:emailContent isHTML:NO];
    //收件人邮箱，使用NSArray指定多个收件人
    NSArray *toRecipients = [NSArray arrayWithObject:emailAddress];
    [picker setToRecipients:toRecipients];
    [self.webViewController.navigationController presentViewController:picker animated:YES completion:nil];
}

// 代理
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    NSLog(@"send mail error:%@", error);
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"邮件发送取消");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"邮件保存成功");
            break;
        case MFMailComposeResultSent:
            NSLog(@"邮件发送成功");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"邮件发送失败");
            break;
        default:
            NSLog(@"邮件未发送");
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -- 设置手机 状态栏颜色
- (void)changeStatusBarColor:(NSString *)paramsStr {
    NSDictionary *parmasDic = [HJHandelJson dictionaryWithJsonString:paramsStr];
    if ([parmasDic allKeys] == 0) {
        return;
    }
    // 状态栏颜色 #FFFFFF
    NSString *color = [parmasDic objectForKey:@"color"];
    // status  1 深色模式  0 浅色模式
    NSString *status = [parmasDic objectForKey:@"status"];
    
    if (!isEmptyString(color)) {
        [self setStatusBarBackgroundColor:[self hjp_colorWithHex:@"#2A2F38" alpha:1]];
    }
    // status  1 深色模式  状态栏背景色是深色时设置 状态栏 字体颜色会是白的
    if ([status isEqualToString:@"1"]) {
        
    }
    // status  0 浅色模式  状态栏背景色是深色时设置 状态栏 字体颜色会是黑的
    if ([status isEqualToString:@"1"]) {
        
    }
}

// 设置状态栏背景色
- (void)setStatusBarBackgroundColor:(UIColor *)color {
    if(@available(iOS 13.0, *)) {
        static UIView *statusBar =nil;
        if(!statusBar) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                statusBar = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.windowScene.statusBarManager.statusBarFrame] ;
                [[UIApplication sharedApplication].keyWindow addSubview:statusBar];
                statusBar.backgroundColor= color;
            });
        } else {
            statusBar.backgroundColor= color;
        }
    } else {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        if([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
            statusBar.backgroundColor= color;
        }
    }
}

#pragma mark -- other
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
    if ([params isKindOfClass:[NSString class]]) {
        method = [NSString stringWithFormat:@"%@(\'%@\')",jsMethod,params];
        return method;
    }
    return method;
}

// 压缩图片
- (NSData *)reSizeImageData:(UIImage *)sourceImage maxImageSize:(CGFloat)maxImageSize maxSizeWithKB:(CGFloat) maxSize {

    if (maxSize <= 0.0) maxSize = 1024.0;
    if (maxImageSize <= 0.0) maxImageSize = 1024.0;
    
    //先调整分辨率
    CGSize newSize = CGSizeMake(sourceImage.size.width, sourceImage.size.height);
    
    CGFloat tempHeight = newSize.height / maxImageSize;
    CGFloat tempWidth = newSize.width / maxImageSize;
    
    if (tempWidth > 1.0 && tempWidth > tempHeight) {
        newSize = CGSizeMake(sourceImage.size.width / tempWidth, sourceImage.size.height / tempWidth);
    }
    else if (tempHeight > 1.0 && tempWidth < tempHeight){
        newSize = CGSizeMake(sourceImage.size.width / tempHeight, sourceImage.size.height / tempHeight);
    }
    
    UIGraphicsBeginImageContext(newSize);
    [sourceImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //调整大小
    NSData *imageData = UIImageJPEGRepresentation(newImage,1.0);
    CGFloat sizeOriginKB = imageData.length / 1024.0;
    
    CGFloat resizeRate = 0.9;
    while (sizeOriginKB > maxSize && resizeRate > 0.1) {
        imageData = UIImageJPEGRepresentation(newImage,resizeRate);
        sizeOriginKB = imageData.length / 1024.0;
        resizeRate -= 0.1;
    }
    
    return imageData;
}

// 可变透明度的Hex方法
- (UIColor *)hjp_colorWithHex:(NSString *)hex alpha:(float)alpha
{
    NSString *colorString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // 十六进制色值必须是6-8位
    if (colorString.length >= 6  && colorString.length  <= 8)
    {
        if ([colorString hasPrefix:@"0x"] || [colorString hasPrefix:@"0X"])
            colorString = [colorString substringFromIndex:2];
        else if ([colorString hasPrefix:@"#"])
            colorString = [colorString substringFromIndex:1];
        if (colorString.length != 6)
            return [UIColor clearColor];
    }
    else
        return [UIColor clearColor];
    
    // 将6位十六进制色值分成R、G、B
    NSRange redRange    = NSMakeRange(0, 2);
    NSRange greenRange  = NSMakeRange(2, 2);
    NSRange blueRange   = NSMakeRange(4, 2);
    NSString *redString     = [colorString substringWithRange:redRange];
    NSString *greenString   = [colorString substringWithRange:greenRange];
    NSString *blueString    = [colorString substringWithRange:blueRange];
    
    // 将RGB对应的十六进制色值转化位十进制
    unsigned int r, g, b;
    [[NSScanner scannerWithString:redString]    scanHexInt:&r];
    [[NSScanner scannerWithString:greenString]  scanHexInt:&g];
    [[NSScanner scannerWithString:blueString]   scanHexInt:&b];
    
    return [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:alpha];
}

@end
