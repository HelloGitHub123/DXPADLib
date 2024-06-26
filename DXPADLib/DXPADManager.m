//
//  DXPADManager.m
//  DCADSdk
//
//  Created by 李标 on 2024/6/5.
//

#import "DXPADManager.h"
#import <SDWebImage/SDWebImage.h>
#import <MJExtension/MJExtension.h>
#import "DCSplashAdView.h"
#import "DCFloatingAdView.h"
#import "DCAlertAdView.h"
#import <DXPNetWorkingManagerLib/DCNetAPIClient.h>
#import "DXPADHeader.h"

// 记录展示次数
static  NSString * DXP_AD_DATA_SHOW_TIMES = @"DXP_AD_DATA_SHOW_TIMES";
// 记录展示索引
static  NSString * DXP_AD_DATA_SHOW_INDEX = @"DXP_AD_DATA_SHOW_INDEX";
// 记录id
static  NSString * DXP_AD_ID = @"DXP_AD_ID";

static NSInteger  HJAlertADTag = 7890012;
static NSInteger  HJFloatViewTag = 7890013;


static DXPADManager *manager = nil;

@interface DXPADManager () {
	DXPADManager *_manager;
}
// 存放当天时间和数据
@property (nonatomic, strong) NSMutableDictionary *adShowCacheDIc;
// 广告id
@property (nonatomic, copy) NSString *adID;
// 上次打开的广告的index
@property (nonatomic, assign) NSInteger splashAdLastShowIndex;
// 单个开屏广告对象
@property (nonatomic, strong) DCAdDetail *splashAdObj;
// 广告接口数据模型
@property (nonatomic, strong) NSMutableArray<DCAdDetail *> *mktAdList;
// 弹框广告
@property (nonatomic, strong) NSMutableArray *alertAdArr;
// 浮窗广告
@property (nonatomic, strong) NSMutableArray *floatingAdArr;
// 广告管理路由配置 Dic {路由URL:vcClassName}
@property (nonatomic, strong) NSDictionary *adPageUrlDic;
// 开屏广告view
@property (nonatomic, strong) DCSplashAdView *splashAdView;

@property (nonatomic,strong) NSMutableArray *showViews;
// 默认的启动图
@property (nonatomic, strong) UIImage *defaultLaunchImg;
@end


@implementation DXPADManager

+ (instancetype)sharedMgr {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		manager = [[DXPADManager alloc] init];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *dic = [defaults objectForKey:DXP_AD_DATA_SHOW_TIMES]; // 存的是日期 {date:xxxx}
		
		void(^updateShowTimeDic)(NSString *) = ^(NSString *currentTimeString) {
			NSDictionary *newDic = @{@"date":currentTimeString};
			manager.adShowCacheDIc = [NSMutableDictionary dictionaryWithDictionary:newDic];
			[defaults setObject:newDic forKey:DXP_AD_DATA_SHOW_TIMES];
		};
		
		manager.adID = [defaults objectForKey:DXP_AD_ID]?:@""; // 取出缓存的开屏广告id
		
		// 设置 开屏广告 splashAdLastShowIndex 展示下标
		NSString *index = [defaults objectForKey:DXP_AD_DATA_SHOW_INDEX];
		if(!isEmptyString_ad(index)) {
			manager.splashAdLastShowIndex = [index integerValue];
		} else {
			manager.splashAdLastShowIndex = 0;
		}

		// 获取当前日期时间
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[formatter setDateFormat:@"yyyyMMdd"];
		formatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];//东八区时间
		NSDate *datenow = [NSDate date];
		NSString *currentTimeString = [formatter stringFromDate:datenow];
		
		if (dic) {
			NSString *dateStr = [dic objectForKey:@"date"];
			// 判断是否是今天数据
			if ([currentTimeString isEqualToString:dateStr]) {
				manager.adShowCacheDIc = [NSMutableDictionary dictionaryWithDictionary:dic];
			}else {
				updateShowTimeDic(currentTimeString);
			}
		}else {
			updateShowTimeDic(currentTimeString);
		}
	});
	return manager;
}

- (instancetype)init {
	if ( self = [super init]) {
	}
	return self;
}

// 入口
- (void)startConfig {
	// 展示splash view
	__weak __typeof(&*self)weakSelf = self;
	self.splashAdView.layer.zPosition = MAXFLOAT;
	[[UIApplication sharedApplication].delegate.window addSubview:self.splashAdView];
	
	[self fetchADConfig:^(bool success) {
		if (success && self.splashAdObj && !IsArrEmpty_ad(self.splashAdObj.adPicList)) {
			// 展示开屏广告
			[self showSplashAd];
		} else {
			if (self.defaultLaunchImg) {
				self.splashAdView.screenImg.image = self.defaultLaunchImg;
				[self.splashAdView showSplashAD:nil adpic:nil];
				// 2秒后移除
				[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(removeLun) userInfo:nil repeats:NO];
			} else {
				// 移除开屏广告
				[weakSelf.splashAdView removeFromSuperview];
			}
		}
	}];
}

- (void)removeLun {
	[self.splashAdView removeFromSuperview];
	if (self.closeBlock) {
		self.closeBlock();
	}
}

// 展示开屏广告
- (void)showSplashAd {
	__weak __typeof(&*self)weakSelf = self;
	if ([self canShowSplashAd:[DXPADManager sharedMgr].splashAdObj]) {
		DCAdPic *adPic = [self getAdpicItem];
		if(adPic) {
			[self.splashAdView showSplashAD:[DXPADManager sharedMgr].splashAdObj adpic:adPic];
		}
	} else {
		[self.splashAdView removeFromSuperview];
	}
}

- (DCAdPic *)getAdpicItem {
	void(^saveIndex)(NSInteger ) = ^(NSInteger index){
		manager.splashAdLastShowIndex = index;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[NSString stringWithFormat:@"%ld",index] forKey:DXP_AD_DATA_SHOW_INDEX];
	};
	
	__block DCAdPic *splachItem = nil;
	[[DXPADManager sharedMgr].splashAdObj.adPicList enumerateObjectsUsingBlock:^(DCAdPic *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.seq  == (manager.splashAdLastShowIndex + 1)) {
			splachItem = obj;
			saveIndex(obj.seq);
			*stop = YES;
		}
	}];

	if(!splachItem && !IsArrEmpty_ad([DXPADManager sharedMgr].splashAdObj.adPicList)) {
		saveIndex(1);
		[[DXPADManager sharedMgr].splashAdObj.adPicList enumerateObjectsUsingBlock:^(DCAdPic *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(obj.seq  == 1) {
				splachItem = obj;
				saveIndex(obj.seq);
				*stop = YES;
			}
		}];
	}
   
	return splachItem;
}

// 开屏频次规则。是否展示开屏广告
- (BOOL)canShowSplashAd:(DCAdDetail *)obj {
	
	if ([@"1" isEqualToString:obj.extData.ruleType]) {
		return YES;
	}
 
	NSString *userKey = isEmptyString_ad(self.userKey) ? @"nouser" : self.userKey;
	NSDictionary *dataDic = self.adShowCacheDIc[@"data"]?:@{};
	NSDictionary *userDic = [dataDic objectForKey:userKey]?:@{};
	
	NSInteger times = [[userDic objectForKey:obj.adId] integerValue];
	
	if ([@"2" isEqualToString:obj.extData.ruleType] && times < 1 ) { // 只展示一次
		return YES;
	}
	
	if ([@"3" isEqualToString:obj.extData.ruleType] && times < obj.extData.ruleValue  ) { // 一天只展示多少次
		return YES;
	}
	
	return NO;
}

// 指定ViewController进行展示
- (void)showAdWith:(UIViewController*)vc {
	NSString *clsName = NSStringFromClass(vc.class);
	NSLog(@"------- %@",clsName);
	// 遍历 弹窗广告和浮窗广告
	if (isEmptyString_ad(clsName)) {
		return;
	}
	
	bool(^canShow)(DCAdDetail *) = ^(DCAdDetail *obj) {
		if ([@"1" isEqualToString:obj.extData.ruleType] ) {
			return YES;
		}
	 
		NSString *userKey = isEmptyString_ad(self.userKey) ? @"nouser" : self.userKey;
		NSDictionary *dataDic = self.adShowCacheDIc[@"data"]?:@{};
		NSDictionary *userDic = [dataDic objectForKey:userKey]?:@{};
		
		NSInteger times = [[userDic objectForKey:obj.adId] integerValue];
		
		if ([@"2" isEqualToString:obj.extData.ruleType] && times < 1 ) { // 只展示一次
			return YES;
		}
		
		if ([@"3" isEqualToString:obj.extData.ruleType] && times < obj.extData.ruleValue  ) { // 一天只展示多少次
			return YES;
		}
		
		return NO;
	};
	
	
	// 悬浮广告
	[self.floatingAdArr enumerateObjectsUsingBlock:^(DCAdDetail *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (!isEmptyString_ad(obj.clsName)
			&& [clsName isEqualToString:obj.clsName]
			&& canShow(obj)
			&& ![self checkADViewShowed:vc andTag:HJFloatViewTag]
			&& !IsArrEmpty_ad(obj.adPicList) ) {
			
			// 设置缓存
			[self updateShowTimesCache:obj];
		 
			DCFloatingAdView *floatView = [[DCFloatingAdView alloc]initWith:obj];
			floatView.clickBlock = ^{
				if (self.floatViewClickBlock) {
					self.floatViewClickBlock();
				}
			};
			floatView.tag = HJFloatViewTag;
			[vc.view addSubview:floatView];
			[self.showViews addObject:floatView];
			//展示宣传广告
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[vc.view bringSubviewToFront:floatView];
			});
			*stop = YES;
		}
	}];
	
	// 弹窗广告
	[self.alertAdArr enumerateObjectsUsingBlock:^(DCAdDetail *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (!isEmptyString_ad(obj.clsName)
			&& [clsName isEqualToString:obj.clsName]
			&& canShow(obj)
			&& ![self checkADViewShowed:vc andTag:HJAlertADTag]
			&& !IsArrEmpty_ad(obj.adPicList) ) {
			
			//展示宣传广告
			[self updateShowTimesCache:obj];
			DCAlertAdView *alertView = [[DCAlertAdView alloc]initWith:obj];
			alertView.clickBlock = ^{
				if (self.alertViewClickBlock) {
					self.alertViewClickBlock();
				}
			};
			
			alertView.tag = HJAlertADTag;
			[vc.view addSubview:alertView];
			[self.showViews addObject:alertView];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[vc.view bringSubviewToFront:alertView];
			});
			obj.showing = YES;
			*stop = YES;
		}
	}];
}

// 判断广告是否已经展示
- (BOOL)checkADViewShowed:(UIViewController*)vc andTag:(NSInteger)viewTag {
	__block bool isShowing = NO;
	[vc.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.tag == viewTag) {
			isShowing = YES;
			*stop = YES;
		}
	}];
	return isShowing;;
}

// 报错展示缓存数据
- (void)updateShowTimesCache:(DCAdDetail *)obj {
	if (isEmptyString_ad(obj.adId)) {
		return;
	}
	
	NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithDictionary:self.adShowCacheDIc[@"data"]?:@{}];
	
	// 获取账号
	NSString *userKey = isEmptyString_ad(self.userKey) ? @"nouser" : self.userKey;
 
	// 如果有账号则使用账号  没有 key则是nouser
	NSMutableDictionary *userDicdata = [NSMutableDictionary dictionaryWithDictionary:dataDic[userKey]?:@{}];
	
	NSInteger times = [[userDicdata objectForKey:obj.adId]integerValue] ?:0;
	[userDicdata setObject:@(times + 1) forKey:obj.adId];
	
	// 设置数据
	[dataDic setObject:userDicdata forKey:userKey];
	[self.adShowCacheDIc setObject:dataDic forKey:@"data"];
	
	[[NSUserDefaults standardUserDefaults] setObject:self.adShowCacheDIc forKey:DXP_AD_DATA_SHOW_TIMES];
}

#pragma mark - 设置启动图片
- (void)setLaunchImg:(NSString*)img {
	self.defaultLaunchImg = [UIImage imageNamed:img];
}

#pragma mark - 获取广告配置接口
- (void)fetchADConfig:(void(^)(bool success))callback {
	[[DCNetAPIClient sharedClient] requestJsonDataWithPath:@"ecare/mktAd/list" withParams:@{} withMethodType:Post elementPath:@"" andBlock:^(NSDictionary* data, NSError *error) {
		NSDictionary *dic = [data objectForKey:@"data"];
		if(dic){
			NSArray *mktAdList = [dic objectForKey:@"mktAdList"];
			NSMutableArray *xxx=  [DCAdDetail mj_objectArrayWithKeyValuesArray:mktAdList];
			self.mktAdList = xxx;
			// 数据整理
			[self constructADModelWithContent];
			callback(YES);
		}else {
			callback(NO);
		}
	}];
}

// 构造数据
- (void)constructADModelWithContent {
	[self.alertAdArr removeAllObjects];
	[self.floatingAdArr removeAllObjects];
	
	[self.mktAdList enumerateObjectsUsingBlock:^(DCAdDetail * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString *cls = [self.adPageUrlDic objectForKey:obj.pageUrl] ?:@""; // 根据pageURL找对应的页面ClassName
		if (!isEmptyString_ad(cls)) {
			obj.clsName = cls; // 保存对应的clasName
		}
		if ([@"1" isEqualToString:obj.adType]) { // 开屏广告
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if (isEmptyString_ad(self.adID)) {
				// 如果换成的id为空
				[defaults setObject:obj.adId?:@"" forKey:DXP_AD_ID];
			} else {
				// 否则取出当前缓存的id
				NSString *adStr = [defaults objectForKey:DXP_AD_ID];
				if (![obj.adId isEqualToString:adStr]) { // 需要重置
					[defaults setObject:obj.adId?:@"" forKey:DXP_AD_ID];
					manager.splashAdLastShowIndex = 0;
					[defaults setObject:@"0" forKey:DXP_AD_DATA_SHOW_INDEX];
				}
			}
			self.adID = obj.adId;
			self.splashAdObj = obj;
			
		} else if ([@"2" isEqualToString:obj.adType]) { // 弹窗广告
			[self.alertAdArr addObject:obj];
		} else if ([@"3" isEqualToString:obj.adType]){ // 悬浮广告
			[self.floatingAdArr addObject:obj];
		}
	}];
}

- (void)setUserKey:(NSString *)userKey {
	_userKey = userKey;
}

// clear 清除缓存存,使用场景,切换号码
- (void)clearAd {
	[self.showViews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (obj) {
			[obj removeFromSuperview];
		}
	}];
	
	[self.showViews removeAllObjects];
	[self.mktAdList removeAllObjects];
	[self.alertAdArr removeAllObjects];
	[self.floatingAdArr removeAllObjects];
}

// MARK: 显示view
- (void)showAlertView {
	
}

- (void)showFloatView {
	
}

// MARK: LAZY
- (NSMutableArray<DCAdDetail *> *)mktAdList {
	if (!_mktAdList) {
		_mktAdList = [NSMutableArray new];
	}
	return _mktAdList;
}

- (DCSplashAdView *)splashAdView {
	if (!_splashAdView) {
		_splashAdView = [[DCSplashAdView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH_ad, SCREEN_HEIGHT_ad)];
		__weak __typeof(&*self)weakSelf = self;
		_splashAdView.clickBlock = ^(DCAdPic * _Nonnull adPic) {
			// 点击回调
			if (weakSelf.clickBlock) {
				weakSelf.clickBlock();
			}
		};
		_splashAdView.closeBlock = ^(NSString * _Nonnull str) {
			// 关闭回调
			if (weakSelf.closeBlock) {
				weakSelf.closeBlock();
			}
		};
		
	}
	return _splashAdView;
}


// 广告配置路由的配置dic，会添加全部deeplink路由
// 参考 HJUtils路由跳转
- (NSDictionary *)adPageUrlDic {
	if (!_adPageUrlDic) {
		_adPageUrlDic = [[NSDictionary alloc] init];
	}
	return _adPageUrlDic;
}

- (NSMutableArray *)alertAdArr {
	if (!_alertAdArr) {
		_alertAdArr = [NSMutableArray new];
	}
	return _alertAdArr;
}
-(NSMutableArray *)showViews{
	if (!_showViews) {
		_showViews = [NSMutableArray new];
	}
	return _showViews;
}

- (NSMutableArray *)floatingAdArr {
	if (!_floatingAdArr) {
		_floatingAdArr = [NSMutableArray new];
	}
	return _floatingAdArr;
}

- (NSMutableDictionary *)adShowCacheDIc {
	if (!_adShowCacheDIc) {
		_adShowCacheDIc = [NSMutableDictionary new];
	}
	return _adShowCacheDIc;
}

@end
