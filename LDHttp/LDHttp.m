//
//  LDHttp.m
//  LDhttpsTools
//
//  Created by lastdays on 2017/10/13.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import "LDHttp.h"
#import <UIKit/UIKit.h>

@interface LDHttp()<LDRequestOperationDelegate>

@property (nonatomic, strong)           NSString            *deviceIMEI;
@property (nonatomic, strong)           NSMutableDictionary *packetDic;
@property (nonatomic, assign)           NSInteger           maxRetrCount;
@property (nonatomic, strong)           NSOperationQueue    *requestQueue;
@property (nonatomic, strong, readonly) dispatch_queue_t    callQueue;

@end

@implementation LDHttp

+ (instancetype)shareInstance {
    static LDHttp *https = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        https = [[LDHttp alloc] init];
    });
    return https;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _packetDic    = [[NSMutableDictionary alloc] initWithCapacity:15];
        _callQueue    = dispatch_queue_create("LDCallBlocK", DISPATCH_QUEUE_SERIAL);
        _maxRetrCount = 3;
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

-(void)asynHttpRequest:(LDDataPacket *)dataPacket
{
    __weak __typeof(self)myself = self;
    __block LDRequestOperation *operation;
    //更新线程
    [self updataQueue:dataPacket];
    //更新超时时间
    [self updateTime:dataPacket];
    [self addRequestPkt:dataPacket RequestCreateBlock:^{
        if(!dataPacket.request){
            dataPacket.request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:dataPacket.httpURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:dataPacket.currentTimeout];
            dataPacket.request.HTTPMethod = dataPacket.httpMethod.length>0?dataPacket.httpMethod:@"POST";
            dataPacket.request.HTTPBody   = dataPacket.httpBody;
            [dataPacket.request setValue:myself.deviceIMEI forHTTPHeaderField:@"AppName-IMEI"];
            for (NSString *key in dataPacket.httpReqHeaders.allKeys) {
                [dataPacket.request setValue:dataPacket.httpReqHeaders[key] forHTTPHeaderField:key];
            }
        }
        operation = [[LDRequestOperation alloc] initWithReq:dataPacket.request pkt:dataPacket];
        operation.delegate = myself;
        dataPacket.request.timeoutInterval = dataPacket.currentTimeout;
        [myself.requestQueue addOperation:operation];
    }];

}

- (void)cancel:(uint64_t)seq {
    NSNumber *rid = @(seq);
    LDDataPacket *pkt = self.packetDic[rid];
    if (pkt) {
        [pkt.task cancel];
    }
}

- (void)addRequestPkt:(LDDataPacket *)pkt RequestCreateBlock:(RequestCreateBlock)requestCreate
{
    BOOL firstRequest = NO;
    NSNumber *seqNum = @(pkt.seq);
    if (!self.packetDic[seqNum]) {
        if (pkt) {
            [self.packetDic setObject:pkt forKey:seqNum];
            pkt.firstReqTime = [NSDate date];
        }
        firstRequest = YES;
    }
    if (pkt) {
        requestCreate();
    }
}

- (void)updateTime:(LDDataPacket *)pkt
{
    pkt.currentTimeout = pkt.timeout;
    if (pkt.firstReqTime) {
        NSTimeInterval requestTime = [[NSDate date] timeIntervalSinceDate:pkt.firstReqTime];
        if (requestTime && requestTime<pkt.currentTimeout) {
            pkt.currentTimeout = pkt.currentTimeout - requestTime;
        }else{
            pkt.currentTimeout = 0;
            pkt.packetStatus = Packet_finish;
        }
    }
}

- (BOOL)isBackPacket:(LDDataPacket *)pkt data:(NSData *)data
{
    NSNumber *seq = @(pkt.seq);
    if (pkt.currentTimeout == 0 || pkt.retrCount>=self.maxRetrCount || pkt.packetStatus==Packet_finish) {
        [self.packetDic removeObjectForKey:seq];
        if (pkt.callbackBlock) {
            dispatch_async(pkt.callQueue, ^{
                pkt.callbackBlock(data);
            });
        }
        return YES;
    }else{
        pkt.retrCount++;
    }
    return NO;
}

- (BOOL)isRetr:(NSURLResponse *)response
{
    NSInteger codeStatus = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"LDHttpRequest codeStatus:%ld",(long)codeStatus);
    if (codeStatus>=500) {
        return NO;
    }
    if (codeStatus>=300 || codeStatus < 200) {
        return YES;
    }
    return NO;
}

- (NSString *)deviceIMEI
{
    static NSString *imei = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imei = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    });
    return imei;
}


//更新回调线程
- (void)updataQueue:(LDDataPacket *)packet
{
    if(packet.callQueue){
        return;
    }
    if ([NSThread isMainThread]) {
        packet.callQueue = dispatch_get_main_queue();
    }else{
        packet.callQueue = packet.callQueue?:self.callQueue;
    }
}


#pragma mark - LDRequestOperationDelegate

-(void)LDURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error pkt:(LDDataPacket *)pkt
{
    NSNumber *seqNum = @(pkt.seq);
    dispatch_async(pkt.callQueue, ^{
        LDDataPacket *pt = self.packetDic[seqNum];
        if (!pt) {
            return;
        }
        if (!error) {
            [self.packetDic removeObjectForKey:seqNum];
            pt.packetStatus = Packet_finish;
        }else{
            if ([self isRetr:task.response]) {
                NSLog(@"error = %@",error);
                pt.packetStatus = Packet_Reset;
                [self asynHttpRequest:pt];
            }
        }
        if ([self isBackPacket:pt data:pt.reponseData]) {
            return;
        }
    });
}

-(void)LDURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data pkt:(LDDataPacket *)pkt
{
    dispatch_async(pkt.callQueue, ^{
        if (pkt.requestBlock) {
            pkt.requestBlock(data.length, dataTask.response.expectedContentLength);
        }
    });

}



//- (void)asynHttpRequest:(LDDataPacket *)dataPacket
//{
//    if (!dataPacket) {
//        return;
//    }
//    NSNumber *seqNum = @(dataPacket.seq);
//    if (!self.packetDic[seqNum]) {
//        [self.packetDic setObject:dataPacket forKey:seqNum];
//        if (dataPacket) {
//            dataPacket.firstReqTime = [NSDate date];
//        }
//    }
//    [self updataQueue:dataPacket];
//    [self updateTime:dataPacket];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:dataPacket.httpURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:dataPacket.currentTimeout];
//    request.HTTPMethod = dataPacket.httpMethod.length>0?dataPacket.httpMethod:@"POST";
//    request.HTTPBody = dataPacket.httpBody;
//    [request setValue:self.deviceIMEI forHTTPHeaderField:@"AppName-IMEI"];
//    for (NSString *key in dataPacket.httpReqHeaders.allKeys) {
//        [request setValue:dataPacket.httpReqHeaders[key] forHTTPHeaderField:key];
//    }
//    NSURLSession *session = [NSURLSession sharedSession];
//    __weak typeof(self) weakSelf = self;
//    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        dispatch_async(dataPacket.callQueue, ^{
//            LDDataPacket *pt = weakSelf.packetDic[seqNum];
//            if (!pt) {
//                return;
//            }
//            if (!error) {
//                pt.reponseData = data;
//                pt.packetStatus = Packet_finish;
//            }else{
//                if ([self isRetr:response]) {
//                    [weakSelf asynHttpRequest:pt];
//                    pt.packetStatus = Packet_Reset;
//                }
//            }
//            if ([self isBackPacket:dataPacket data:dataPacket.reponseData]) {
//                return;
//            }
//        });
//    }];
//    [task resume];
//}


@end
