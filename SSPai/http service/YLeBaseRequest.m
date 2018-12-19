//
//  YLeBaseRequest.m
//  SSPai
//
//  Created by AlexYang on 2018/11/23.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import "YLeBaseRequest.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NSString *const YLeRequestValidationErrorDomain = @"com.YLe.request.validation";

@interface YLeBaseRequest ()
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;
@end


@implementation YLeBaseRequest

#pragma mark - request and response Information

-(NSHTTPURLResponse *)response{
    return (NSHTTPURLResponse *)self.requestTask.response;
}

-(NSInteger)responseStatusCode{
    return self.response.statusCode;
}

-(NSDictionary *)responseHeaders{
    return self.response.allHeaderFields;
}

-(NSURLRequest *)currentRequest{
    return self.requestTask.currentRequest;
}

-(NSURLRequest *)originalRequst{
    return self.requestTask.originalRequest;
}

-(BOOL)isCancelled{
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

-(BOOL)isExecuting{
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark request Configuration
-(void)setCompletionBlockWithSuccess:(YLeRequestCompletionBlock)success failure:(YLeRequestCompletionBlock)failure{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

-(void)clearCompletionBlock{
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

-(void)addAccessory:(id<YLeRequestAccessory>)accessory{
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark request action
-(void)start{
    
}

-(void)stop{
    
}

-(void)startWithCompletionBlockWithSuccess:(YLeRequestCompletionBlock)success failure:(YLeRequestCompletionBlock)failure{
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - Subclass Override

- (void)requestCompletePreprocessor {
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (NSString *)requestUrl {
    return @"";
}

- (NSString *)cdnUrl {
    return @"";
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (id)requestArgument {
    return nil;
}

- (id)cacheFileNameFilterForRequestArgument:(id)argument {
    return argument;
}

-(YLeRequestMethod)requestMethod{
    return YLeRequestMethodGET;
}

-(YLeRequestSerializerType)requestSerializerType{
    return YLeRequestSerializerTypeHTTP;
}

-(YLeResponseSerializerType)responseSerializerType{
    return YLeResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}

- (BOOL)useCDN {
    return NO;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (id)jsonValidator {
    return nil;
}

-(BOOL)statusCodeValidator{
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

#pragma mark NSObject

-(NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}




@end
