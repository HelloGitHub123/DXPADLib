//
//  HJADWKWebViewHandler.m
//
//
//  DITOApp
//
//  Created by mac on 2021/6/22.

#import "HJADWKWebViewHandler.h"
#import <objc/runtime.h>
#import "HJ_ADJSHandler.h"

@interface HJADWKWebViewHandler () <WKScriptMessageHandler>
@property (nonatomic, strong) id jsExport;
@property (nonatomic, strong) WKUserContentController *userContent;

@property (nonatomic, strong) NSMutableArray *methods;
@property (nonatomic, strong) NSMutableArray *returnMethods;
@property (nonatomic, copy) NSString *bindName;
@property (nonatomic, strong) NSMutableString *jsHandler;
@end
@implementation HJADWKWebViewHandler

- (instancetype)initWithUserContent:(WKUserContentController *)userContent{
    if (self = [super init]) {
        self.userContent = userContent;
    }
    return self;
}

- (void)removeAllMessageHandler{
    for (NSString *name in self.methods) {
        [self.userContent removeScriptMessageHandlerForName:name];
    }
}
- (void)configureWithJSExport:(id)jsExport bindName:(NSString *)name{
    self.jsExport = jsExport;
    self.bindName = name;
    [self getProtocolMethod];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    for (NSString *name in self.methods ) {
        if ([message.name isEqualToString:name]) {
            SEL method1 = NSSelectorFromString(name);
            if (message.body != nil && ![message.body isKindOfClass:[NSNull class]]) {
                SEL method2 = NSSelectorFromString([name stringByAppendingString:@":"]);
                if (method2 && [self.jsExport respondsToSelector:method2]) {
                    [self.jsExport performSelector:method2 withObject:message.body];
                }else if (method1 && [self.jsExport respondsToSelector:method1]) {
                    [self.jsExport performSelector:method1 withObject:message.body];
                }
            }else if (method1 && [self.jsExport respondsToSelector:method1]) {
                [self.jsExport performSelector:method1 withObject:message.body];
            }
            break;
        }
    }
}

- (id)performWithSel:(NSString *)sel withObject:(id)object{
     SEL method1 = NSSelectorFromString(sel);
     if (object != nil && ![object isKindOfClass:[NSNull class]]) {
         SEL method2 = NSSelectorFromString([sel stringByAppendingString:@":"]);
         if (method2 && [self.jsExport respondsToSelector:method2]) {
             return [self.jsExport performSelector:method2 withObject:object];
         }else if (method1 && [self.jsExport respondsToSelector:method1]) {
             return [self.jsExport performSelector:method1 withObject:object];
         }
     }else if (method1 && [self.jsExport respondsToSelector:method1]) {
         return [self.jsExport performSelector:method1 withObject:object];
     }
    return nil;
}

- (void)getProtocolMethod{
    self.methods = [@[] mutableCopy];
    self.returnMethods = [@[] mutableCopy];
    unsigned int protocalCount;
    self.jsHandler = [[NSMutableString alloc] initWithFormat:@"var %@ = {",self.bindName];

    if(![[NSString stringWithUTF8String:class_getName([self.jsExport class])] isEqualToString:@"HJ_ADJSHandler"])
    {
        id parent =  self.parentJsExport;
        //获取父类协议列表
        __unsafe_unretained Protocol **protocolList = class_copyProtocolList([HJ_ADJSHandler class], &protocalCount);
        Protocol *jsExport;
        for (unsigned int i = 0; i< protocalCount; i++) {
            Protocol *myProtocal = protocolList[i];
            if (protocol_conformsToProtocol(myProtocal, NSProtocolFromString(@"HJJavaScriptExport"))) {
                jsExport = myProtocal;
                break;
            }
        }
        free(protocolList);
       /* 获取方法列表描述 ,并拼接js*/
        
        [self.jsHandler appendString:[self getJS:jsExport optional:YES]];
        [self.jsHandler appendString:[self getJS:jsExport optional:NO]];
//        free(protocolList);

    }
    
    //获取协议列表
    __unsafe_unretained Protocol **protocolList = protocolList = class_copyProtocolList([self.jsExport class], &protocalCount);
    Protocol *jsExport;
    for (unsigned int i = 0; i< protocalCount; i++) {
        Protocol *myProtocal = protocolList[i];
        if (protocol_conformsToProtocol(myProtocal, NSProtocolFromString(@"HJJavaScriptExport"))) {
            jsExport = myProtocal;
            break;
        }
    }
    free(protocolList);
//    self.jsHandler = [[NSMutableString alloc] initWithFormat:@"var %@ = {",self.bindName];
   /* 获取方法列表描述 ,并拼接js*/
    
    [self.jsHandler appendString:[self getJS:jsExport optional:YES]];
    [self.jsHandler appendString:[self getJS:jsExport optional:NO]];
    [self.jsHandler appendFormat:@"};"];
    [self.userContent removeAllUserScripts];
    WKUserScript *jsUserScript = [[WKUserScript alloc] initWithSource:self.jsHandler injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];

    [self.userContent addUserScript:jsUserScript];
}

- (NSString *)getJS:(Protocol *)protocol optional:(BOOL)optional{
    
    NSMutableString *js = [@"" mutableCopy];
    unsigned int methodCount = 0;
    if (protocol) {
        struct objc_method_description *method_description_list = protocol_copyMethodDescriptionList(protocol, optional, YES, &methodCount);
        for (int i = 0; i < methodCount ; i ++) {
            struct objc_method_description description = method_description_list[i];
            NSString *methName = [NSStringFromSelector(description.name) stringByReplacingOccurrencesOfString:@":"
                                                                                                   withString:@""];
            NSString *type = [NSString stringWithUTF8String:description.types];
            NSLog(@"index:%d name:%@ type:%@",i,NSStringFromSelector(description.name),[NSString stringWithUTF8String:description.types]);
            if ([type hasPrefix:@"v"]) {
                [self.methods addObject:methName];
                [self.userContent addScriptMessageHandler:self name:methName];
                [js appendFormat:@"\
                 %@: function(params){    \
                 if (window.webkit.messageHandlers.%@ != undefined){\
                 window.webkit.messageHandlers.%@.postMessage(params);\
                 }\
                 },",methName,methName,methName];
            } else {
                [self.returnMethods addObject:methName];
                [js appendFormat:@"\
                 %@: function(params){\
                 return window.prompt('%@',params);\
                 },",methName,methName];
            }
        }
        free(method_description_list);
    }

    return [js copy];
}

- (id)parentJsExport
{
    if(!_parentJsExport){
        _parentJsExport = [[HJ_ADJSHandler alloc]initWithViewController:((HJ_ADJSHandler*)self.jsExport).webViewController];
    }
    return _parentJsExport;

}

@end
