//
//  SMRouteNavigationController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import "SMRoute.h"
#import "SMGPSTrackButton.h"

@interface SMRouteNavigationController : SMTranslatedViewController <RMMapViewDelegate, SMRouteDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIScrollViewDelegate, RouteDelegate> {
    __weak IBOutlet UITableView *tblDirections;
    __weak IBOutlet UIView *instructionsView;
    __weak IBOutlet UIView *minimizedInstructionsView;
    __weak IBOutlet UIView *progressView;
    __weak IBOutlet UILabel *labelTimeLeft;
    __weak IBOutlet UILabel *labelDistanceLeft;
    __weak IBOutlet UILabel *labelDistanceToNextTurn;
    __weak IBOutlet UIImageView *imgNextTurnDirection;
    __weak IBOutlet UIView *finishFadeView;
    __weak IBOutlet UILabel *finishDistance;
    __weak IBOutlet UILabel *finishTime;
    __weak IBOutlet UILabel *finishDestination;
    __weak IBOutlet UIView *recalculatingView;
    __weak IBOutlet SMGPSTrackButton *buttonTrackUser;
    __weak IBOutlet UIScrollView *swipableView;
    __weak IBOutlet UIView *routeOverview;
    __weak IBOutlet UILabel *overviewDestination;
    __weak IBOutlet UILabel *overviewTimeDistance;
    __weak IBOutlet UIView *stopView;
    __weak IBOutlet UIButton *closeButton;
    __weak IBOutlet UIImageView *arrivalBG;
}

@property BOOL currentlyRouting;
@property BOOL updateSwipableView;

@property (nonatomic, strong) CLLocation *startLocation, *endLocation;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;
@property (weak, nonatomic) IBOutlet UIView *mapFade;

@property (nonatomic, strong) id jsonRoot;

@end
