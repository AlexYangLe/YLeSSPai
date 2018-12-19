//
//  YLeBaseRequest.h
//  SSPai
//
//  Created by AlexYang on 2018/11/23.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const YLeRequestValidationErrorDomain;

NS_ENUM(NSInteger){
    YLeRequestValidationErrorInvalidStatusCode = -8,
    YLeRequestValidationErrorInvalidJSONFormat = -9,
};

//HTTP request method
typedef NS_ENUM(NSInteger,YLeRequestMethod){
    YLeRequestMethodGET = 0,
    YLeRequestMethodPOST,
    YLeRequestMethodPUT,
    YLeRequestMethodDELETE,
};
//HTTP request method
typedef NS_ENUM(NSInteger,YLeRequestSerializerType){
    YLeRequestSerializerTypeHTTP=0,
    YLeRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger, YLeResponseSerializerType){
    //NSData type
    YLeResponseSerializerTypeHTTP,
    //JSON type
    YLeResponseSerializerTypeJSON,
    // NSXMLParser type
    YLeResponseSerializerTypeXML,
};
//设置请求的优先级
typedef NS_ENUM(NSInteger, YLeRequestPriority){
    YLeRequestPriorityLow = -4L,
    YLeRequestPriorityDefault = 0,
    YLeRequestPriorityHigh = 4,
};
    
@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

@class YLeBaseRequest;

typedef void(^YLeRequestCompletionBlock)(__kindof YLeBaseRequest *request);

@protocol YleRequestDelegate <NSObject>

@optional

/**
 The request finished successfully

 @param request the Corresponding request
 */
-(void)requestFinished:(__kindof YLeBaseRequest *) request;

/**
 The request failed

 @param request the Corresponding request
 */
-(void)requestFailed:(__kindof YLeBaseRequest *) request;

@end


/**
 用于追踪请求状态，实现代理协议的对象可以执行相应的方法m，所有的方法都将在主队列中被调用
 */
@protocol YLeRequestAccessory <NSObject>

/**
 请求即将开始

 @param request The corresponding request.
 */
-(void)requestWillStart:(id)request;

/**
 请求将要结束,结束之后会执行‘requestFinished’和‘successCompletionBlock’

 @param request The corresponding request.
 */
-(void)requestWillStop:(id)request;


/**
 请求已经结束，结束之后会执行‘requestFinished’和‘successCompletionBlock’

 @param request The corresponding request.
 */
-(void)requestDidStop:(id)request;

@end


@interface YLeBaseRequest : NSObject

#pragma mark - request and response Info
//requestTask 开始是nil，可以在request开始之后调用
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
//requestTask.currentRequest 简称
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;
//requestTask.originalRequest 简称
@property (nonatomic, strong, readonly) NSURLRequest *originalRequst;
//requestTask.response 简称
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
//response status code
@property (nonatomic, readonly) NSInteger *responseStatusCode;
//响应头字段
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;
//响应的原始数据, 请求失败时此值为nil
@property (nonatomic, strong, readonly, nullable) NSData *responseData;
//响应的string，请求失败时此值为nil
@property (nonatomic, strong, readonly, nullable) NSString *responseString;
//序列化响应对象，对象的实际类型是YLeResponseSerializerType，请求失败的时候是nil
//假如使用resumableDownloadPathe和DownloadTask，这个值将成功保存文件路径(NSURL),如果失败是nil
@property (nonatomic, strong, readonly, nullable) id responseObject;
//如果使用YTKResponseSerializerTypeJSON， 响应对象的getter，否则是nil
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;
//可能是序列化错误或者网络错误，否是是nil
@property (nonatomic, strong, readonly, nullable) NSError *error;
//返回请求任务的取消状态
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
//返回请求任务的执行状态
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

#pragma mark request config
//标识请求，默认是0
@property (nonatomic) NSInteger tag;
//userInfo 可以被用来存储请求的额外信息，默认是nil
@property (nonatomic, strong, nullable) NSDictionary *userInfo;
//请求的代理对象，加入使用block可以忽略这个，默认是nil
@property (nonatomic, weak, nullable) id<YleRequestDelegate> delegate;
//成功的回调，假如这个值不是nil并且delegate的代理方法requestFinishedy也实现，两个都将被调用，但是优先调用delegate，这个block在主线程被调用
@property (nonatomic, copy, nullable) YLeRequestCompletionBlock successCompletionBlock;
//失败的回调，假如这个值不是nil并且delegate的代理方法requestFailed也实现，两个都将被调用，但是优先调用delegate，这个block在主线程被调用
@property (nonatomic, copy, nullable) YLeRequestCompletionBlock failureCompletionBlock;
//添加accessories对象，假如使用addAccessoryt增加accessory对象将自动创建数组，默认是nil
@property (nonatomic, strong,nullable) NSMutableArray<id<YLeRequestAccessory>> *requestAccessories;
//当POST请求需要时可以用来构造HTTP请求的body
@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;
//用于回复下载请求，默认nil
//值不是nil的时候，NSURLSessionDownloadTask被使用，在请求开始之前已存在的文件将会被删除，如果请求成功，文件将自动保存到这个路径，否则response将被保存到responseData和responseString.服务器必须支持range和适当的响应Last-Modified或者Etag，详情参看NSURLSessionDownloadTask
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;
//可以使用block去追踪下载进度，参考resumableDownloadPath
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;
//请求优先级，默认是YTKRequestPriorityDefault，ios8+
@property (nonatomic) YLeRequestPriority requestPriority;
//设置完成回调
-(void)setCompletionBlockWithSuccess:(nullable YLeRequestCompletionBlock)success
                             failure:(nullable YLeRequestCompletionBlock)failure;
//包含成功和失败回调
-(void)clearCompletionBlock;
//增加附加请求
-(void)addAccessory:(id<YLeRequestAccessory>)accessory;

#pragma mark request action
//增加self(请求)到请求队列并且开始请求
-(void)start;
//从请求队列删除self(请求)并且取消请求
-(void)stop;
//请求回调
-(void)startWithCompletionBlockWithSuccess:(nullable YLeRequestCompletionBlock)success
                                   failure:(nullable YLeRequestCompletionBlock)failure;

#pragma mark subclass overide
//请求成功后，切换到主线程之前，在后台线程上被调用，如果加载了缓存，这个方法将会被主线程调用，就像requestCompleteFilter
-(void)requestCompletePreprocessor;
//请求成功之后被x主线程调用
-(void)requestCompleteFilter;
//请求失败后，切换到主线程之前，在后台线程上被调用，参考requestCompletePreprocessor
-(void)requestFailedPreprocessor;
//请求失败h之后被主线程调用
-(void)requestFailedFilter;
//请求的base URL
-(NSString *)baseUrl;
//请求的url路径，将和baseurl链接使用
-(NSString *)requestUrl;
//cdn url
-(NSString *)cdnUrl;
//请求超时时间，默认60s
//当使用resumableDownloadPath(NSURLSessionDownloadTask)，可以忽略NSURLRequest的属性timeoutInterval.
-(NSTimeInterval)requestTimeoutInterval;
//增加请求参数
-(nullable id)requestArgument;
//Override this method to filter requests with certain arguments when caching.
-(id)cacheFileNameFilterForRequestArgument:(id)argument;
//HTTP request method
-(YLeRequestMethod)requestMethod;
//请求序列化类型
-(YLeRequestSerializerType)requestSerializerType;
//结果序列化类型
-(YLeResponseSerializerType)responseSerializerType;
//用于HTTP授权的userName和password @[@"Username", @"Password"].
-(nullable NSArray<NSArray *> *)requestAuthorizationHeaderFieldArray;
//增加HTTP请求头字段
-(nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary;
//创建自定义请求,方法返回非nil值，`requestUrl`, `requestTimeoutInterval`,`requestArgument`, `allowsCellularAccess`, `requestMethod` 和 `requestSerializerType` 将被忽略
-(nullable NSURLRequest *)buildCustomUrlRequest;

//发送请求时使用CDN
-(BOOL)useCDN;
//是否使用无线网络，默认是YES
-(BOOL)allowsCellularAccess;
//验证responseJSONObject的格式是否正确
-(nullable id)jsonValidator;
//验证responseStatusCode是否有效
-(BOOL)statusCodeValidator;

@end

NS_ASSUME_NONNULL_END
