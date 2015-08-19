//
//  XCCacheObject.m
//  XCNetServiceDemo
//
//  Created by wuhuping on 15/8/18.
//  Copyright (c) 2015年 cd_xc. All rights reserved.
//

#import "XCCacheObject.h"
#import "XCNetworkConfig.h"
@interface XCCacheObject () <NSCoding>

@property (nonatomic, copy, readwrite) NSData *data;
@property (nonatomic, copy, readwrite) NSDate *lastUpdateTime;
@property (nonatomic, assign, readwrite) BOOL isOutdated;
@property (nonatomic, assign, readwrite) BOOL isEmpty;
@property (nonatomic, assign, readwrite) XCCacheDataType cacheDataType;

@end

@implementation XCCacheObject

#pragma mark - Getter & Setter
- (BOOL)isEmpty
{
    return self.data == nil;
}

- (BOOL)isOutdated
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.lastUpdateTime];
    NSTimeInterval outdateTimeSeconds = [self outdateTimeSecondsWithCacheDataType:self.cacheDataType];
    
    //过期时间为负时认为是永不过期
    if (outdateTimeSeconds < 0) {
        return NO;
    }else {
        return timeInterval > outdateTimeSeconds;
    }
}

- (void)setData:(NSData *)data
{
    _data = [data copy];
    _lastUpdateTime = [NSDate date];
}

#pragma mark - Life Cycle
- (id)initWithData:(NSData *)data
{
    return [self initWithData:data dataType:XCCacheDataTypeNormal];
}

- (id)initWithData:(NSData *)data dataType:(XCCacheDataType)dataType
{
    if (self = [super init]) {
        self.data = data;
        self.cacheDataType = dataType;
    }
    return self;
}

#pragma mark - Pulic Method
- (void)updateData:(NSData *)data
{
    self.data = data;
}

- (void)updateCacheDataType:(XCCacheDataType)cacheDataType
{
    self.cacheDataType = cacheDataType;
}

#pragma mark - Private Method
- (NSTimeInterval)outdateTimeSecondsWithCacheDataType:(XCCacheDataType)cacheDataType
{
    switch (cacheDataType) {
        case XCCacheDataTypeNormal:
            return kXCNormalCacheDataOutdateTimeSeconds;
            break;
            
        default:
            return 0.0;
            break;
    }
    return 0.0;
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.data forKey:@"data"];
    [aCoder encodeObject:self.lastUpdateTime forKey:@"lastUpdateTime"];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.cacheDataType] forKey:@"cacheDataType"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isOutdated] forKey:@"isOutdated"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isEmpty] forKey:@"isEmpty"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init]) {
        self.data = [aDecoder decodeObjectForKey:@"data"];
        self.lastUpdateTime = [aDecoder decodeObjectForKey:@"lastUpdateTime"];
        self.cacheDataType = [[aDecoder decodeObjectForKey:@"cacheDataType"] integerValue];
        self.isOutdated = [[aDecoder decodeObjectForKey:@"isOutdated"] boolValue];
        self.isEmpty = [[aDecoder decodeObjectForKey:@"isEmpty"] boolValue];
    }
    
    return self;
}

@end
