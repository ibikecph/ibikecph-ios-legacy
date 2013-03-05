//
//  SMRoute.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "SMTurnInstruction.h"
#import "SMRequestOSRM.h"

@protocol SMRouteDelegate <NSObject>
@required
- (void) updateTurn:(BOOL)firstElementRemoved;
- (void) reachedDestination;
- (void) updateRoute;
- (void) startRoute;
- (void) routeNotFound;
@optional
- (void) routeRecalculationStarted;
- (void) routeRecalculationDone;
@end

@interface SMRoute : NSObject <SMRequestOSRMDelegate> {
    BOOL approachingTurn;
}

@property (nonatomic, weak) id<SMRouteDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSMutableArray *pastTurnInstructions; // turn instrucitons from first to the last passed turn
@property (nonatomic, strong) NSMutableArray *turnInstructions; // turn instruaciton from next to the last
@property (nonatomic, strong) NSMutableArray *visitedLocations;
//@property (nonatomic, strong) SMTurnInstruction *lastTurn;

@property CGFloat distanceLeft;
@property CGFloat tripDistance;
@property CGFloat averageSpeed;
@property CGFloat caloriesBurned;

@property CLLocationCoordinate2D locationStart;
@property CLLocationCoordinate2D locationEnd;
@property BOOL recalculationInProgress;
@property NSInteger estimatedTimeForRoute;
@property NSInteger estimatedRouteDistance;
@property NSString * routeChecksum;
@property NSString * destinationHint;

@property CLLocationCoordinate2D lastCorrectedLocation;
@property double lastCorrectedHeading;


@property NSInteger lastVisitedWaypointIndex;


- (void) visitLocation:(CLLocation *)loc;
- (CLLocation *) getStartLocation;
- (CLLocation *) getEndLocation;
- (CLLocation *) getFirstVisitedLocation;
- (CLLocation *) getLastVisitedLocation;
- (NSData*) save;

- (CGFloat)calculateDistanceTraveled;
- (CGFloat)calculateAverageSpeed;
- (CGFloat)calculateCaloriesBurned;
- (NSString*)timePassed;

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg;
- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg andJSON:(NSDictionary*) routeJSON;
- (void) recalculateRoute:(CLLocation *)loc;

- (double)getCorrectedHeading;

@end
