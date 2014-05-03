//
//  ServerFinder.h
//  Server Finder
//
//  Created by Brian Jarchow on 4/29/14.
//  Copyright (c) 2014 Brian Jarchow. All rights reserved.
//

#import <sys/socket.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <Foundation/Foundation.h>

@interface ServerFinder : UIViewController <NSStreamDelegate> {
@public
    
    NSString *myIP;
    NSString *mask;
    NSString *address;
    NSString *base;
    NSString *recieved;
    NSString *challenge;
    NSString *response;
    NSString *command;
    int port;
    int last;
    UITextView *logView;
    NSMutableArray *servers;
    NSDate *start;
    NSTimeInterval end;
}

@property (strong) NSInputStream *inputStream;
@property (strong) NSOutputStream *outputStream;
@property (retain, nonatomic) NSTimer *connectionTimer;

-(void) setup;
-(void) search:(int)p;


@end
