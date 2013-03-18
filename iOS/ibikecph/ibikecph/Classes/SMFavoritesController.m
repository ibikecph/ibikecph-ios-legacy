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
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
    [favoriteHome resignFirstResponder];
}

- (IBAction)searchWork:(id)sender {
    searchFav = favWork;
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
    [favoriteWork resignFirstResponder];
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

@end
