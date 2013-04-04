//
//  SMAccountController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 21/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAccountController.h"
#import <QuartzCore/QuartzCore.h>
#import "DAKeyboardControl.h"

@interface SMAccountController () {
    
}
@property (nonatomic, strong) SMAPIRequest * apr;
@end

@implementation SMAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [scrlView setContentSize:CGSizeMake(320.0f, 517.0f)];
    
    /**
     * rounded corners for images
     */
    fbImage.layer.cornerRadius = 5;
    fbImage.layer.masksToBounds = YES;
    regularImage.layer.cornerRadius = 5;
    regularImage.layer.masksToBounds = YES;
    
    /**
     * decide which view we want to show
     */
    [fbView setHidden:YES];
    [regularView setHidden:NO];
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"login"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_GET_USER_DATA withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
}

- (void)viewDidUnload {
    fbImage = nil;
    fbName = nil;
    fbView = nil;
    regularView = nil;
    regularImage = nil;
    name = nil;
    email = nil;
    password = nil;
    passwordRepeat = nil;
    scrlView = nil;
    [super viewDidUnload];
}


#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveChanges:(id)sender {
}

- (IBAction)deleteAccount:(id)sender {
}

- (IBAction)logout:(id)sender {
    [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
    [self.appDelegate saveSettings];
    [self goBack:nil];
}

#pragma mark - textview delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    [textField resignFirstResponder];
    [[scrlView viewWithTag:nextTag] becomeFirstResponder];
    if (nextTag == 105) {
        [scrlView setContentOffset:CGPointZero];
        [self saveChanges:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0.0f, MAX(textField.frame.origin.y + 260.0f - scrlView.frame.size.height, 0.0f))];
    return YES;
}

#pragma mark - api request

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    
}


@end
