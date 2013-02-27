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
#import "SMFindAddressController.h"

#import "SMTurnInstruction.h"
#import "SMRoute.h"
#import "SMFindAddressController.h"
#import "SMDirectionCell.h"
#import "SMDirectionTopCell.h"
#import "SMRouteFinishedController.h"
#import "SMReportErrorController.h"

#import "SMUtil.h"

#import "SMAnnotation.h"

@interface SMRouteNavigationController ()
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recycledItems = [NSMutableSet set];
    self.activeItems = [NSMutableSet set];
//    [swipableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    [instructionsView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];
    self.updateSwipableView = YES;
    
    [RMMapView class];
    
    self.currentlyRouting = NO;
    self.directionsShownCount = -1;

    [SMLocationManager instance];
    
    [self.mpView setTileSource:TILE_SOURCE];
    
    [self.mpView setDelegate:self];
    
    //    [self findRouteFrom:CLLocationCoordinate2DMake(55.6785507, 12.5375865) to:CLLocationCoordinate2DMake(55.680805,12.5555466)];
    
    [self hideDirections];
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
    [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateFollowingWithHeading];
    [self.mpView setTriggerUpdateOnHeadingChange:NO];
    [self.mpView setDisplayHeadingCalibration:NO];
    [self.mpView setEnableBouncing:TRUE];
    
//    [self.mpView zoomByFactor:16 near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:YES];
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];

    // Start tracking location only when user starts it through UI
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate];
    }

    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [labelDestination setText:[a objectAtIndex:0]];
    [labelTimeLeft setText:@"---"];
    [labelDistanceLeft setText:@"---"];

    [tblDirections setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
//    [self.mpView setOrderMarkersByYPosition:YES];
    
    [self addObserver:self forKeyPath:@"currentlyRouting" options:0 context:nil];
    [swipableView addObserver:self forKeyPath:@"hidden" options:0 context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tblDirections reloadData];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPosition) name:@"refreshPosition" object:nil];

//    [buttonTrackUser setEnabled:NO];

    if (self.currentlyRouting) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload {
    self.mpView.delegate = nil;
    self.mpView = nil;
    self.route.delegate = nil;
    self.route = nil;
    tblDirections = nil;
    buttonNewStop = nil;
    instructionsView = nil;
    progressBar = nil;
    labelTimeLeft = nil;
    labelDestination = nil;
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
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//}

- (void) start:(CLLocationCoordinate2D)from end:(CLLocationCoordinate2D)to  {
    
    if (self.mpView.delegate == nil) {
        self.mpView.delegate = self;
    }
    
    for (RMAnnotation *annotation in self.mpView.annotations) {
        [self.mpView removeAnnotation:annotation];
    }

    self.route = [[SMRoute alloc] initWithRouteStart:from andEnd:to andDelegate:self];
    if (!self.route) {
        return;
    }
//    [self updateTurn:NO];
//
//    // Display new path
//    [self addRouteAnnotation:self.route];

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
//    [self showDirections:1];
//
//    self.currentlyRouting = YES;
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
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

//- (void) refreshPosition {
//    if (self.currentlyRouting && self.route && [SMLocationManager instance].hasValidLocation) {
//
//        CLLocation *location = [SMLocationManager instance].lastValidLocation;
//    }
//}

//- (void) addLineAnnotation:(CLLocation *)start end:(CLLocation *)end {
//    if (!start || !end)
//        return;
//
//    RMAnnotation *lineAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:start.coordinate andTitle:nil];
//    lineAnnotation.annotationType = @"line";
//    lineAnnotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                         start,@"lineStart",
//                                         end,@"lineEnd",
//                                         [UIColor redColor],@"lineColor",
//                                         [UIColor clearColor],@"fillColor",
//                                         [NSNumber numberWithFloat:9.0f],@"lineWidth",
//                                         nil];
//    [lineAnnotation setBoundingBoxFromLocations:[NSMutableArray arrayWithObjects:start, end, nil]];
//    [self.mpView addAnnotation:lineAnnotation];
//}

- (void) addRouteAnnotation:(SMRoute *)r {
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
}

- (void)resetZoom {
    //  [self.mpView zoomByFactor:(self.mpView.zoom - 5) near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:YES];
    //    [self.mpView zoomOutToNextNativeZoomAt:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f)  animated:YES];
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];
    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:[SMLocationManager instance].lastValidLocation.coordinate] animated:YES];
}

- (void)zoomToLocation:(CLLocation*)loc temporary:(BOOL)isTemp {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
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
//       debugLog(@"didUpdateUserLocation()");
       [self.route visitLocation:userLocation.location];
//       [self renderMinimizedDirectionsViewFromInstruction];
       [self showDirections:self.directionsShownCount];
       
       [labelDistanceLeft setText:formatDistance(self.route.distanceLeft)];
       
       CGFloat percent = self.route.tripDistance / (self.route.distanceLeft + self.route.tripDistance);
       CGRect frame = progressBar.frame;
       frame.size.width = 306.0f * percent;
       [progressBar setFrame:frame];
       
       
//       float avgSpeed = [self.route calculateAverageSpeed];
//       if (!avgSpeed)
//           [labelTimeLeft setText:@""];
//       else {
           CGFloat time = self.route.distanceLeft * self.route.estimatedTimeForRoute / self.route.estimatedRouteDistance;
           [labelTimeLeft setText:formatTimeLeft(time)];
//       }

       [tblDirections reloadData];
       [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void)beforeMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        debugLog(@"before map move");
//        [buttonTrackUser setEnabled:YES];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
        [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateNotFollowing];
    }
    [self checkCallouts];
}

//- (void)beforeMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
//    debugLog(@"beforeMapZoom() wasUserAction = %@", wasUserAction ? @"YES" : @"NO");
//    if (wasUserAction) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
//        [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateNotFollowing];
//    }
//}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    debugLog(@"After map zoom!!!! wasUserAction = %d", wasUserAction);
    if (wasUserAction) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
        [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateNotFollowing];
    }
    [self checkCallouts];
}

#pragma mark - route delegate

- (void)routeNotFound {
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@"--"];
    [labelTimeLeft setText:@"--"];
    [labelDestination setText:@""];
    
    CGRect frame = progressBar.frame;
    frame.size.width = 0.0f;
    [progressBar setFrame:frame];
    
    [self showDirections:0];
    
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
}

- (void)startRoute {
//    [self updateTurn:NO];
    
    // Display new path
    [self addRouteAnnotation:self.route];
    
    [tblDirections reloadData];
    
    [self showDirections:1];
    
    self.currentlyRouting = YES;
    
    [self reloadSwipableView];
    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    
    [labelDistanceLeft setText:formatDistance(self.route.estimatedRouteDistance)];
    [labelTimeLeft setText:formatTimeLeft(self.route.estimatedTimeForRoute)];
    
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
        
        if (self.route.turnInstructions.count < self.directionsShownCount && self.directionsShownCount <= 3) 
            [self showDirections:self.route.turnInstructions.count];
        
        [tblDirections performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];        
        [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void) reachedDestination {
    [self updateTurn:NO];

    CGFloat distance = [self.route calculateDistanceTraveled];
    [finishDistance setText:formatDistance(distance)];
    
    [finishTime setText:[self.route timePassed]];

    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshPosition" object:nil];
    
    [self saveRoute];
    
    self.currentlyRouting = NO;
    
    [labelDistanceLeft setText:@"--"];
    [labelTimeLeft setText:@"--"];
    [labelDestination setText:@""];
    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [finishDestination setText:[a objectAtIndex:0]];
    
    CGRect frame = progressBar.frame;
    frame.size.width = 0.0f;
    [progressBar setFrame:frame];

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [UIView animateWithDuration:0.4f animations:^{
        [finishFadeView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        [self hideDirections];
        [labelDistanceLeft setText:@"--"];
        [labelTimeLeft setText:@"--"];
        [labelDestination setText:@""];
    }];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void) updateRoute {
//    self.directions = [self.route getRelevantDirections];

    // Remove previous path and display new one
    for (RMAnnotation *annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"path"]) {
            [self.mpView removeAnnotation:annotation];
            break;
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

- (IBAction)hideFinishView:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [finishFadeView setAlpha:0.0f];
    }];
}

- (IBAction)goBack:(id)sender {
    [self removeObserver:self forKeyPath:@"currentlyRouting" context:nil];
    [swipableView removeObserver:self forKeyPath:@"hidden" context:nil];
    self.currentlyRouting = NO;
    
    [self.mpView setDelegate:nil];
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    self.mpView = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [self saveRoute];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)buttonPressed:(id)sender {
    if (self.currentlyRouting) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"route_stop_title") message:translateString(@"route_stop_text") delegate:self cancelButtonTitle:nil otherButtonTitles:translateString(@"report_error"), translateString(@"Stop"), nil];
        [av show];
    } else {
        [self performSegueWithIdentifier:@"newRouteSegue" sender:nil];
    }
}

- (void)trackingOn {
    debugLog(@"trackingOn() btn state = 0x%0x, prev btn state = 0x%0x", buttonTrackUser.gpsTrackState, buttonTrackUser.prevGpsTrackState);
    if (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateFollowing ||
        (buttonTrackUser.gpsTrackState == SMGPSTrackButtonStateNotFollowing && buttonTrackUser.prevGpsTrackState == SMGPSTrackButtonStateFollowingWithHeading)) {
        // next state is follow with heading
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
        [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateFollowingWithHeading];
    } else {
        // next state is follow
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
        [buttonTrackUser newGpsTrackState: SMGPSTrackButtonStateFollowing];
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
    [self.mpView setCenterCoordinate:center];

    // trackingOn is called with 1s delay beacuse map view has some strage looking
    // map scroll effect (when you scroll and click gps button to center).
    [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([segue.identifier isEqualToString:@"newRouteSegue"]) ){
        SMFindAddressController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    } else if (([segue.identifier isEqualToString:@"routeFinished"]) ){
        self.mpView.delegate = nil;
        [buttonNewStop setTitle:translateString(@"new_route") forState:UIControlStateNormal];
        SMRouteFinishedController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setCaloriesBurned:[self.route calculateCaloriesBurned]];
        [destViewController setAverageSpeed:[self.route calculateAverageSpeed]];
        [destViewController setRouteDistance:[self.route calculateDistanceTraveled]];
        [destViewController setDestination:self.destination];
    } else if (([segue.identifier isEqualToString:@"reportError"]) ){
        SMReportErrorController *destViewController = segue.destinationViewController;
        NSMutableArray * arr = [NSMutableArray array];
        if (self.route) {
            @synchronized(self.route.pastTurnInstructions) {
                for (SMTurnInstruction * t in self.route.pastTurnInstructions) {
                    [arr addObject:[t fullDescriptionString]];
                }
            }
            @synchronized(self.route.turnInstructions) {
                for (SMTurnInstruction * t in self.route.turnInstructions) {
                    [arr addObject:[t fullDescriptionString]];
                }
            }
        }
        [destViewController setRouteDirections:arr];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
    }
}

#pragma mark - route finder delegate

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    [self setStartLocation:[[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude]];
    [self setEndLocation:[[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude]];
    [self start:self.startLocation.coordinate end:self.endLocation.coordinate];
    self.destination = dst;
    self.source = src;
    
    NSDictionary * d = @{
                         @"endLat": [NSNumber numberWithDouble:self.endLocation.coordinate.latitude],
                         @"endLong": [NSNumber numberWithDouble:self.endLocation.coordinate.longitude],
                         @"startLat": [NSNumber numberWithDouble:self.startLocation.coordinate.latitude],
                         @"startLong": [NSNumber numberWithDouble:self.startLocation.coordinate.longitude],
                         @"destination": dst,
                         };

    NSString * s = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"];
    BOOL x = [d writeToFile:s atomically:NO];
    if (x == NO) {
        NSLog(@"Temp route not saved!");
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
////  [self.mpView zoomByFactor:(self.mpView.zoom - 5) near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:YES];
////    [self.mpView zoomOutToNextNativeZoomAt:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f)  animated:YES];
//    [self.mpView setZoom:DEFAULT_MAP_ZOOM];
//    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:[SMLocationManager instance].lastValidLocation.coordinate] animated:YES];
//
//    if (self.route.visitedLocations.count > 0)
//        [self.mpView setCenterCoordinate:((CLLocation *)[[self.route.visitedLocations lastObject] objectForKey:@"location"]).coordinate];
//    else
//        [self.mpView setCenterCoordinate:self.startLocation.coordinate];
//
//    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
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
//    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
//    [self.mpView setZoom:DEFAULT_TURN_ZOOM];
//    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:selectedTurn.loc.coordinate] animated:YES];
//    [self.mpView setCenterCoordinate:selectedTurn.loc.coordinate];
//
//    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing) {
//        [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
//
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
//        [self performSelector:@selector(resetZoomTurn) withObject:nil afterDelay:ZOOM_TO_TURN_DURATION];
//    }
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self performSegueWithIdentifier:@"reportError" sender:nil];
            break;
        case 1: {
            self.currentlyRouting = NO;
            [buttonNewStop setTitle:translateString(@"new_route") forState:UIControlStateNormal];
            
            [labelDistanceLeft setText:@"--"];
            [labelTimeLeft setText:@"--"];
            [labelDestination setText:@""];
            
            CGRect frame = progressBar.frame;
            frame.size.width = 0.0f;
            [progressBar setFrame:frame];
            
            [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
            
            
            [self saveRoute];
            
            CGFloat distance = [self.route calculateDistanceTraveled];
            [finishDistance setText:formatDistance(distance)];
            [finishTime setText:[self.route timePassed]];
            NSArray * a = [self.destination componentsSeparatedByString:@","];
            [finishDestination setText:[a objectAtIndex:0]];
            [UIView animateWithDuration:0.4f animations:^{
                [finishFadeView setAlpha:1.0f];
            } completion:^(BOOL finished) {
                self.route = nil;
                [self.mpView removeAllAnnotations];
                [tblDirections reloadData];
                [self showDirections:0];
            }];
        }
            break;
        default:
            break;
    }
}

#pragma mark - directions table

- (void)hideDirections {
    [self showDirections:0];
}

- (void)showDirections:(NSInteger)segments {
    self.directionsShownCount = segments;

    if (!self.route || !self.route.turnInstructions || self.route.turnInstructions.count <= 0) {
        [instructionsView setHidden:YES];
        [minimizedInstructionsView setHidden:YES];
        [self repositionInstructionsView:self.view.frame.size.height];
        return;
    }

    BOOL fullscreen = NO;
    if (segments == 0) {
        [instructionsView setHidden:YES];
        [minimizedInstructionsView setHidden:NO];
        [self repositionInstructionsView:self.view.frame.size.height];
    } else {
        [instructionsView setHidden:NO];
        [minimizedInstructionsView setHidden:YES];
        int maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
        /**
         * dynamic cell resizing
         */
        CGFloat tblHeight = 0.0f;
        @synchronized(self.route.turnInstructions) {
            for (int i = 0; i < MIN(segments, [self.route.turnInstructions count]); i++) { 
                SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
                if (i == 0) {
                    tblHeight += [SMDirectionTopCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                } else {
                    tblHeight += [SMDirectionCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                }
            }
        }
//        tblHeight = MAX(100.0f, tblHeight);
        int newY = maxY - tblHeight;
        if (newY < self.mpView.frame.origin.y || (newY - self.mpView.frame.origin.y) < 50.0f) {
            newY = self.mpView.frame.origin.y;
            fullscreen = YES;
        }
        
        [self repositionInstructionsView:newY + 1];
    }

    if (fullscreen) {
        CGRect frame = tblDirections.frame;
        frame.size.height = instructionsView.frame.size.height - tblDirections.frame.origin.y;
        [tblDirections setFrame:frame];
        [tblDirections setScrollEnabled:YES];
    } else {
        if (segments == 1) {
            [swipableView setHidden:NO];
            [swipableView setFrame:tblDirections.frame];
        }
        [tblDirections setScrollEnabled:NO];
    }
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
        float maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
        float cellCount = self.route.turnInstructions.count;
        float newY = [sender locationInView:self.view].y;

        if (cellCount < self.directionsShownCount) {
            self.directionsShownCount = cellCount;
            [self showDirections:cellCount];
            return;
        }
        
        /**
         * dynamic row height repositioning
         */
        CGFloat tblHeight = 0.0f;
        CGFloat height = 0.0f;
        @synchronized(self.route.turnInstructions) {
            for (int i = 0; i < cellCount; i++) {
                SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
                if (i == 0) {
                    height = [SMDirectionTopCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                } else {
                    height = [SMDirectionCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                }
                
                if (newY > maxY - (tblHeight + height*0.5)) {
                    [self showDirections:i];
                    return;
                }
                tblHeight += height;
            }
        }
        [self showDirections:cellCount];
        
        
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        [self repositionInstructionsView:MAX([sender locationInView:self.view].y, self.mpView.frame.origin.y)];
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        [swipableView setHidden:YES];
    }
}

#pragma mark - swipable view

- (SMDirectionTopCell*)getRecycledItemOrCreate {
    SMDirectionTopCell * cell = [self.recycledItems anyObject];
    if (cell == nil) {
        cell = [tblDirections dequeueReusableCellWithIdentifier:@"topDirectionCell"];
    } else {
        [self.recycledItems removeObject:cell];
    }
    [cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBG"]]];    
    return cell;
}

- (void)reloadSwipableView {
    [swipableView setFrame:tblDirections.frame];
    @synchronized(self.instructionsForScrollview) {
        self.instructionsForScrollview = [NSArray arrayWithArray:self.route.turnInstructions];
    }
    for (SMDirectionTopCell * cell in self.activeItems) {
        [cell removeFromSuperview];
        cell.position = 0;
        [self.recycledItems addObject:cell];
    }
    [self.activeItems minusSet:self.recycledItems];
    [swipableView setContentSize:CGSizeMake(self.view.frame.size.width * ([self.instructionsForScrollview count]), swipableView.frame.size.height)];
    [self showVisible];
}

- (BOOL)isVisible:(NSUInteger)index {
    for (SMDirectionTopCell * cell in self.activeItems) {
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
        for (SMDirectionTopCell * cell in self.activeItems) {
            if (cell.position < start || cell.position > end) {
                cell.position = 0;
                [self.recycledItems addObject:cell];
                [cell removeFromSuperview];
            }
        }
        [self.activeItems minusSet:self.recycledItems];
        
        if (start < [self.instructionsForScrollview count] && end < [self.instructionsForScrollview count]) {
            for (int i = start; i <= end; i++) {
                SMDirectionTopCell * cell = nil;
                if ([self isVisible:i] == NO) {
                    cell = [self getRecycledItemOrCreate];
                    cell.position = i;
                    SMTurnInstruction *turn = (SMTurnInstruction *)[self.instructionsForScrollview objectAtIndex:i];
                    [cell setFrame:CGRectMake(i*swipableView.frame.size.width, 0, swipableView.frame.size.width, [SMDirectionTopCell getHeightForDescription:turn.descriptionString andWayname:turn.wayName])];
                    [cell renderViewFromInstruction:turn];
                    [swipableView addSubview:cell];
                    [self.activeItems addObject:cell];
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

#pragma mark - hiding progress bar etc when not routing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"currentlyRouting"]) {
        /**
         * hide/show views depending onwhether we're currently routing or not
         */
        if (self.currentlyRouting) {
            [progressView setHidden:NO];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [buttonNewStop setTitle:translateString(@"Stop") forState:UIControlStateNormal];
        } else {
            [self showDirections:0];
            [minimizedInstructionsView setHidden:YES];
            [progressView setHidden:YES];
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [buttonNewStop setTitle:translateString(@"new_route") forState:UIControlStateNormal];
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
    }
}

@end
