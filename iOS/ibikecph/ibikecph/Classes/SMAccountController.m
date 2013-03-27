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

@end
