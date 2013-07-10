//
//  SMAboutController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAboutController.h"

@interface SMAboutController ()

@end

@implementation SMAboutController

- (void)viewDidLoad {
    [super viewDidLoad];
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    [scrlView setContentSize:CGSizeMake(265.0f, 520.0f)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize size = [aboutText.text sizeWithFont:aboutText.font constrainedToSize:CGSizeMake(aboutText.frame.size.width, 100000.0f) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = aboutText.frame;
    frame.size.height = size.height + 50.0f;
    aboutText.frame = frame;
    [scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, aboutText.frame.origin.y + aboutText.frame.size.height)];
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    scrlView = nil;
    aboutText = nil;
    [super viewDidUnload];
}
@end
