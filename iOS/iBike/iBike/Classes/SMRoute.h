//
//  SMRoute.h
//  iBike
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
    int lastVisitedWaypointIndex;
}

@property (nonatomic, weak) id<SMRouteDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSMutableArray *pastTurnInstructions; // turn instrucitons from first to the last passed turn
@property (nonatomic, strong) NSMutableArray *turnInstructions; // turn instruaciton from next to the last
@property (nonatomic, strong) NSMutableArray *visitedLocations;
//@property (nonatomic, strong) SMTurnInstruction *lastTurn;

@property CGFloat tripDistance;
@property CGFloat averageSpeed;
@property CGFloat caloriesBurned;

@property CLLocationCoordinate2D locationStart;
@property CLLocationCoordinate2D locationEnd;
@property BOOL recalculationInProgress;
@property NSInteger estimatedTimeForRoute;
@property NSInteger estimatedRouteDistance;


- (void) visitLocation:(CLLocation *)loc;
- (CLLocation *) getStartLocation;
- (CLLocation *) getEndLocation;
- (CLLocation *) getFirstVisitedLocation;
- (CLLocation *) getLastVisitedLocation;
- (NSData*) save;

- (CGFloat)calculateDistanceToNextTurn:(CLLocation *)loc;
- (CGFloat)calculateDistanceTraveled;
- (CGFloat)calculateAverageSpeed;
- (CGFloat)calculateCaloriesBurned;
- (NSString*)timePassed;

- (id)initWithRouteStart:(CLLocationCoordinate2D)start andEnd:(CLLocationCoordinate2D)end andDelegate:(id<SMRouteDelegate>)dlg;
- (void) recalculateRoute:(CLLocation *)loc;

@end
