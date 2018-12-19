//
//  YLeNetworkAgent.h
//  SSPai
//
//  Created by AlexYang on 2018/11/26.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YLeBaseRequest;

NS_ASSUME_NONNULL_BEGIN
//是网络请求底层，主要处理实际请求生成、序列化、结果响应请求
@interface YLeNetworkAgent : NSObject

+(instancetype)new;
-(instancetype)init;

+(YLeNetworkAgent *)shareAgent;
//添加请求到回话，并且启动
-(void)addRequest:(YLeBaseRequest *)request;
//取消先前添加的请求
-(void)cancelRequest:(YLeBaseRequest *)request;
//取消先前添加的所有请求
-(void)cancelAllRequest;


/**
 返回请求的url

 @param request 要解析的请求，不为nil
 @return result Url
 */
-(NSString *)buildRequestUrl:(YLeBaseRequest *)request;






@end

NS_ASSUME_NONNULL_END
