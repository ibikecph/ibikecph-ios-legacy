//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMFavoritesController.h"

@interface SMFavoritesController ()

@end

@implementation SMFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - button actions

- (IBAction)skipOver:(id)sender {
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
}


@end
