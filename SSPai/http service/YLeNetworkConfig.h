//
//  YLeNetworkConfig.h
//  SSPai
//
//  Created by AlexYang on 2018/11/28.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YLeBaseRequest;
@class AFSecurityPolicy;

//在发送请求之前用来增加公共的参数到请求
@protocol YLeUrlFilterProtocol <NSObject>

/**
 在发送请求之前对Url进行预处理

 @param originUrl 请求的源Url，由requestUrl返回
 @param requestLe
 @return 新url，将被用作一个新的requestUrl
 */
-(NSString *)filterUrl:(NSString *)originUrl withRequest:(YLeBaseRequest *)request;

@end

@protocol YLeCacheDirPathFilterProtocol <NSObject>


/**
 实际保存之前，预处理缓存路径

 @param originPath 原始的基本缓存路径，在YLeRequest中生成
 @param request request
 @return 缓存时用作基本路径的新路径
 */
-(NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(YLeBaseRequest *)request;

@end


//存储与网络相关的全局配置，在YleNetworkAgent中使用，形成和过滤请求，以及缓存响应。
@interface YLeNetworkConfig : NSObject

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)new NS_UNAVAILABLE;

+(YLeNetworkConfig *)sharedConfig;
//请求base URL.默认是empty string
@property (nonatomic, strong) NSString *baseUrl;
//request cdn Url.默认是empty string
@property (nonatomic, strong) NSString *cdnUrl;
//URL过滤器
@property (nonatomic, strong, readonly) NSArray<id<YLeUrlFilterProtocol>> *urlFilters;
//缓存路径过滤器
@property (nonatomic, strong, readonly) NSArray<id<YLeCacheDirPathFilterProtocol>> *cacheDirPathFilters;
//AFNetworking 安全使用策略
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
//SessionConfiguration 将用于初始化AFHTTPSessionManager,默认是nil
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

//增加一个新的url 过滤器
-(void)addUrlFilter:(id<YLeUrlFilterProtocol>)filter;
//清除所有的url 过滤器
-(void)clearUrlFilter;
//增加一个新的缓存路径的过滤器
-(void)addCacheDirPathFilter:(id<YLeCacheDirPathFilterProtocol>)filter;
//清除所有的缓存路径的过滤器
-(void)clearCacheDirPathFilter;
@end

NS_ASSUME_NONNULL_END
