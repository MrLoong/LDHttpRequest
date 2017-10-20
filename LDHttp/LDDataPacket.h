//
//  LDDataPacket.h
//  LDhttpsTools
//
//  Created by lastdays on 2017/10/12.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    Packet_Reset,
    Packet_finish
    
}PacketStatus;

/**
 *  Request回调信息，下载进度Block
 *
 *  @param alreadyReceiveSize 已经接收大小
 *  @param expectedContentLength     未接收大小
 */
typedef void(^RequestBlock)(NSInteger alreadyReceiveSize,NSInteger expectedContentLength);
typedef void(^LDHttpReqCallBlock)(NSData *_Nullable rspData);

@interface LDDataPacket : NSObject

@property (nonatomic, copy, nullable)   NSString           *appKey;
@property (nonatomic, copy, nullable)   NSDictionary       *httpReqHeaders;
@property (nonatomic, copy, nonnull)    NSString           *httpURL;
@property (nonatomic, copy, nonnull)    NSString           *httpMethod;
@property (nonatomic, strong, nullable) NSData             *httpBody;
@property (nonatomic, assign, readonly) uint64_t           seq;
@property (nonatomic, strong, nullable) dispatch_queue_t   callQueue;
@property (nonatomic, assign)           BOOL               report;
@property (nonatomic, copy, nullable)   LDHttpReqCallBlock callbackBlock;
@property (nonatomic, assign)           NSTimeInterval     timeout;
@property (nonatomic, strong,nullable)  NSData             *reponseData;
@property (nonatomic, assign)           NSInteger          retrCount;
@property (nonatomic, assign)           PacketStatus       packetStatus;
@property (nonatomic, strong, nullable) NSMutableURLRequest   *request;
@property (nonatomic, copy, nullable)   RequestBlock       requestBlock;





//私有属性
@property (nonatomic, strong, nullable) NSDate               *firstReqTime;
@property (nonatomic, assign)           NSTimeInterval       currentTimeout;
@property (nonatomic, strong, nullable) NSURLSessionDataTask *task;

@end
