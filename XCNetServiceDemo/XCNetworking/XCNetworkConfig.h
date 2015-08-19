//
//  XCNetworkConfig.h
//  XCNetServiceDemo
//
//  Created by wuhuping on 15/8/18.
//  Copyright (c) 2015年 cd_xc. All rights reserved.
//

#ifndef XCNetServiceDemo_XCNetworkConfig_h
#define XCNetServiceDemo_XCNetworkConfig_h

#pragma mark - Cache
/**
 *  缓存类型
 */
typedef NS_ENUM(NSInteger, XCCacheType){
    
    /** 缓存数据不存在 **/
    XCCacheTypeNone = 0x00,
    
    /** 磁盘缓存 **/
    XCCacheTypeDisk = 0x01,
    
    /** 内存缓存 **/
    XCCacheTypeMemory = 0x01 << 1,
};

/**
 *  缓存数据类型
 */
typedef NS_ENUM(NSInteger, XCCacheDataType){
    XCCacheDataTypeNormal,
};

typedef void(^XCNetworkNoParamsBlock)();
typedef void(^XCNetworkCacheDataQueryCompletedBlock)(NSData *data, XCCacheType cacheType);

/** 缓存数据为XCCacheDataTypeNormal时的磁盘缓存路径文件夹名 **/
static NSString *kDiskCachePathNameForCacheDataTypeNormal = @"Normal";

/** 数据过期时间 **/
static NSTimeInterval kXCNormalCacheDataOutdateTimeSeconds = 3600.0;

#pragma mark - Networking

/**
 *  服务器返回数据状态类型
 */
typedef NS_ENUM(NSInteger, XCURLResponseErrorType){
    /** 只要接受到服务器的反馈就算成功,返回数据内容是否成功,由上层处理 **/
    XCURLResponseErrorTypeNone,
    /** 请求超时 **/
    XCURLResponseErrorTypeTimeout,
    /** 没有网络 **/
    XCURLResponseErrorTypeNoNetwork
};

#endif
