//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMFavoritesController.h"
#import "SMSearchController.h"
#import "DAKeyboardControl.h"
#import "SMUtil.h"
#import <CoreLocation/CoreLocation.h>
#import "SMFavoritesUtil.h"

typedef enum {
    favHome,
    favWork
} FavoriteType;
@interface SMFavoritesController () {
    FavoriteType searchFav;
}
@property (nonatomic, strong) NSDictionary * homeDict;
@property (nonatomic, strong) NSDictionary * workDict;
@end

@implementation SMFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.workDict = nil;
    self.homeDict = nil;
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
    if ([[SMFavoritesUtil getFavorites] count] > 0) {
        [self.view setAlpha:0.0f];
        [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
    } else {
        [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

- (IBAction)skipOver:(id)sender {
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
}

- (IBAction)saveFavorites:(id)sender {
    if (self.homeDict) {
        if ([self.homeDict objectForKey:@"subsource"] && [[self.homeDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : [self.homeDict objectForKey:@"name"],
             @"address" : [self.homeDict objectForKey:@"name"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"home",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
        } else {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : translateString(@"Home"),
             @"address" : [self.homeDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"home",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
        }
    }
    if (self.workDict) {
        if ([self.workDict objectForKey:@"subsource"] && [[self.workDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : [self.workDict objectForKey:@"name"],
             @"address" : [self.workDict objectForKey:@"nameden runde"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"work",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];            
        } else {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : translateString(@"Work"),
             @"address" : [self.workDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"work",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
        }
    }
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
}

- (IBAction)searchHome:(id)sender {
    searchFav = favHome;
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}

- (IBAction)searchWork:(id)sender {
    searchFav = favWork;
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"favToSearch"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setShouldAllowCurrentPosition:NO];
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
            [self setHomeDict:locationDict];
            break;
        case favWork:
            [favoriteWork setText:[locationDict objectForKey:@"name"]];
            [self setWorkDict:locationDict];
            break;
        default:
            break;
    }
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
