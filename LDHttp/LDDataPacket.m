//
//  LDDataPacket.m
//  LDhttpsTools
//
//  Created by lastdays on 2017/10/12.
//  Copyright © 2017年 lastdays. All rights reserved.
//

#import "LDDataPacket.h"

@implementation LDDataPacket

- (instancetype)init
{
    self = [super init];
    if (self) {
        _seq = [self creatSeq];
        _timeout = 20;
        _retrCount = 0;
        NSLog(@"%llu",_seq);
    }
    return self;
}

static uint64_t firstSeq = 0;
static NSLock *seqLock = nil;
- (uint64_t)creatSeq
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        seqLock = [[NSLock alloc] init];
        firstSeq = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000);
        firstSeq = (uint32_t)(firstSeq * firstSeq * arc4random());
    });
    [seqLock lock];
    uint64_t seq = firstSeq++;
    [seqLock unlock];
    return seq;
}



@end
