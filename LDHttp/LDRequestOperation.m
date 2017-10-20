//
//  LDRequestOperation.m
//  LDhttpsTools
//
//  Created by lastdays on 2017/10/16.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import "LDRequestOperation.h"
#import <UIKit/UIKit.h>
@interface LDRequestOperation ()<NSURLSessionDataDelegate>
{
    BOOL finished;
}
@property(strong,nonatomic) NSMutableData *reponseData;
@property(nonatomic, strong)LDDataPacket *pkt;

@end

@implementation LDRequestOperation

- (instancetype)initWithReq:(NSMutableURLRequest *)request pkt:(LDDataPacket *)pkt
{
    self = [super init];
    if (self) {
        _request = request;
        _pkt = pkt;
    }
    return self;
}

-(void)start
{
    NSLog(@"start");
    if (self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    /**
     * 创建NSURLSessionConfiguration类的对象, 这个对象被用于创建NSURLSession类的对象.
     */
    NSURLSessionConfiguration *configura = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    /**
     * 2. 创建NSURLSession的对象.
     * 参数一 : NSURLSessionConfiguration类的对象.(第1步创建的对象.)
     * 参数二 : session的代理人. 如果为nil, 系统将会提供一个代理人.
     * 参数三 : 一个队列, 代理方法在这个队列中执行. 如果为nil, 系统会自动创建一系列的队列.
     * 注: 只能通过这个方法给session设置代理人, 因为在NSURLSession中delegate属性是只读的.
     */
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configura delegate:self delegateQueue:nil];
    
    /**
     *  创建request
     */
    NSMutableURLRequest *request = self.request;
    NSLog(@"request allHTTPHeaderFields = %@",request.allHTTPHeaderFields);
    
    /**
     *  创建数据类型任务
     */
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    
    
    self.pkt.task = dataTask;
    /**
     *  开始任务
     */
    [dataTask resume];
    
    /**
     *  在session中的所有任务都完成之后, 使session失效.
     */
    [session finishTasksAndInvalidate];
    
}

-(void)cancel
{
    [self clear];
    [self willChangeValueForKey:@"isFinished"];
    finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    return;
}

/**
 *  清空
 */
-(void)clear
{
    self.request = nil;
    self.pkt = nil;
}

- (BOOL)isFinished
{
    return finished;
}

#pragma mark - LDRequestOperationDelegate
//最先调用，在这里做一些数据的初始化。
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    NSLog(@"开始");
    self.reponseData = [[NSMutableData alloc] init];
    if (self.isCancelled) {
        self.reponseData = nil;
    }
    completionHandler(NSURLSessionResponseAllow);
}


//请求响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    [self.reponseData appendData:data];
    if (self.delegate && [self.delegate respondsToSelector:@selector(LDURLSession:dataTask:didReceiveData:pkt:)]) {
        [self.delegate LDURLSession:session dataTask:dataTask didReceiveData:self.reponseData pkt:self.pkt];
    }
}

//请求完成后调用
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(LDURLSession:task:didCompleteWithError:pkt:)]) {
        if (self.pkt) {
            self.pkt.reponseData = self.reponseData;
            [self.delegate LDURLSession:session task:task didCompleteWithError:error pkt:self.pkt];
            finished = YES;
            [self cancel];
        }
    }
}




@end
