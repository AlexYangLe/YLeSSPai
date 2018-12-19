//
//  YLeRequest.h
//  SSPai
//
//  Created by AlexYang on 2018/11/29.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import "YLeBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const YLeRequestCacheErrorDomain;

NS_ENUM(NSInteger){
    YleRequestCacheErrorExpired = -1,
    YleRequestCacheErrorVersionMismatch = -2,
    YleRequestCacheErrorSensitiveDataMismatch = -3,
    YleRequestCacheErrorAppVersionMismatch = -4,
    YleRequestCacheErrorInvalidCacheTime = -5,
    YleRequestCacheErrorInvalidMetadata = -6,
    YleRequestCacheErrorInvalidCacheData = -7,
};

//创建请求时集成的基类，YLeRequest具有缓存功能，注意：下载请求将不会缓存，因为下载请求可能涉及由`Cache-Control`, `Last-Modified`等控制的复杂的缓存控制策略.
@interface YLeRequest : YLeBaseRequest
//是否使用缓存作为相应，默认是NO，缓存h将在特定参数下生效.
//注意这个cacheTimeInSeconds是-1,因此缓存数据实际上不会用作响应，除非你在cacheTimeInSeconds返回正值
//不会影响存储响应，意味着响应始终被保存，即使ignoreCache是YES
@property (nonatomic, assign) BOOL ignoreCache;
//数据是否来自本地缓存
-(BOOL)isDataFromCache;

//从存储中手动加载缓存
//param error 假如发生错误导致缓存加载失败，将传递错误对象，否则是NULL
//return 缓存是否成功加载
-(BOOL)loadCacheWithError:(NSError * __autoreleasing *)error;
//启动请求时，即使本地存在，也不读取本地缓存，使用它更新本地缓存
-(void)startWithoutCache;
//将响应数据保存到该请求缓存为位置（可能来自其他的请求）
-(void)saveResponseDataCacheFile:(NSData *)data;

#pragma mark -Subclass Override
//缓存的最长时间，默认是-1，响应实际并不为保存在缓存
-(NSInteger)cacheTimeInSeconds;
//版本可以用来标识和使本地的缓存失效
-(long long)cacheVersion;

/**
 告诉缓存需要更新的附加标识符，该对象的description字符串将用作标识符，来验证缓存是否有效，建议使用NSArray或者NSDictionary作为返回值类型，但是，如果你打算使用自定义类类型，确保正确的实现description
 */
-(nullable id)cacheSensitiveData;
//缓存是否异步写入存储
-(BOOL)writeCacheAsynchronously;
@end

NS_ASSUME_NONNULL_END
