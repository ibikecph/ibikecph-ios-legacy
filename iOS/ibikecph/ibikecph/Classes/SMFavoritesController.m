//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMFavoritesController.h"
#import "SMSearchController.h"
#import "DAKeyboardControl.h"

typedef enum {
    favHome,
    favWork
} FavoriteType;
@interface SMFavoritesController () {
    FavoriteType searchFav;
}

@end

@implementation SMFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidUnload {
    favoriteHome = nil;
    favoriteWork = nil;
    scrlView = nil;
    favoritesView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

- (IBAction)skipOver:(id)sender {
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
}

- (IBAction)searchHome:(id)sender {
    searchFav = favHome;
    [favoriteHome resignFirstResponder];
    [scrlView setContentOffset:CGPointZero];
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}

- (IBAction)searchWork:(id)sender {
    searchFav = favWork;
    [favoriteWork resignFirstResponder];
    [scrlView setContentOffset:CGPointZero];
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"favToSearch"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        switch (searchFav) {
            case favHome:
                [destViewController setSearchText:favoriteHome.text];
                break;
            case favWork:
                [destViewController setSearchText:favoriteWork.text];
                break;
            default:
                break;
        }
        
    }
}

#pragma mark - search delegate

- (void)locationFound:(NSDictionary *)locationDict {
    switch (searchFav) {
        case favHome:
            [favoriteHome setText:[locationDict objectForKey:@"name"]];
            break;
        case favWork:
            [favoriteWork setText:[locationDict objectForKey:@"name"]];
            break;
        default:
            break;
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag + 1;
    [textField resignFirstResponder];
    
    [[favoritesView viewWithTag:tag] becomeFirstResponder];
    if (tag == 103) {
        [scrlView setContentOffset:CGPointZero];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0.0f, 150.0f)];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointZero];
    return YES;
}


@end
