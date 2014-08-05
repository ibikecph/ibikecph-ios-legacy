//
//  SMDebugViewController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 8/1/14.
//  Copyright (c) 2014 City of Copenhagen. All rights reserved.
//

#import "SMDebugViewController.h"

@interface SMDebugViewController () <UITextViewDelegate> {
    __weak IBOutlet UITextView *textLog;
}

@end

@implementation SMDebugViewController

- (id)init {
    self = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"SMDebugViewController"];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addText:) name:@"notificationAddDebugText" object:nil];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (IBAction)addText:(NSNotification*)notif {
    @synchronized(self) {
        textLog.text = [NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:@"%@\n", [notif.userInfo objectForKey:@"text"]], textLog.text];
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

@end
