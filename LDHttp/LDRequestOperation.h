//
//  LDRequestOperation.h
//  LDhttpsTools
//
//  Created by lastdayson 2017/10/16.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDDataPacket.h"

@protocol LDRequestOperationDelegate <NSObject>

-(void)LDURLSession:(NSURLSession *)session
                task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
                pkt:(LDDataPacket *)pkt;


- (void)LDURLSession:(NSURLSession *)session
            dataTask:(NSURLSessionDataTask *)dataTask
      didReceiveData:(NSData *)data
                 pkt:(LDDataPacket *)pkt;

@end

@interface LDRequestOperation : NSOperation

@property(nonatomic, strong) NSMutableURLRequest            *request;
@property(nonatomic, weak)   id<LDRequestOperationDelegate> delegate;

- (instancetype)initWithReq:(NSMutableURLRequest *)request
                        pkt:(LDDataPacket *)pkt;

@end
