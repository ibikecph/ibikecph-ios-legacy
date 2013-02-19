//
//  SMRouteNavigationController.h
//  iBike
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import "SMRoute.h"
#import "SMFindAddressController.h"

@interface SMRouteNavigationController : UIViewController <RMMapViewDelegate, SMRouteDelegate, RouteFinderDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    __weak IBOutlet UITableView *tblDirections;
    __weak IBOutlet UIButton *buttonNewStop;
    BOOL currentlyRouting;
    __weak IBOutlet UIView *instructionsView;
    __weak IBOutlet UIView *minimizedInstructionsView;
    __weak IBOutlet UIView *progressView;
    __weak IBOutlet UIImageView *progressBar;
    __weak IBOutlet UILabel *labelTimeLeft;
    __weak IBOutlet UILabel *labelDestination;
    __weak IBOutlet UILabel *labelDistanceLeft;
    __weak IBOutlet UILabel *labelDistanceToNextTurn;
    __weak IBOutlet UIImageView *imgNextTurnDirection;
    __weak IBOutlet UIButton *buttonTrackUser;
    __weak IBOutlet UIView *finishFadeView;
    __weak IBOutlet UILabel *finishDistance;
    __weak IBOutlet UILabel *finishTime;
    __weak IBOutlet UIView *recalculatingView;
}

@property (nonatomic, strong) CLLocation *startLocation, *endLocation;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;

@property (nonatomic, weak) id<RouteFinderDelegate> delegate;

@end
