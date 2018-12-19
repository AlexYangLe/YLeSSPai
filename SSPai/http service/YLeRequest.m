//
//  YLeRequest.m
//  SSPai
//
//  Created by AlexYang on 2018/11/29.
//  Copyright © 2018 AlexYang. All rights reserved.
//

#import "YLeRequest.h"
#import "YLeNetworkConfig.h"
#import "YLeNetworkAgent+Private.h"

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

NSString *const YLeRequestCacheErrorDomain = @"com.YLe.request.caching";

static dispatch_queue_t ylerequest_cache_writing_queue(){
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("com.YLe.YLeRequest.caching", attr);
    });
    return queue;
}

@interface YLeCacheMetadata : NSObject<NSSecureCoding>
@property (nonatomic, assign) long long version;
@property (nonatomic, strong) NSString *sensitiveDataString;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSString *appVersionString;

@end

@implementation YLeCacheMetadata

+(BOOL)supportsSecureCoding{
    return YES;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.sensitiveDataString forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    [aCoder encodeObject:@(self.stringEncoding) forKey:NSStringFromSelector(@selector(stringEncoding))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
                                                                            
}

-(nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(version))] integerValue];
    self.sensitiveDataString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    self.stringEncoding = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(stringEncoding))] integerValue];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(appVersionString))];
    return self;
}


@end

@interface YLeRequest()

@property (nonatomic, strong) NSData *cacheData;
@property (nonatomic, strong) NSString *cacheString;
@property (nonatomic, strong) id cacheJSON;
@property (nonatomic, strong) NSXMLParser *cacheXML;

@property (nonatomic, strong) YLeCacheMetadata *cacheMetadata;
@property (nonatomic, assign) BOOL dataFromCache;


@end

@implementation YLeRequest

-(void)start{
    if (self.ignoreCache) {
        [self startWithoutCache];
        return;
    }
    //h不缓存下载请求
    if (self.resumableDownloadPath) {
        [self startWithoutCache];
        return;
    }
    
    if (![self loadCacheWithError:nil]) {
        [self startWithoutCache];
        return;
    }
    
    _dataFromCache = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestCompletePreprocessor];
        [self requestCompleteFilter];
        YLeRequest *strongSelf = self;
        //请求回调优先选择delegate
        [strongSelf.delegate requestFinished:strongSelf];
        if (strongSelf.successCompletionBlock) {
            strongSelf.successCompletionBlock(strongSelf);
        }
        [strongSelf clearCompletionBlock];
    });
}

-(void)startWithoutCache{
    [self clearCacheVariables];
    [super start];
}

#pragma mark - NetWork Request Delegate
-(void)requestCompletePreprocessor{
    [super requestCompletePreprocessor];
    if (self.writeCacheAsynchronously) {
        dispatch_async(ylerequest_cache_writing_queue(), ^{
            [self saveResponseDataCacheFile:[super responseData]];
        });
    }else{
        [self saveResponseDataCacheFile:[super responseData]];
    }
}

#pragma mark Subclass Override
-(NSInteger)cacheTimeInSeconds{
    return -1;
}

-(long long)cacheVersion{
    return 0;
}

-(id)cacheSensitiveData{
    return nil;
}

-(BOOL)writeCacheAsynchronously{
    return YES;
}

#pragma mark -
-(BOOL)isDataFromCache{
    return _dataFromCache;
}

-(NSData *)responseData{
    if (_cacheData) {
        return _cacheData;
    }
    
    return [super responseData];
}

-(NSString *)responseString{
    if (_cacheString) {
        return _cacheString;
    }
    return [super responseString];
}

-(id)responseJSONObject{
    if (_cacheJSON) {
        return _cacheJSON;
    }
    return [super responseJSONObject];
}

-(id)responseObject{
    if(_cacheJSON){
        return _cacheJSON;
    }
    if (_cacheXML) {
        return _cacheXML;
    }
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseObject];
}

#pragma mark ---
-(BOOL)loadCacheWithError:(NSError * _Nullable __autoreleasing *)error{
    //make sure cache time in valid
    if ([self cacheTimeInSeconds] < 0) {
        if (error) {
            *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorInvalidCacheTime userInfo:@{NSLocalizedDescriptionKey:@"Invalid cached time"}];
        }
        return NO;
    }
    
    //try load metadata
    if (![self loadCacheMetadata]) {
        if (error) {
            *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorInvalidMetadata userInfo:@{NSLocalizedDescriptionKey:@"Invalid metadara. Cache may not exist"}];
        }
        return NO;
    }
    
    //Check if cache is stall valid
    if (![self loadCacheWithError:error]) {
        return NO;
    }
    
    if (![self loadCacheData]) {
        if (error) {
            *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorInvalidCacheData userInfo:@{NSLocalizedDescriptionKey:@"Invalid cache data"}];
        }
        return NO;
    }
    return YES;
}

-(BOOL)validateCacheWithError:(NSError * _Nullable __autoreleasing *)error{
    //Date
    NSDate *creationDate = self.cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > [self cacheTimeInSeconds]) {
        if (error) {
            *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorExpired userInfo:@{NSLocalizedDescriptionKey:@"Cache expired"}];
        }
        return NO;
    }
    //Version
    long long cacheVersionFileContent = self.cacheMetadata.version;
    if (cacheVersionFileContent != [self cacheVersion]) {
        if (error) {
            *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorVersionMismatch userInfo:@{NSLocalizedDescriptionKey:@"Cache version mismatch"}];
        }
        return NO;
    }
    
    //sensitive data
    NSString *sensitiveDataString = self.cacheMetadata.sensitiveDataString;
    NSString *currentSensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
    if (sensitiveDataString || currentSensitiveDataString) {
        //假如其中一个字符串是nil，将会触发短路
        if (sensitiveDataString.length != currentSensitiveDataString.length || ![sensitiveDataString isEqualToString:currentSensitiveDataString]) {
            if (error) {
                *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorSensitiveDataMismatch userInfo:@{NSLocalizedDescriptionKey:@"Cache sensitive data mismatch"}];
            }
            return NO;
        }
    }
    
    //app version
    NSString *appVersionString = self.cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [YLeNetworkUtils appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length || ![appVersionString isEqualToString:currentAppVersionString]) {
            if (error) {
                *error = [NSError errorWithDomain:YLeRequestCacheErrorDomain code:YleRequestCacheErrorAppVersionMismatch userInfo:@{NSLocalizedDescriptionKey:@"APP Version mismatch"}];
            }
            return NO;
        }
    }
    return YES;
    
}

-(BOOL)loadCacheMetadata{
    NSString *path = [self cacheMetadataFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        @try {
            _cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return YES;
        } @catch (NSException *exception) {
            NSLog(@"Load cache metadata failed, reason = %@", exception.reason);
            return NO;
        }
    }
    return NO;
}

-(BOOL)loadCacheData{
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        _cacheData = data;
        _cacheString = [[NSString alloc] initWithData:_cacheData encoding:self.cacheMetadata.stringEncoding];
        switch (self.responseSerializerType) {
            case YLeResponseSerializerTypeHTTP:
                return YES;
            case YLeResponseSerializerTypeJSON:
                _cacheJSON = [NSJSONSerialization JSONObjectWithData:_cacheData options:(NSJSONReadingOptions)0 error:&error];
                return error == nil;
            case YLeResponseSerializerTypeXML:
                _cacheXML = [[NSXMLParser alloc] initWithData:_cacheData];
                return YES;
        }
    }
    return NO;
}

-(void)saveResponseDataCacheFile:(NSData *)data{
    if ([self cacheTimeInSeconds] > 0 && ![self isDataFromCache]) {
        if (data != nil) {
            @try {
                //新数据重写l覆盖老数据
                [data writeToFile:[self cacheFilePath] atomically:YES];
                
                YLeCacheMetadata *metadata = [[YLeCacheMetadata alloc] init];
                metadata.version = [self cacheVersion];
                metadata.sensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
                metadata.stringEncoding = [YLeNetworkUtils stringEncodingWithRequest:self];
                metadata.creationDate = [NSDate date];
                metadata.appVersionString = [YLeNetworkUtils appVersionString];
                [NSKeyedArchiver archiveRootObject:metadata toFile:[self cacheMetadataFilePath]];
            } @catch (NSException *exception) {
                NSLog(@"Save cache failed,reason=%@",exception.reason);
            }
        }
    }
}


-(void)clearCacheVariables{
    _cacheData = nil;
    _cacheXML = nil;
    _cacheJSON = nil;
    _cacheString = nil;
    _cacheMetadata = nil;
    _dataFromCache = NO;
}

#pragma mark -
-(void)createDirectoryIfNeeded:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    }else{
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

-(void)createBaseDirectoryAtPath:(NSString *)path{
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        NSLog(@"create cache directory failed, error = %@", error);
    }else{
        [YLeNetworkUtils addDoNotBackupAttribute:path];
    }
}


-(NSString *)cacheBasePath{
    NSString *pathOfLLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    
    //Filter cache base path
    NSArray<id<YLeCacheDirPathFilterProtocol>> *filters = [[YLeNetworkConfig sharedConfig] cacheDirPathFilters];
    if (filters.count > 0) {
        for (id<YLeCacheDirPathFilterProtocol> f in filters) {
            path= [f filterCacheDirPath:path withRequest:self];
        }
    }
    [self createDirectoryIfNeeded:path];
    return path;
}


-(NSString *)cacheFileName{
    NSString *requestUrl = [self requestUrl];
    NSString *baseUrl = [YLeNetworkConfig sharedConfig].baseUrl;
    id argument = [self cacheFileNameFilterForRequestArgument:[self requestArgument]];
    NSString *requestInfo = [NSString stringWithFormat:@"Methid:%ld Host:%@ Url:%@ argument: %@", (long)[self requestMethod], baseUrl, requestUrl, argument];
    
    NSString *cacheFileName = [YLeNetworkUtils md5StringFromString:requestInfo];
    return cacheFileName;
}

-(NSString *)cacheFilePath{
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}



-(NSString *)cacheMetadataFilePath{
    NSString *cacheMedaydayaFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMedaydayaFileName];
    return path;
}

@end
