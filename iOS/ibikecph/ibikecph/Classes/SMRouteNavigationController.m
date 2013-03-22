    //
//  SMRouteNavigationController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMRouteNavigationController.h"

#import "RMMapView.h"
#import "RMShape.h"
#import "RMPath.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMUserLocation.h"

#import "SMiBikeCPHMapTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "SMLocationManager.h"

#import "SMTurnInstruction.h"
#import "SMRoute.h"
#import "SMDirectionCell.h"
#import "SMDirectionTopCell.h"
#import "SMReportErrorController.h"

#import "SMUtil.h"

#import "SMAnnotation.h"
#import "SMSwipableView.h"

typedef enum {
    directionsFullscreen,
    directionsNormal,
    directionsMini,
    directionsHidden
} DirectionsState;

@interface SMRouteNavigationController () {
    DirectionsState currentDirectionsState;
    CGFloat lastDirectionsPos;
    CGFloat touchOffset;
    BOOL overviewShown;
}
@property (nonatomic, strong) SMRoute *route;
@property (nonatomic, strong) IBOutlet RMMapView * mpView;
@property int directionsShownCount; // How many directions are shown in the directions table at the moment:
                                    // -1 means no direction is shown and minimized directions view is not shown (this happens before first call to showDirections())
                                    // 0 means no direction is shown and minimized directions view is shown
                                    // > 3 means directions table is maximized
@property (nonatomic, strong) NSMutableSet * recycledItems;
@property (nonatomic, strong) NSMutableSet * activeItems;
@property (nonatomic, strong) NSArray * instructionsForScrollview;
@end

@implementation SMRouteNavigationController

#define MAX_SEGMENTS 1
#define MAX_TABLE 80.0f

- (void)viewDidLoad {
    [super viewDidLoad];

    self.recycledItems = [NSMutableSet set];
    self.activeItems = [NSMutableSet set];
    [instructionsView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    self.updateSwipableView = YES;
    
    [RMMapView class];
    
    self.currentlyRouting = NO;
    overviewShown = NO;
    self.directionsShownCount = -1;

    [SMLocationManager instance];
    
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    
    [self setDirectionsState:directionsHidden];
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    [self.mpView setTriggerUpdateOnHeadingChange:NO];
    [self.mpView setDisplayHeadingCalibration:NO];
    [self.mpView setEnableBouncing:TRUE];
    [self.mpView setRoutingDelegate:nil];
    
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];

    [labelTimeLeft setText:@""];
    [labelDistanceLeft setText:@""];
    
    [tblDirections setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    // Start tracking location only when user starts it through UI
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate withJSON:self.jsonRoot];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    [self.mpView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
    [self addObserver:self forKeyPath:@"currentlyRouting" options:0 context:nil];
    [swipableView addObserver:self forKeyPath:@"hidden" options:0 context:nil];
    [self.mapFade addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tblDirections reloadData];
    if (self.currentlyRouting) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"currentlyRouting" context:nil];
    [swipableView removeObserver:self forKeyPath:@"hidden" context:nil];
    [self.mpView removeObserver:self forKeyPath:@"userTrackingMode" context:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    self.mpView.delegate = nil;
    self.mpView = nil;
    self.route.delegate = nil;
    self.route = nil;
    tblDirections = nil;
    instructionsView = nil;
    labelTimeLeft = nil;
    labelDistanceLeft = nil;
    progressView = nil;
    minimizedInstructionsView = nil;
    labelDistanceToNextTurn = nil;
    imgNextTurnDirection = nil;
    finishFadeView = nil;
    finishDistance = nil;
    finishTime = nil;
    recalculatingView = nil;
    finishDestination = nil;
    buttonTrackUser = nil;
    swipableView = nil;
    routeOverview = nil;
    overviewDestination = nil;
    overviewTimeDistance = nil;
    stopView = nil;
    [self setMapFade:nil];
    closeButton = nil;
    arrivalBG = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


#pragma mark - custom methods

#define COORDINATE_PADDING 0.005f

- (void)showRouteOverview {
    overviewShown = YES;
    self.currentlyRouting = NO;
    [progressView setHidden:YES];
    [self setDirectionsState:directionsNormal];
    // Display new path
    NSDictionary * coordinates = [self addRouteAnnotation:self.route];
    [self.mpView setRoutingDelegate:self];
    [tblDirections reloadData];
    
    [self reloadSwipableView];
    
    [routeOverview setFrame:instructionsView.frame];

    [overviewTimeDistance setText:[NSString stringWithFormat:@"%@   %@", expectedArrivalTime(self.route.estimatedTimeForRoute), formatDistance(self.route.estimatedRouteDistance)]];
    [overviewDestination setText:self.destination];

    
    CLLocationCoordinate2D ne = ((CLLocation*)[coordinates objectForKey:@"neCoordinate"]).coordinate;
    CLLocationCoordinate2D sw = ((CLLocation*)[coordinates objectForKey:@"swCoordinate"]).coordinate;
    
    ne.latitude += COORDINATE_PADDING;
    ne.longitude += COORDINATE_PADDING;

    sw.latitude -= COORDINATE_PADDING;
    sw.longitude -= COORDINATE_PADDING;

    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake((ne.latitude+sw.latitude) / 2.0, (ne.longitude+sw.longitude) / 2.0)];
    [self.mpView zoomWithLatitudeLongitudeBoundsSouthWest:sw northEast:ne animated:YES];    
}

- (IBAction)startRouting:(id)sender {
    overviewShown = NO;
    [UIView animateWithDuration:0.4f animations:^{
        [routeOverview setAlpha:0.0f];
    }];
    
    self.currentlyRouting = YES;
    [self resetZoom];
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];

    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];

    [recalculatingView setAlpha:1.0f];
    [UIView animateWithDuration:0.3f animations:^{
        [recalculatingView setAlpha:0.0f];
    }];
}

- (void) start:(CLLocationCoordinate2D)from end:(CLLocationCoordinate2D)to  withJSON:(id)jsonRoot{
    
    if (self.mpView.delegate == nil) {
        self.mpView.delegate = self;
    }
    
    for (RMAnnotation *annotation in self.mpView.annotations) {
        [self.mpView removeAnnotation:annotation];
    }

    self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self andJSON:jsonRoot];
    if (!self.route) {
        return;
    }

    SMAnnotation *startMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:from andTitle:@"A"];
    startMarkerAnnotation.annotationType = @"marker";
    startMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerStart"];
    startMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    NSMutableArray * arr = [[self.source componentsSeparatedByString:@","] mutableCopy];
    startMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([startMarkerAnnotation.title isEqualToString:@""]) {
        startMarkerAnnotation.title = translateString(@"marker_start");
    }
    [arr removeObjectAtIndex:0];
    startMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mpView addAnnotation:startMarkerAnnotation];

    SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:to andTitle:@"B"];
    endMarkerAnnotation.annotationType = @"marker";
    endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
    endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    arr = [[self.destination componentsSeparatedByString:@","] mutableCopy];
    endMarkerAnnotation.title = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [arr removeObjectAtIndex:0];
    endMarkerAnnotation.subtitle = [[arr componentsJoinedByString:@","] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.mpView addAnnotation:endMarkerAnnotation];
    

    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(from.latitude,from.longitude)];

    [self showRouteOverview];
}

- (void) renderMinimizedDirectionsViewFromInstruction {
    if (self.route.turnInstructions.count > 0) {
        SMTurnInstruction *nextTurn = [self.route.turnInstructions objectAtIndex:0];
        [labelDistanceToNextTurn setText:formatDistance(nextTurn.lengthInMeters)];
        [imgNextTurnDirection setImage:[nextTurn largeDirectionIcon]];
    } else {
        [minimizedInstructionsView setHidden:YES];
    }
}

- (NSDictionary*) addRouteAnnotation:(SMRoute *)r {
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:[r getStartLocation].coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                         @"linePoints" : [NSArray arrayWithArray:r.waypoints],
                                         @"lineColor" : PATH_COLOR,
                                         @"fillColor" : [UIColor clearColor],
                                         @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                         };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:r.waypoints]];
    [self.mpView addAnnotation:calculatedPathAnnotation];
    return @{
             @"neCoordinate" : calculatedPathAnnotation.neCoordinate,
             @"swCoordinate" : calculatedPathAnnotation.swCoordinate
             };
}

- (void)resetZoom {
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];
    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:[SMLocationManager instance].lastValidLocation.coordinate] animated:YES];
}

- (void)zoomToLocation:(CLLocation*)loc temporary:(BOOL)isTemp {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    [self.mpView setZoom:DEFAULT_TURN_ZOOM];
    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:loc.coordinate] animated:YES];
    [self.mpView setCenterCoordinate:loc.coordinate];
    
    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing) {
        [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        if (isTemp) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
            [self performSelector:@selector(resetZoomTurn) withObject:nil afterDelay:ZOOM_TO_TURN_DURATION];
        }
    }
}

- (void)saveRoute {
    if (self.route && self.route.visitedLocations && ([self.route.visitedLocations count] > 0)) {
        NSData * data = [self.route save];
        NSDictionary * d = @{
                             @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[[self.route.visitedLocations objectAtIndex:0] objectForKey:@"date"]],
                             @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[[self.route.visitedLocations lastObject] objectForKey:@"date"]],
                             @"visitedLocations" : data,
                             @"fromName" : self.source,
                             @"toName" : self.destination,
                             @"fromLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.startLocation],
                             @"toLocation" : [NSKeyedArchiver archivedDataWithRootObject:self.endLocation]
                             };
        BOOL x = [d writeToFile:[SMUtil routeFilenameFromTimestampForExtension:@"plist"] atomically:YES];
        if (x == NO) {
            NSLog(@"Route not saved!");
        }
    }
}

#pragma mark - mapView delegate

- (void)checkCallouts {
    for (SMAnnotation * annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation showCallout];
            }
        }
    }
}

- (void)mapViewRegionDidChange:(RMMapView *)mapView {
    [self checkCallouts];
}

- (void)tapOnAnnotation:(SMAnnotation *)annotation onMap:(RMMapView *)map {
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        for (id v in self.mpView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        
        if ([annotation calloutShown]) {
            [annotation hideCallout];
        } else {
            [annotation showCallout];
        }
    }
}

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"path"]) {
        RMShape *path = [[RMShape alloc] initWithView:aMapView];
        [path setZPosition:-MAXFLOAT];
        [path setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [path setOpacity:PATH_OPACITY];
        [path setFillColor:[annotation.userInfo objectForKey:@"fillColor"]];
        [path setLineWidth:[[annotation.userInfo objectForKey:@"lineWidth"] floatValue]];
        path.scaleLineWidth = NO;

        if ([[annotation.userInfo objectForKey:@"closePath"] boolValue])
            [path closePath];

        @synchronized([annotation.userInfo objectForKey:@"linePoints"]) {
            for (CLLocation *location in [annotation.userInfo objectForKey:@"linePoints"]) {
                [path addLineToCoordinate:location.coordinate];
            }
        }

        return path;
    }
    
    if ([annotation.annotationType isEqualToString:@"line"]) {
        RMShape *line = [[RMShape alloc] initWithView:aMapView];
        [line setZPosition:-MAXFLOAT];
        [line setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [line setOpacity:PATH_OPACITY];
        [line setFillColor:[annotation.userInfo objectForKey:@"fillColor"]];
        [line setLineWidth:[[annotation.userInfo objectForKey:@"lineWidth"] floatValue]];
        line.scaleLineWidth = YES;

        CLLocation *start = [annotation.userInfo objectForKey:@"lineStart"];
        [line addLineToCoordinate:start.coordinate];
        CLLocation *end = [annotation.userInfo objectForKey:@"lineEnd"];
        [line addLineToCoordinate:end.coordinate];

        return line;
    }
    
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        RMMarker * rm = [[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
        [rm setZPosition:100];
        return rm;
    }
    
    return nil;
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
   if (self.currentlyRouting && self.route && userLocation) {
       [self.route visitLocation:userLocation.location];
       
       [self setDirectionsState:currentDirectionsState];
       
       [self reloadFirstSwipableView];
       
       [labelDistanceLeft setText:formatDistance(self.route.distanceLeft)];
       
       CGFloat percent = 0;
       @try {
           if ((self.route.distanceLeft + self.route.tripDistance) > 0) {
               percent = self.route.tripDistance / (self.route.distanceLeft + self.route.tripDistance);               
           }
       }
       @catch (NSException *exception) {
           percent = 0;
       }
       @finally {
           
       }
       
       if (self.route) {
           
       }
       
       CGFloat time = self.route.distanceLeft * self.route.estimatedTimeForRoute / self.route.estimatedRouteDistance;
       [labelTimeLeft setText:expectedArrivalTime(time)];

       [tblDirections reloadData];
       [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void)beforeMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        debugLog(@"before map move");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
    }
    [self checkCallouts];
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    debugLog(@"After map zoom!!!! wasUserAction = %d", wasUserAction);
    if (wasUserAction) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
    }
    [self checkCallouts];
}

#pragma mark - route delegate

- (void)routeNotFound {
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    
    [self setDirectionsState:directionsHidden];
    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
}

- (void)startRoute {
    if (overviewShown) {
        return;
    }
    currentDirectionsState = directionsNormal;
    [routeOverview setHidden:YES];
    
    // Display new path
    [self addRouteAnnotation:self.route];
    
    [self.mpView setRoutingDelegate:self];
    
    
    [tblDirections reloadData];
    
    [self setDirectionsState:directionsNormal];
    
    self.currentlyRouting = YES;
    
    [self reloadSwipableView];
    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:expectedArrivalTime(self.route.estimatedTimeForRoute)];
    
    [recalculatingView setAlpha:1.0f];
    [UIView animateWithDuration:0.3f animations:^{
        [recalculatingView setAlpha:0.0f];
    }];
}

- (void) updateTurn:(BOOL)firstElementRemoved {
    
    @synchronized(self.route.turnInstructions) {
        
        [self reloadSwipableView];
        
        if (firstElementRemoved) {
            if ([tblDirections numberOfRowsInSection:0] > 0) {
                [tblDirections deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
        
//        if (self.route.turnInstructions.count < self.directionsShownCount && self.directionsShownCount <= 3) 
//            [self showDirections:self.route.turnInstructions.count];
        [self setDirectionsState:currentDirectionsState];
        
        [tblDirections performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];        
        [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void) reachedDestination {
    [self updateTurn:NO];

    CGFloat distance = [self.route calculateDistanceTraveled];
    [finishDistance setText:formatDistance(distance)];
    [finishTime setText:[self.route timePassed]];

    /**
     * save route data
     */
    [self saveRoute];
    
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@""];
    [labelTimeLeft setText:@""];
    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [finishDestination setText:[a objectAtIndex:0]];
    
    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [UIView animateWithDuration:0.4f animations:^{
        [finishFadeView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        [self setDirectionsState:directionsHidden];
        [labelDistanceLeft setText:@""];
        [labelTimeLeft setText:@""];
    }];
    
    /**
     * enable screen time out 
     */
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    /**
     * remove delegate so we don't correct position and heading any more
     */
    [self.mpView setRoutingDelegate:nil];
    
    /**
     * show actual route travelled
     */
    [self showRouteTravelled];
}

- (void)showRouteTravelled {
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
        }
    }
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:self.route.visitedLocations];
    for (NSDictionary * d in self.route.visitedLocations) {
        [arr addObject:[d objectForKey:@"location"]];
    }
    
    CLLocation * loc = nil;
    if (arr && [arr count] > 0) {
        loc = [arr objectAtIndex:0];
    }
    
    RMAnnotation *calculatedPathAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:loc.coordinate andTitle:nil];
    calculatedPathAnnotation.annotationType = @"path";
    calculatedPathAnnotation.userInfo = @{
                                          @"linePoints" : [NSArray arrayWithArray:arr],
                                          @"lineColor" : PATH_COLOR,
                                          @"fillColor" : [UIColor clearColor],
                                          @"lineWidth" : [NSNumber numberWithFloat:10.0f],
                                          };
    [calculatedPathAnnotation setBoundingBoxFromLocations:[NSArray arrayWithArray:arr]];
    [self.mpView addAnnotation:calculatedPathAnnotation];
}

- (void) updateRoute {
    // Remove previous path and display new one
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
        }
    }
    [self addRouteAnnotation:self.route];

    [tblDirections reloadData];
}

- (void)routeRecalculationStarted {
    dispatch_async(dispatch_get_main_queue(), ^{
        [recalculatingView setAlpha:0.0f];
        [UIView animateWithDuration:0.3f animations:^{
            [recalculatingView setAlpha:1.0f];
        }];
    });
}

- (void)routeRecalculationDone {
    dispatch_async(dispatch_get_main_queue(), ^{
        [recalculatingView setAlpha:1.0f];
        [self reloadSwipableView];
        [UIView animateWithDuration:0.3f animations:^{
            [recalculatingView setAlpha:0.0f];
        }];
    });
}

#pragma mark - button actions

- (IBAction)reportError:(id)sender {
    [self performSegueWithIdentifier:@"reportError" sender:nil];
}

- (IBAction)hideFinishView:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [finishFadeView setAlpha:0.0f];
    }];
}

- (IBAction)hideStopView:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [stopView setAlpha:0.0f];
    }];
}

- (IBAction)goBack:(id)sender {
    self.currentlyRouting = NO;
    
    [self.mpView setDelegate:nil];
    [self.mpView setRoutingDelegate:nil];
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    self.mpView = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [self saveRoute];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)buttonPressed:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [stopView setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];    
}

- (void)trackingOn {
    debugLog(@"trackingOn() btn state = 0x%0x, prev btn state = 0x%0x", buttonTrackUser.gpsTrackState, buttonTrackUser.prevGpsTrackState);
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing) {
        if (buttonTrackUser.prevGpsTrackState == SMGPSTrackButtonStateFollowing) {
            [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
        } else {
            [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
        }
    } else if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateFollowing) {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
    } else {
        // next state is follow
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    }
}

-(IBAction)trackUser:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
    [self resetZoom];

    CLLocationCoordinate2D center;
    if ([SMLocationManager instance].hasValidLocation)
        center = [SMLocationManager instance].lastValidLocation.coordinate;
    else
        center = self.startLocation.coordinate;
    [self.mpView setCenterCoordinate:center animated:NO];

    [self trackingOn];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([segue.identifier isEqualToString:@"reportError"]) ){
        SMReportErrorController *destViewController = segue.destinationViewController;
        NSMutableArray * arr = [NSMutableArray array];
        if (self.route) {
            @synchronized(self.route.pastTurnInstructions) {
                if (self.route) {
                    for (SMTurnInstruction * t in self.route.pastTurnInstructions) {
                        [arr addObject:[t fullDescriptionString]];
                    }                    
                }
            }
            @synchronized(self.route.turnInstructions) {
                if (self.route) {
                    for (SMTurnInstruction * t in self.route.turnInstructions) {
                        [arr addObject:[t fullDescriptionString]];
                    }
                }
            }
        }
        [destViewController setRouteDirections:arr];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.route.turnInstructions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int i = [indexPath row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(i == 0 ? @"topDirectionCell" : @"directionCell")];

    if (i >= 0 && i < self.route.turnInstructions.count) {
        SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
        /**
         * Replace "Destination reached" message with your address
         */
        if (turn.drivingDirection == 15) {
            turn.descriptionString = self.destination;
        }
        if (i == 0)
            [(SMDirectionTopCell *)cell renderViewFromInstruction:turn];
        else
            [(SMDirectionCell *)cell renderViewFromInstruction:turn];
        
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:indexPath.row];
    if (indexPath.row == 0) {
        return [SMDirectionTopCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
    } else {
        return [SMDirectionCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
    }
}

#pragma mark - UITableViewDelegate methods

- (void)resetZoomTurn {
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing)
        [self trackUser:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    int i = [indexPath row];
    if (i < 0 || i >= self.route.turnInstructions.count)
        return;
    SMTurnInstruction *selectedTurn = [self.route.turnInstructions objectAtIndex:i];

    [self zoomToLocation:selectedTurn.loc temporary:YES];
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 2:
            [self performSegueWithIdentifier:@"reportError" sender:nil];
            break;
        case 1: {
            [self goBack:nil];
        }
            break;
        default:
            break;
    }
}

#pragma mark - directions table

/**
 * set new direction state
 */
- (void)setDirectionsState:(DirectionsState)state {
    switch (state) {
        case directionsFullscreen: {
            CGRect frame = tblDirections.frame;
            frame.size.height = instructionsView.frame.size.height - tblDirections.frame.origin.y;
            [tblDirections setFrame:frame];
            [tblDirections setScrollEnabled:YES];
            CGFloat newY = self.mpView.frame.origin.y + MAX_TABLE;
            [self repositionInstructionsView:newY + 1];
            lastDirectionsPos = newY + 1;
        }
            break;
        case directionsNormal: {
            [instructionsView setHidden:NO];
            [minimizedInstructionsView setHidden:YES];
            int maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
            CGFloat tblHeight = 0.0f;
            CGFloat newY = 0;
            @synchronized(self.route.turnInstructions) {
                if ([self.route.turnInstructions count] > 0) {
                    tblHeight = [SMDirectionTopCell getHeightForDescription:[[self.route.turnInstructions objectAtIndex:0] descriptionString] andWayname:[[self.route.turnInstructions objectAtIndex:0] wayName]];                    
                }
            }
            newY = maxY - tblHeight;
            [self repositionInstructionsView:newY + 1];
            lastDirectionsPos = newY + 1;
            [swipableView setHidden:NO];
            [swipableView setFrame:tblDirections.frame];
            [tblDirections setScrollEnabled:NO];

        }
            break;
        case directionsMini:
            [instructionsView setHidden:YES];
            [minimizedInstructionsView setHidden:NO];
            [self repositionInstructionsView:self.view.frame.size.height];
            [tblDirections setScrollEnabled:NO];
            lastDirectionsPos = self.view.frame.size.height;
            break;
        case directionsHidden:
            [instructionsView setHidden:YES];
            [minimizedInstructionsView setHidden:YES];
            [self repositionInstructionsView:self.view.frame.size.height];
            lastDirectionsPos = self.view.frame.size.height;
            break;
        default:
            break;
    }
    currentDirectionsState = state;
}


- (void)resizeMap {
    CGRect frame = self.mpView.frame;
    frame.size.height = instructionsView.frame.origin.y - frame.origin.y;
    [self.mpView setFrame:frame];
    
}

- (void)repositionInstructionsView:(CGFloat)newY {
    CGRect frame = instructionsView.frame;
    frame.size.height += frame.origin.y - newY;
    frame.origin.y = newY;
    [instructionsView setFrame:frame];
    
    [self resizeMap];
}

- (void)repositionSwipableView:(CGFloat)newY {
    CGRect frame = swipableView.frame;
    frame.size.height += frame.origin.y - newY;
    frame.origin.y = newY;
    [swipableView setFrame:frame];
}

- (IBAction)onPanGestureDirections:(UIPanGestureRecognizer *)sender {
    [tblDirections scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [instructionsView setHidden:NO];
    [minimizedInstructionsView setHidden:YES];
    if (sender.state == UIGestureRecognizerStateEnded) {
        float newY = [sender locationInView:self.view].y;        
        switch (currentDirectionsState) {
            case directionsFullscreen:
                if (newY > lastDirectionsPos + 20.0f) {
                    [self setDirectionsState:directionsNormal];
                } else {
                    [self setDirectionsState:directionsFullscreen];
                }
                break;
            case directionsNormal:
                if (newY > lastDirectionsPos + 20.0f) {
                    [self setDirectionsState:directionsMini];
                } else if (newY < lastDirectionsPos - 20.0f) {
                    [self setDirectionsState:directionsFullscreen];
                } else {
                    [self setDirectionsState:directionsNormal];
                }
                break;
            case directionsMini:
                if (newY < lastDirectionsPos - 20.0f) {
                    [self setDirectionsState:directionsNormal];
                } else {
                    [self setDirectionsState:directionsMini];
                }                
                break;
            case directionsHidden:
                break;                
            default:
                break;
        }
        
        
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        [swipableView setHidden:YES];
        float newY = MAX([sender locationInView:self.view].y - touchOffset, self.mpView.frame.origin.y);
        [self repositionInstructionsView:newY];
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        touchOffset = [sender locationInView:instructionsView].y;
        [swipableView setHidden:YES];
    }
}

#pragma mark - swipable view

- (SMSwipableView*)getRecycledItemOrCreate {
    SMSwipableView * cell = [self.recycledItems anyObject];
    if (cell == nil) {
        cell = [SMSwipableView getFromNib];
    } else {
        [self.recycledItems removeObject:cell];
    }
    [cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];    
    return cell;
}

- (void)reloadFirstSwipableView {
    for (SMSwipableView * cell in self.activeItems) {
        if (cell.position == 0) {
            SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:0];
            [cell renderViewFromInstruction:turn];
        }
    }
}

- (void)reloadSwipableView {
    [swipableView setFrame:tblDirections.frame];
    @synchronized(self.instructionsForScrollview) {
        self.instructionsForScrollview = [NSArray arrayWithArray:self.route.turnInstructions];
        for (SMSwipableView * cell in self.activeItems) {
            cell.position = -1;
            [self.recycledItems addObject:cell];
            [cell removeFromSuperview];
        }
        [self.activeItems minusSet:self.recycledItems];
    }
    
    [swipableView setContentSize:CGSizeMake(self.view.frame.size.width * ([self.instructionsForScrollview count]), swipableView.frame.size.height)];
    [self showVisible];
}

- (BOOL)isVisible:(NSUInteger)index {
    for (SMSwipableView * cell in self.activeItems) {
        if (cell.position == index) {
            return YES;
        }
    }
    return NO;
}

- (void)showVisible {
    @synchronized(self.instructionsForScrollview) {
        NSInteger start = MAX(0, floor(swipableView.contentOffset.x / self.view.frame.size.width));
        NSUInteger end = MIN(ceil(swipableView.contentOffset.x / self.view.frame.size.width), [self.instructionsForScrollview count] - 1);
        for (SMSwipableView * cell in self.activeItems) {
            if (cell.position < start || cell.position > end) {
                cell.position = -1;
                [self.recycledItems addObject:cell];
                [cell removeFromSuperview];
            }
        }
        [self.activeItems minusSet:self.recycledItems];
        
        if (start < [self.instructionsForScrollview count] && end < [self.instructionsForScrollview count]) {
            for (int i = start; i <= end; i++) {
                SMSwipableView * cell = nil;
                if ([self isVisible:i] == NO) {
                    cell = [self getRecycledItemOrCreate];
                    [self.activeItems addObject:cell];
                    cell.position = i;
                    SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:i];
                    [cell setFrame:CGRectMake(i*swipableView.frame.size.width, 0, swipableView.frame.size.width, [SMSwipableView getHeight])];
                    [cell renderViewFromInstruction:turn];
                    [swipableView addSubview:cell];
                }
            }
            
            if (start == end) {
                if (start == 0) {
                    /**
                     * start tracking the user if we're back to first instruction
                     * we also start updating the swipable view
                     */
                    self.updateSwipableView = YES;
                    [self resetZoomTurn];
                } else {
                    /**
                     * we're not on the first instruction
                     */
                    self.updateSwipableView = NO;
                    SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:start];
                    [self zoomToLocation:turn.loc temporary:NO];
                }
            } else {
                self.updateSwipableView = NO;
            }            
        }
    [swipableView setContentSize:CGSizeMake(swipableView.contentSize.width, swipableView.frame.size.height)];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self showVisible];
}

#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"currentlyRouting"]) {
        /**
         * hide/show views depending onwhether we're currently routing or not
         */
        if (self.currentlyRouting) {
            [progressView setHidden:NO];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        } else {
            [self setDirectionsState:directionsHidden];
            [minimizedInstructionsView setHidden:YES];
            [progressView setHidden:YES];
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        }
    } else if (object == swipableView && [keyPath isEqualToString:@"hidden"]) {
        /**
         * observer that hides directions table when swipable view is shown
         */
        if (swipableView.hidden) {
            [tblDirections setAlpha:1.0f];
        } else {
            [tblDirections setAlpha:0.0f];
        }
    } else if (object == self.mpView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mpView.userTrackingMode == RMUserTrackingModeFollow) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeNone) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        }
    } else if (object == self.mapFade && [keyPath isEqualToString:@"frame"]) {
        CGFloat maxSize = self.view.frame.size.height - 160.0f;
        if (self.mapFade.frame.size.height > maxSize) {
            [self.mapFade setAlpha:0.0f];
        } else {
            [self.mapFade setAlpha: 0.8f - ((self.mapFade.frame.size.height - MAX_TABLE) * 0.8f / (maxSize - MAX_TABLE))];
        }
        
        if (self.mapFade.alpha > 0.7f) {
            [arrivalBG setImage:[UIImage imageNamed:@"routeArrivalDark"]];
            [closeButton setImage:[UIImage imageNamed:@"btnCloseDark"] forState:UIControlStateNormal];
            [labelDistanceLeft setTextColor:[UIColor whiteColor]];
            [labelTimeLeft setTextColor:[UIColor whiteColor]];
            [buttonTrackUser setHidden:YES];
        } else {
            [arrivalBG setImage:[UIImage imageNamed:@"routeArrival"]];
            [closeButton setImage:[UIImage imageNamed:@"btnClose"] forState:UIControlStateNormal];
            [labelDistanceLeft setTextColor:[UIColor darkGrayColor]];
            [labelTimeLeft setTextColor:[UIColor darkGrayColor]];
            [buttonTrackUser setHidden:NO];
        }
        
        debugLog(@"size: %f maxSize: %f alpha: %f", self.mapFade.frame.size.height, maxSize, self.mapFade.alpha);
    }
}

#pragma mark - routing delegate

- (double)getCorrectedHeading {
    return [self.route getCorrectedHeading];
}

- (CLLocation *)getCorrectedPosition {
    return self.route.lastCorrectedLocation;
}

@end
