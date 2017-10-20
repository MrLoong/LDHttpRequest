//
//  ViewController.m
//  LDHttpRequest
//
//  Created by lastdays on 2017/10/20.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import "ViewController.h"
#import "LDHttp.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)testOne:(id)sender {
    LDDataPacket *packet = [[LDDataPacket alloc] init];
    packet.httpMethod = @"GET";
    packet.httpReqHeaders = @{
                              @"test1":@"value1",
                              @"test2":@"value2",
                              @"test3":@"value3"
                              };
    packet.callbackBlock = ^(NSData * _Nullable rspData) {
        if (rspData) {
            NSString *data = [[NSString alloc] initWithData:rspData encoding:NSUTF8StringEncoding];
            NSLog(@"%@",data);
        }
    };
    packet.httpURL = @"http://www.sojson.com/open/api/weather/json.shtml?city=%E6%B7%B1%E5%9C%B3";
    [[LDHttp shareInstance] asynHttpRequest:packet];
}
- (IBAction)testTwo:(id)sender {
    LDDataPacket *packet = [[LDDataPacket alloc] init];
    packet.httpMethod = @"GET";
    packet.httpReqHeaders = @{
                              @"test1":@"value1",
                              @"test2":@"value2",
                              @"test3":@"value3"
                              };
    packet.callbackBlock = ^(NSData * _Nullable rspData) {
        if (rspData) {
            NSString *data = [[NSString alloc] initWithData:rspData encoding:NSUTF8StringEncoding];
            //
            NSLog(@"就是这里：%@",data);
        }
        
    };
    packet.requestBlock = ^(NSInteger alreadyReceiveSize, NSInteger expectedContentLength) {
        NSLog(@"alreadyReceiveSize = %ld",(long)alreadyReceiveSize);
        NSLog(@"expectedContentLength = %ld",(long)expectedContentLength);
    };
    packet.httpURL = @"http://www.sojson.com/open/api/weather/json.shtml?city=%E6%B7%B1%E5%9C%B3";
    dispatch_queue_t aSerialQueue = dispatch_queue_create("lastdays", DISPATCH_QUEUE_SERIAL);
    
    // 指定线程回调，如果不进行设置，我们的网络库会以自己的默认线程进行回调
    packet.callQueue =aSerialQueue;
    dispatch_async(aSerialQueue, ^{
        [[LDHttp shareInstance] asynHttpRequest:packet];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
