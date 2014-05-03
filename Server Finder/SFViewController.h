//
//  SFViewController.h
//  Server Finder
//
//  Created by Brian Jarchow on 4/29/14.
//  Copyright (c) 2014 Brian Jarchow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerFinder.h"

@interface SFViewController : UIViewController

- (IBAction)btnSearch:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UITextField *portNumber;
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;

@property (strong) ServerFinder *sF;

@end
