//
//  YLeNetworkAgent+Private.h
//  SSPai
//
//  Created by AlexYang on 2018/11/27.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import "YLeNetworkAgent.h"
#import "YLeBaseRequest.h"
#import "YLeNetworkAgent.h"

NS_ASSUME_NONNULL_BEGIN
@class AFHTTPSessionManager;
@interface YLeNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

+ (void)addDoNotBackupAttribute:(NSString *)path;

+ (NSString *)md5StringFromString:(NSString *)string;

+ (NSString *)appVersionString;

+ (NSStringEncoding)stringEncodingWithRequest:(YLeBaseRequest *)request;

+ (BOOL)validateResumeData:(NSData *)data;

@end

@interface YLeBaseRequest(Setter)
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;
@end

@interface YLeBaseRequest (RequestAccessory)
- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;
@end

@interface YLeNetworkAgent (Private)
- (AFHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;
@end

NS_ASSUME_NONNULL_END
