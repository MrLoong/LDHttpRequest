//
//  LDHttp.h
//  LDhttpsTools
//
//  Created by lastdays on 2017/10/13.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDRequestOperation.h"

typedef NS_OPTIONS(NSInteger,RequestOptions) {
    
    //默认下载操作
    requestDefault = 1,
    
    //允许后台操作
    requestContinueInBackground = 2
};

typedef NS_ENUM(NSInteger,RequestOrder){
    
    //默认下载顺序，先进先出
    FIFO,
    
    //先进后出
    LIFO
};

//无参数block
typedef void(^RequestCreateBlock)(void);

@interface LDHttp : NSObject

/**
 Http 异步请求接口

 @param dataPacket 数据包
 */
-(void)asynHttpRequest:(LDDataPacket *)dataPacket;

//取消请求
- (void)cancel:(uint64_t)seq;

+ (instancetype)shareInstance;

@end
