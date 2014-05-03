//
//  SFViewController.m
//  Server Finder
//
//  Created by Brian Jarchow on 4/29/14.
//  Copyright (c) 2014 Brian Jarchow. All rights reserved.
//

#import "SFViewController.h"
#import "ServerFinder.h"

@interface SFViewController ()

@end

@implementation SFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.sF = [[ServerFinder alloc] init];
    [self.sF addObserver:self forKeyPath:@"last" options:0 context:NULL];
    self.sF->logView = self.logView;
    [self.sF setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnSearch:(UIButton *)sender
{
    if (self.logView.text == nil)
    {   // Give error message and exit if port number is blank
        UIAlertView *alert = [[UIAlertView alloc]
                               initWithTitle:@"Missing Port Number"
                               message:@"Enter a port number and try again."
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    int port = [self.portNumber.text intValue];
    if (port < 1 || port > 65535)
    {   // Give error message and exit if port number is invalid. Port 0 is invalid, according to ICANN
        UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Invald port"
                                  message:@"Enter a valid port number"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // pass port number to ServerFinder object and search for servers
    [self.sF search:port];
    self.progressBar.hidden = false;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(object == self.sF)
    {
        if([keyPath isEqualToString:@"last"])
        {
            self.progressBar.progress = (float)self.sF->last / 255.0;
        }
        if(self.sF->last == 255)
            self.progressBar.hidden = TRUE;
    }
}

@end
