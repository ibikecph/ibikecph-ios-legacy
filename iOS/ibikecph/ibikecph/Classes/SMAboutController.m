//
//  SMAboutController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAboutController.h"

@interface SMAboutController () {
    __weak IBOutlet UILabel *debugLabel;
}

@end

@implementation SMAboutController

- (void)viewDidLoad {
    [super viewDidLoad];
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    [scrlView setContentSize:CGSizeMake(265.0f, 520.0f)];
    [self moveView];
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
    
    frame = debugLabel.frame;
    frame.origin.y = CGRectGetMaxY(aboutText.frame) + 5.0f;
    debugLabel.frame = frame;
    
    [scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, CGRectGetMaxY(debugLabel.frame) + 5.0f)];
    
#if DEBUG
    [debugLabel setText:BUILD_STRING];
#else
    [debugLabel setText:@""];
#endif

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

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleBlackOpaque;
}

@end
