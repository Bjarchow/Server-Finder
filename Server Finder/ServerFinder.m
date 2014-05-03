//
//  ServerFinder.m
//  Server Finder
//
//  Created by Brian Jarchow on 4/29/14.
//  Copyright (c) 2014 Brian Jarchow. All rights reserved.
//

#import "ServerFinder.h"

@implementation ServerFinder
@synthesize connectionTimer;

- (void)setup
{
    // Find local IP address
    NSString *local = [self getIPaddress];
    myIP = local;
    last = 0;
    
    // strip the last byte from the IP address
    int i;
    int j = 0;
    for(i=0;i<local.length;i++)
    {
        if([local characterAtIndex:i]=='.')
        {
            j++;
            if(j == 3) break;
        }
    }
    
    if(j == 3)
    {
        base = [local substringToIndex:i+1];
    }
    else
    {
        // error message and exit
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bad IP"
                                                        message:@"Could not identify IP address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
    // report starting point
    [self addLogEntry:[NSString stringWithFormat:@"Local IP Address: %@", myIP]];
    [self addLogEntry:[NSString stringWithFormat:@"Searching %@1 to %@254\n", base, base]];

}

- (void)search:(int) p
{
    port = p;
    [self findServer];
}

- (void)findServer
{
    [self willChangeValueForKey:@"last"];
    last++;
    [self didChangeValueForKey:@"last"];
    if (last < 255)
    {
        // create address
        address = [NSString stringWithFormat:@"%@%d", base, last];
        // if equal to the local address, increment
        if ([address isEqualToString:myIP] && last < 254) {
            last ++;
            address = [NSString stringWithFormat:@"%@%d", base, last];
        }
        //        [self addLogEntry:[NSString stringWithFormat:@"Trying %@", address]];
        [self connect];
    }
    else
    {
        [self addLogEntry:@"search complete"];
        last = 0;
    }
}

- (void)connect
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)address, port, &readStream, &writeStream);
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
	
    [self.inputStream setDelegate:self];
	[self.outputStream setDelegate:self];
	[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.inputStream open];
	[self.outputStream open];
    
    // So our run loop continues to run.
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [runloop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    
    // start the connection timer
    [self startConnectionTimer];
    
    // So we have a clean starting place.
    self->recieved = @"";
}

- (void) disconnect
{
    [self.outputStream close];
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    self.outputStream = nil;
}

- (void)startConnectionTimer
{
    [self stopConnectionTimer]; // Make sure any existing timer is stopped before this method is called
    
    NSTimeInterval interval = 0.025; // Measured in seconds, is a double
    
    self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                            target:self
                                                          selector:@selector(handleConnectionTimeout:)
                                                          userInfo:nil
                                                           repeats:NO];
    start = [NSDate date];
    //    NSLog(@"timer started");
}

- (void)handleConnectionTimeout:(NSTimer*) timer
{
    // ... disconnect ...
    //	    NSLog(@"connection timeout");
    [self stopConnectionTimer];
    [self disconnect];
    
    // try connecting to the next address
    [self findServer];
}

// Call this when you successfully connect
- (void)stopConnectionTimer
{
    if (connectionTimer)
    {
        [connectionTimer invalidate];
        connectionTimer = nil;
    }
    end = [[NSDate date] timeIntervalSinceDate:start];
}

// Adds contents of entry to UITextView on the user interface
- (void)addLogEntry:(NSString*) entry
{
    NSLog(@"%@", entry);
    if(nil != self->logView)
        self->logView.text = [[NSString stringWithFormat:@"%@\n", entry] stringByAppendingString:self->logView.text];
}

// acquires local IP address and subnet mask.
- (NSString *)getIPaddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone. My mac is using en1 for the simulator
#if TARGET_IPHONE_SIMULATOR
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en1"])
#else
                    if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
#endif
                    {
                        // Get NSString from C String
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                        mask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];

                        
                    }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	
	switch (streamEvent)
    {
			
		case NSStreamEventOpenCompleted:
            [self stopConnectionTimer];
            if(theStream == self.inputStream)
            {
                [self addLogEntry:[NSString stringWithFormat:@"Server found at: %@ after %f seconds", address, end]];
                [servers addObject:address];
            }
            else
            {
                [self findServer];
            }
            break;
			
		case NSStreamEventHasBytesAvailable:
			if (theStream == self.inputStream) {
				uint8_t buffer[1024];
				int len;
				
				while ([self.inputStream hasBytesAvailable]) {
					len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
						self->recieved = [self->recieved stringByAppendingString:output];
                        
						if (nil != output && [self->recieved hasSuffix:@"->"]) {
							[self messageReceived: output];
                            recieved = @"";
						}
					}
				}
			}
            break;
			
		case NSStreamEventErrorOccurred:
			break;
            
		case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
		default:
            break;
	} // end switch
    
}

- (void)messageReceived:(NSString *)message
{
    // So we always log what we recieve.
    [self addLogEntry:[NSString stringWithFormat:@"TIU: %@", message]];
}

@end
