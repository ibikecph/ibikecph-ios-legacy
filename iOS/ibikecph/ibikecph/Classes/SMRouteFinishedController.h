//
//  SMRouteFinishedController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 01/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMFindAddressController.h"
#import "SMRouteNavigationController.h"

@interface SMRouteFinishedController : SMTranslatedViewController <RouteFinderDelegate> {
    
    __weak IBOutlet UILabel *labelTrip;
    __weak IBOutlet UILabel *labelAvgSpeed;
    __weak IBOutlet UILabel *labelCalories;
    __weak IBOutlet UILabel *labelTotalTrip;
    __weak IBOutlet UILabel *labelDestination;
    __weak IBOutlet UIButton *buttonNewStop;
}

@property CGFloat routeDistance;
@property CGFloat caloriesBurned;
@property CGFloat averageSpeed;
@property (nonatomic, strong) NSString * destination;

@property (nonatomic, weak) SMRouteNavigationController * delegate;

@end
