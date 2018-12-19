//
//  YLeNetworkConfig.m
//  SSPai
//
//  Created by AlexYang on 2018/11/28.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import "YLeNetworkConfig.h"
#import "YLeBaseRequest.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


@implementation YLeNetworkConfig{
    NSMutableArray<id<YLeUrlFilterProtocol>> *_urlFilters;
    NSMutableArray<id<YLeCacheDirPathFilterProtocol>> *_cacheDirPathFilters;
}

+(YLeNetworkConfig *)sharedConfig{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _baseUrl = @"";
        _cdnUrl = @"";
        _urlFilters = [NSMutableArray array];
        _cacheDirPathFilters = [NSMutableArray array];
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return self;
}

-(void)addUrlFilter:(id<YLeUrlFilterProtocol>)filter{
    [_urlFilters addObject:filter];
}

-(void)clearUrlFilter{
    [_urlFilters removeAllObjects];
}

-(void)addCacheDirPathFilter:(id<YLeCacheDirPathFilterProtocol>)filter{
    [_cacheDirPathFilters addObject:filter];
}

-(void)clearCacheDirPathFilter{
    [_cacheDirPathFilters removeAllObjects];
}

-(NSArray<id<YLeUrlFilterProtocol>> *)urlFilters{
    return [_urlFilters copy];
}

-(NSArray<id<YLeCacheDirPathFilterProtocol>> *)cacheDirPathFilters{
    return [_cacheDirPathFilters copy];
}

#pragma mark NSObject
-(NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}





@end
