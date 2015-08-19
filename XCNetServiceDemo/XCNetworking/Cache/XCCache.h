//
//  XCCache.h
//  XCNetServiceDemo
//
//  Created by wuhuping on 15/8/18.
//  Copyright (c) 2015年 cd_xc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCNetworkConfig.h"
@interface XCCache : NSObject

/** 最大内存缓存 **/
@property (nonatomic, assign) NSUInteger maxMemoryLimit;
/** 缓存策略 **/
@property (nonatomic, assign) XCCacheType cachePolicy;

+ (id)sharedCache;

/** 网络请求返回数据缓存key,如有其它类型的数据需要缓存,需要添加对应的生成key的方法 **/
- (NSString *)keyWithMethodName:(NSString *)methodName
                         params:(NSDictionary *)params;

/** 以下方法未指定缓存数据类型时,缓存数据类型默认为XCCacheDataTypeNormal,
    所有的磁盘缓存分区缓存,内存缓存共用 **/
- (void)saveCacheData:(NSData *)cacheData
                  key:(NSString *)key;
- (void)saveCacheData:(NSData *)cacheData
                  key:(NSString *)key
        cacheDataType:(XCCacheDataType)cacheDataType;

- (void)fetchDataWithKey:(NSString *)key
              completion:(XCNetworkCacheDataQueryCompletedBlock)completion;
- (void)fetchDataWithKey:(NSString *)key
              completion:(XCNetworkCacheDataQueryCompletedBlock)completion
           cacheDataType:(XCCacheDataType)cacheDataType;

- (void)removeCacheWithKey:(NSString *)key
            withCompletion:(XCNetworkNoParamsBlock)completion;
- (void)removeCacheWithKey:(NSString *)key
            withCompletion:(XCNetworkNoParamsBlock)completion
             cacheDataType:(XCCacheDataType)cacheDataType;

- (void)clearMemoryCache;

- (void)clearDiskCache:(XCNetworkNoParamsBlock)completion;
- (void)clearDiskCache:(XCNetworkNoParamsBlock)completion
         cacheDataType:(XCCacheDataType)cacheDataType;

@end
