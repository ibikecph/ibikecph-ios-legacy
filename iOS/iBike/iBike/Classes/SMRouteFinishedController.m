//
//  SMRouteFinishedController.m
//  iBike
//
//  Created by Ivan Pavlovic on 01/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMRouteFinishedController.h"

#import "SMUtil.h"

@interface SMRouteFinishedController ()

@end

@implementation SMRouteFinishedController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [labelAvgSpeed setText:[NSString stringWithFormat:@"%.1f km/h", self.averageSpeed]];

    [labelTrip setText:formatDistance(self.routeDistance)];
    [labelTotalTrip setText:formatDistance(self.routeDistance)];
    
    [labelCalories setText:[NSString stringWithFormat:@"%.0f", self.caloriesBurned]];
    
    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [labelDestination setText:[[a objectAtIndex:0] uppercaseString]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)goToFrontPage:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([segue.identifier isEqualToString:@"newRouteSegue"]) ){
        SMFindAddressController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    }
}

#pragma mark - route finder delegate

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate findRouteFrom:from to:to fromAddress:src toAddress:dst];
}

- (void)viewDidUnload {
    labelTrip = nil;
    labelAvgSpeed = nil;
    labelCalories = nil;
    labelTotalTrip = nil;
    labelDestination = nil;
    buttonNewStop = nil;
    [super viewDidUnload];
}
@end
