//
//  SMRouteNavigationController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"
#import "SMRoute.h"
#import "SMGPSTrackButton.h"
#import "FlickableView.h"
#import "SMRequestOSRM.h"

/**
 * \ingroup screens
 * Main turn-by-turn navigation screen
 */

@interface SMRouteNavigationController : SMTranslatedViewController <UIGestureRecognizerDelegate,RMMapViewDelegate, SMRouteDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIScrollViewDelegate, RouteDelegate, ViewTapDelegate, SMRequestOSRMDelegate> {
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
    __weak IBOutlet UILabel *overviewDestinationBottom;
    __weak IBOutlet UILabel *overviewDestination;
    __weak IBOutlet UILabel *overviewTimeDistance;
    __weak IBOutlet UIView *stopView;
    __weak IBOutlet UIButton *closeButton;
    __weak IBOutlet UIImageView *arrivalBG;
    __weak IBOutlet UIImageView *swipeLeftArrow;
    __weak IBOutlet UIImageView *swipeRightArrow;
    __weak IBOutlet UIImageView *noConnectionView;
    __weak IBOutlet UIView *finishView;
    __weak IBOutlet UILabel *finishStreet;
    __weak IBOutlet UIView *routeOverviewBottom;
    __weak IBOutlet FlickableView *centerView;
    __weak IBOutlet UIView *blockingView;
    __weak IBOutlet UIView *mapContainer;
    __weak IBOutlet UIView *statusbarView;
}

@property BOOL currentlyRouting;
@property BOOL updateSwipableView;

@property (nonatomic, strong) CLLocation *startLocation, *endLocation;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;
@property (weak, nonatomic) IBOutlet UIView *mapFade;

@property (nonatomic, strong) id jsonRoot;

@end
