//
//  XCCacheObject.h
//  XCNetServiceDemo
//
//  Created by wuhuping on 15/8/18.
//  Copyright (c) 2015年 cd_xc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCNetworkConfig.h"
@interface XCCacheObject : NSObject

/** 缓存数据 **/
@property (nonatomic, copy, readonly) NSData *data;
/** 缓存数据最后更新时间 **/
@property (nonatomic, copy, readonly) NSDate *lastUpdateTime;
/** 缓存数据类型 **/
@property (nonatomic, assign, readonly) XCCacheDataType cacheDataType;

/** 缓存数据是否已经过期 **/
@property (nonatomic, assign, readonly) BOOL isOutdated;
/** 缓存数据是否为空 **/
@property (nonatomic, assign, readonly) BOOL isEmpty;

- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data dataType:(XCCacheDataType)dataType;

- (void)updateData:(NSData *)data;
- (void)updateCacheDataType:(XCCacheDataType)cacheDataType;

@end
