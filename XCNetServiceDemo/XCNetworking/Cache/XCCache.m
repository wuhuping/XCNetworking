//
//  XCCache.m
//  XCNetServiceDemo
//
//  Created by wuhuping on 15/8/18.
//  Copyright (c) 2015年 cd_xc. All rights reserved.
//

#import "XCCache.h"
#import "XCCacheObject.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
@interface XCCache ()

/** 内存缓存 **/
@property (strong, nonatomic) NSCache *memCache;

/** 磁盘缓存路径 **/
@property (strong, nonatomic) NSString *diskCachePath;

/** 磁盘操作队列 **/
@property (strong, nonatomic) dispatch_queue_t ioQueue;

@end

@implementation XCCache {
    NSFileManager *_fileManager;
}

#pragma mark - Life Cycle
+ (id)sharedCache
{
    static XCCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XCCache alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.cachePolicy = XCCacheTypeDisk;
        self.maxMemoryLimit = NSUIntegerMax;
        
        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.yzm.ios.XCCache", DISPATCH_QUEUE_SERIAL);
        
        // Init the disk cache
        NSString *fullNamespace = @"com.yzm.ios.XCCache";
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
        
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemoryCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Public Method
- (NSString *)keyWithMethodName:(NSString *)methodName
                         params:(NSDictionary *)params
{
    if (!methodName) {
        return nil;
    }else {
        NSString *key = nil;
        if (params) {
            key = [NSString stringWithFormat:@"%@%@", methodName, params];
        }else {
            key = methodName;
        }
        key = [self cachedFileNameForKey:key];
        return key;
    }
}

- (void)saveCacheData:(NSData *)cacheData
                  key:(NSString *)key
{
    [self saveCacheData:cacheData key:key cacheDataType:XCCacheDataTypeNormal];
}

- (void)saveCacheData:(NSData *)cacheData
                  key:(NSString *)key
        cacheDataType:(XCCacheDataType)cacheDataType
{
    if (key == nil) {
        return;
    }
    
    //Cache to disk
    if ((self.cachePolicy&XCCacheTypeDisk) == XCCacheTypeDisk) {
        if (![_fileManager fileExistsAtPath:_diskCachePath]) {
            [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES
                                     attributes:nil error:NULL];
        }
        
        XCCacheObject *cacheObject = cacheObject = [self queryXCCacheObjectDataFromDisk:key
                                                                          cacheDataType:cacheDataType];;
        if (cacheObject == nil) {
            cacheObject = [[XCCacheObject alloc] init];
        }
        [cacheObject updateData:cacheData];
        [cacheObject updateCacheDataType:cacheDataType];
        
        NSData *serializaData = [NSKeyedArchiver archivedDataWithRootObject:cacheObject];
        [_fileManager createFileAtPath:[self diskCachePathForKey:key cacheDataType:cacheDataType]
                              contents:serializaData attributes:nil];
    }
    
    //Cache to memory
    if ((self.cachePolicy&XCCacheTypeMemory) == XCCacheTypeMemory) {
        key = [self cachedFileNameForKey:key];
        XCCacheObject *cacheObject = [self queryXCCacheObjectDataFromMemory:key];
        if (cacheObject == nil) {
            cacheObject = [[XCCacheObject alloc] init];
        }
        [cacheObject updateData:cacheData];
        [cacheObject updateCacheDataType:cacheDataType];
        
        [self.memCache setObject:cacheObject forKey:key];
    }
}

- (void)fetchDataWithKey:(NSString *)key completion:(XCNetworkCacheDataQueryCompletedBlock)completion
{
    [self fetchDataWithKey:key completion:completion cacheDataType:XCCacheDataTypeNormal];
}

- (void)fetchDataWithKey:(NSString *)key
              completion:(XCNetworkCacheDataQueryCompletedBlock)completion
           cacheDataType:(XCCacheDataType)cacheDataType
{
    if (key == nil) {
        if (completion) {
            completion(nil, XCCacheTypeNone);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //query memory cache
        XCCacheObject *memCachedObject = [self queryXCCacheObjectDataFromMemory:key];
        if (!memCachedObject.isOutdated && !memCachedObject.isEmpty) {
            completion(memCachedObject.data, XCCacheTypeMemory);
            
            return;
        }
        
        //query disk cache
        dispatch_async(self.ioQueue, ^{
            XCCacheObject *diskCacheObject = [self queryXCCacheObjectDataFromDisk:key cacheDataType:cacheDataType];
            if (diskCacheObject && memCachedObject) {
                if ([diskCacheObject.lastUpdateTime compare:memCachedObject.lastUpdateTime] == NSOrderedAscending) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(memCachedObject.data, XCCacheTypeMemory);
                        });
                    }
                }else {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(diskCacheObject.data, XCCacheTypeDisk);
                        });
                    }
                }
            }else if (memCachedObject) {
                if (!memCachedObject.isOutdated && !memCachedObject.isEmpty) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(memCachedObject.data, XCCacheTypeMemory);
                        });
                    }
                }else {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, XCCacheTypeNone);
                        });
                    }
                }
            }else if (diskCacheObject) {
                if (!diskCacheObject.isOutdated && !diskCacheObject.isEmpty) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(diskCacheObject.data, XCCacheTypeDisk);
                        });
                    }
                }else {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil, XCCacheTypeNone);
                        });
                    }
                }
            }
        });
    });
}

- (void)removeCacheWithKey:(NSString *)key withCompletion:(XCNetworkNoParamsBlock)completion
{
    [self removeCacheWithKey:key withCompletion:completion cacheDataType:XCCacheDataTypeNormal];
}

- (void)removeCacheWithKey:(NSString *)key
            withCompletion:(XCNetworkNoParamsBlock)completion
             cacheDataType:(XCCacheDataType)cacheDataType
{
    if (key == nil) {
        completion();
    }
    
    //remove memory cache
    [self.memCache removeObjectForKey:key];
    
    //remove disk cache
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:[self diskCachePathForKey:key cacheDataType:cacheDataType] error:nil];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)clearMemoryCache
{
    [self.memCache removeAllObjects];
}

- (void)clearDiskCacheForType:(XCCacheDataType)cacheDataType
               withCompletion:(XCNetworkNoParamsBlock)completion
{
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:[self diskCachePathForCacheDataType:cacheDataType] error:nil];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)clearDiskCache:(XCNetworkNoParamsBlock)completion
{
    [self clearDiskCache:completion cacheDataType:XCCacheDataTypeNormal];
}

- (void)clearDiskCache:(XCNetworkNoParamsBlock)completion
         cacheDataType:(XCCacheDataType)cacheDataType
{
    dispatch_async(self.ioQueue, ^{
        NSString *cachePath = [self diskCachePathForCacheDataType:cacheDataType];
        [_fileManager removeItemAtPath:cachePath error:nil];
        [_fileManager createDirectoryAtPath:cachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

#pragma mark - Private Method
- (NSString *)diskCachePathForKey:(NSString *)key cacheDataType:(XCCacheDataType)cacheDataType
{
    NSString *filename = [self cachedFileNameForKey:key];
    switch (cacheDataType) {
        case XCCacheDataTypeNormal:
        {
            return [[self diskCachePathForCacheDataType:XCCacheDataTypeNormal] stringByAppendingString:filename];
        }
            break;
            
        default:
            return nil;
            break;
    }
    return nil;
}

- (NSString *)diskCachePathForCacheDataType:(XCCacheDataType)cacheDataType
{
    switch (cacheDataType) {
        case XCCacheDataTypeNormal:
        {
            return [self.diskCachePath stringByAppendingPathComponent:kDiskCachePathNameForCacheDataTypeNormal];
        }
            break;
            
        default:
            return nil;
            break;
    }
}

- (NSData *)diskDataWithKey:(NSString *)key cacheDataType:(XCCacheDataType)cacheDataType
{
    NSString *cachePath = [self diskCachePathForKey:key cacheDataType:cacheDataType];
    NSData *data = [NSData dataWithContentsOfFile:cachePath];
    
    return data;
}

- (XCCacheObject *)queryXCCacheObjectDataFromMemory:(NSString *)key
{
    XCCacheObject *cachedObject = [self.memCache objectForKey:key];
    return cachedObject;
}

- (XCCacheObject *)queryXCCacheObjectDataFromDisk:(NSString *)key cacheDataType:(XCCacheDataType)cacheDataType
{
    NSData *cacheData = [self diskDataWithKey:key cacheDataType:cacheDataType];
    
    XCCacheObject *cachedObject = (XCCacheObject *)[NSKeyedUnarchiver unarchiveObjectWithData:cacheData];
    
    return cachedObject;
}

#pragma mark - Hepler
- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

#pragma mark - Setter & Getter
- (NSCache *)memCache
{
    if (_memCache == nil) {
        _memCache = [[NSCache alloc] init];
        _memCache.countLimit = self.maxMemoryLimit;
    }
    
    return _memCache;
}

- (void)setMaxMemoryLimit:(NSUInteger)maxMemoryLimit
{
    _maxMemoryLimit = maxMemoryLimit;
    [self.memCache setCountLimit:maxMemoryLimit];
}

@end
