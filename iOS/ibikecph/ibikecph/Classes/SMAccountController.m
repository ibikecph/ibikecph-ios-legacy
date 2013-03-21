//
//  SMAccountController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 21/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMAccountController.h"

@interface SMAccountController ()

@end

@implementation SMAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
