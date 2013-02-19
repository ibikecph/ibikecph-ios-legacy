    //
//  SMRouteNavigationController.m
//  iBike
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMRouteNavigationController.h"

#import "SMMapView.h"
#import "RMShape.h"
#import "RMPath.h"
#import "RMMarker.h"
#import "RMAnnotation.h"
#import "RMUserLocation.h"

#import "SMiBikeCPHMapTileSource.h"
#import "SMOpenStreetMapTileSource.h"

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

#define DEFAULT_MAP_ZOOM 17
#define DEFAULT_TURN_ZOOM 18

@interface SMRouteNavigationController ()
@property (nonatomic, strong) SMRoute *route;
@property (nonatomic, strong) IBOutlet SMMapView * mpView;
@property int directionsShownCount; // How many directions are shown in the directions table at the moment:
                                    // -1 means no direction is shown and minimized directions view is not shown (this happens before first call to showDirections())
                                    // 0 means no direction is shown and minimized directions view is shown
                                    // > 3 means directions table is maximized
@end

@implementation SMRouteNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMMapView class];
    
    currentlyRouting = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    self.directionsShownCount = -1;

    [SMLocationManager instance];
    
    [self.mpView setTileSource:TILE_SOURCE];
    
    [self.mpView setDelegate:self];
    
    //    [self findRouteFrom:CLLocationCoordinate2DMake(55.6785507, 12.5375865) to:CLLocationCoordinate2DMake(55.680805,12.5555466)];
    
    [self hideDirections];
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
//    [self.mpView setTriggerUpdateOnHeadingChange:NO];
    [self.mpView setDisplayHeadingCalibration:NO];
    
//    [self.mpView zoomByFactor:16 near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:YES];
    [self.mpView setZoom:DEFAULT_MAP_ZOOM];

    // Start tracking location only when user starts it through UI
    if (self.startLocation && self.endLocation) {
        [self start:self.startLocation.coordinate end:self.endLocation.coordinate];
    }

    NSArray * a = [self.destination componentsSeparatedByString:@","];
    [labelDestination setText:[[a objectAtIndex:0] uppercaseString]];
    [labelTimeLeft setText:@"---"];
    [labelDistanceLeft setText:@"---"];

    [tblDirections setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
//    [self.mpView setOrderMarkersByYPosition:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tblDirections reloadData];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPosition) name:@"refreshPosition" object:nil];

    [buttonTrackUser setEnabled:NO];
    
    if (currentlyRouting) {
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
    buttonTrackUser = nil;
    progressView = nil;
    minimizedInstructionsView = nil;
    labelDistanceToNextTurn = nil;
    imgNextTurnDirection = nil;
    finishFadeView = nil;
    finishDistance = nil;
    finishTime = nil;
    recalculatingView = nil;
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
    
    [buttonNewStop setTitle:translateString(@"Stop") forState:UIControlStateNormal];
    
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

    RMAnnotation *startMarkerAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:from andTitle:@"A"];
    startMarkerAnnotation.annotationType = @"marker";
    startMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerStart"];
    startMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    [self.mpView addAnnotation:startMarkerAnnotation];

    RMAnnotation *endMarkerAnnotation = [RMAnnotation annotationWithMapView:self.mpView coordinate:to andTitle:@"B"];
    endMarkerAnnotation.annotationType = @"marker";
    endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
    endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
    [self.mpView addAnnotation:endMarkerAnnotation];
    

    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(from.latitude,from.longitude)];
//    [self showDirections:1];
//
//    currentlyRouting = YES;
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

- (void) refreshPosition {
    if (currentlyRouting && self.route && [SMLocationManager instance].hasValidLocation) {

        CLLocation *location = [SMLocationManager instance].lastValidLocation;
        if (location.speed > 0 || location.course >= 0)
            debugLog(@"refreshPosition() speed = %f, course = %f, acc = %f", location.speed, location.course, location.horizontalAccuracy);

        [self.route visitLocation:location];
        [self renderMinimizedDirectionsViewFromInstruction];

        float distanceLeft = [self.route calculateDistanceToNextTurn:location];
        [labelDistanceLeft setText:formatDistance(distanceLeft)];

        CGFloat percent = self.route.tripDistance / (distanceLeft + self.route.tripDistance);
        CGRect frame = progressBar.frame;
        frame.size.width = 306.0f * percent;
        [progressBar setFrame:frame];

        float avgSpeed = [self.route calculateAverageSpeed];
        if (!avgSpeed)
            [labelTimeLeft setText:@""];
        else {
            CGFloat time = distanceLeft / avgSpeed;
            [labelTimeLeft setText:formatTime(time)];
        }

        [tblDirections reloadData];
        [self renderMinimizedDirectionsViewFromInstruction];
    }
}

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

- (RMMapLayer *)mapView:(SMMapView *)aMapView layerForAnnotation:(RMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"path"]) {
        RMShape *path = [[RMShape alloc] initWithView:aMapView];
        [path setZPosition:-MAXFLOAT];
        [path setLineColor:[annotation.userInfo objectForKey:@"lineColor"]];
        [path setOpacity:0.5f];
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
        [line setOpacity:0.5f];
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

- (void)mapView:(SMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
    // Moved to refreshPosition(), mapView is triggering loc. change for heading changes too, which we don't need
   if (currentlyRouting && self.route) {
       debugLog(@"didUpdateUserLocation()");
        [self.route visitLocation:userLocation.location];
       [self renderMinimizedDirectionsViewFromInstruction];
       
       float distanceLeft = [self.route calculateDistanceToNextTurn:userLocation.location];
       [labelDistanceLeft setText:formatDistance(distanceLeft)];
       
       CGFloat percent = self.route.tripDistance / (distanceLeft + self.route.tripDistance);
       CGRect frame = progressBar.frame;
       frame.size.width = 306.0f * percent;
       [progressBar setFrame:frame];
       
       
       float avgSpeed = [self.route calculateAverageSpeed];
       if (!avgSpeed)
           [labelTimeLeft setText:@""];
       else {
           CGFloat time = distanceLeft / avgSpeed;
           [labelTimeLeft setText:formatTime(time)];
       }

       [tblDirections reloadData];
       [self renderMinimizedDirectionsViewFromInstruction];
    }
}

- (void)afterMapMove:(SMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        [buttonTrackUser setEnabled:YES];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    }
}

- (void)beforeMapZoom:(SMMapView *)map byUser:(BOOL)wasUserAction {
    debugLog(@"beforeMapZoom() wasUserAction = %@", wasUserAction ? @"YES" : @"NO");
    if (wasUserAction) {
        [buttonTrackUser setEnabled:YES];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    }
}

- (void)afterMapZoom:(SMMapView *)map byUser:(BOOL)wasUserAction {
    debugLog(@"After map zoom!!!! wasUserAction = %d", wasUserAction);
    if (wasUserAction) {
        [buttonTrackUser setEnabled:YES];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    }
}

#pragma mark - route delegate

- (void)routeNotFound {
    currentlyRouting = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [buttonNewStop setTitle:translateString(@"new_route") forState:UIControlStateNormal];
    
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
    
    currentlyRouting = YES;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(self.route.locationStart.latitude,self.route.locationStart.longitude)];
    
    [recalculatingView setAlpha:1.0f];
    [UIView animateWithDuration:0.3f animations:^{
        [recalculatingView setAlpha:0.0f];
    }];
}

- (void) updateTurn:(BOOL)firstElementRemoved {
    
    @synchronized(self.route.turnInstructions) {
        [self renderMinimizedDirectionsViewFromInstruction];
        
        if (firstElementRemoved) {
            if ([tblDirections numberOfRowsInSection:0] > 0) {
                [tblDirections deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            }
        }
        
        if ((self.route.turnInstructions.count - 1) < self.directionsShownCount && self.directionsShownCount <= 3) // remove -1 if you want to see "Finished instruction"
            [self showDirections:self.route.turnInstructions.count-1]; // remove -1 if you want to see "Finished instruction"
        
        [tblDirections performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];        
    }
}

- (void) reachedDestination {
    [self updateTurn:NO];

    CGFloat distance = [self.route calculateDistanceTraveled];
    [finishDistance setText:formatDistance(distance)];
    
    [finishTime setText:[self.route timePassed]];

    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshPosition" object:nil];
    
    [self saveRoute];
    
    currentlyRouting = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [buttonNewStop setTitle:translateString(@"new_route") forState:UIControlStateNormal];
    
    [labelDistanceLeft setText:@"--"];
    [labelTimeLeft setText:@"--"];
    [labelDestination setText:@""];
    
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
    currentlyRouting = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self.mpView setDelegate:nil];
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    self.mpView = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"] error:nil];
    
    [self saveRoute];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)buttonPressed:(id)sender {
    if (currentlyRouting) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"route_stop_title") message:translateString(@"route_stop_text") delegate:self cancelButtonTitle:nil otherButtonTitles:translateString(@"report_error"), translateString(@"Stop"), nil];
        [av show];
    } else {
        [self performSegueWithIdentifier:@"newRouteSegue" sender:nil];
    }
}

- (void)trackingOn {
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
}

-(IBAction)trackUser:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    [buttonTrackUser setEnabled:NO];

    [self resetZoom];

    CLLocationCoordinate2D center;
    if ([SMLocationManager instance].hasValidLocation)
        center = [SMLocationManager instance].lastValidLocation.coordinate;
    else
        center = self.startLocation.coordinate;

    if (currentlyRouting) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
        [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
        if ([SMLocationManager instance].hasValidLocation) {
            [buttonTrackUser setEnabled:NO];
        }
        [self.mpView setCenterCoordinate:center];
    } else {
        [self.mpView setCenterCoordinate:center];
    }

    [self.mpView setUserTrackingMode:RMUserTrackingModeFollowWithHeading];
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
    return self.route.turnInstructions.count - 1; // remove -1 if you want to see "Finished instruction"
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int i = [indexPath row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(i == 0 ? @"topDirectionCell" : @"directionCell")];

    if (i >= 0 && i < self.route.turnInstructions.count) {
        SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
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
    [self trackUser:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    int i = [indexPath row];
    if (i < 0 || i >= self.route.turnInstructions.count)
        return;
    SMTurnInstruction *selectedTurn = [self.route.turnInstructions objectAtIndex:i];

    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];

//    [self.mpView setCenterCoordinate:selectedTurn.loc.coordinate];
//    [self.mpView zoomInToNextNativeZoomAt:[self.mpView coordinateToPixel:selectedTurn.loc.coordinate] animated:YES];
    [self.mpView setZoom:DEFAULT_TURN_ZOOM];
    [self.mpView zoomByFactor:1 near:[self.mpView coordinateToPixel:selectedTurn.loc.coordinate] animated:YES];
    [self.mpView setCenterCoordinate:selectedTurn.loc.coordinate];

    [buttonTrackUser setEnabled:YES];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetZoomTurn) object:nil];
    [self performSelector:@selector(resetZoomTurn) withObject:nil afterDelay:ZOOM_TO_TURN_DURATION];
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self performSegueWithIdentifier:@"reportError" sender:nil];
            break;
        case 1: {
            currentlyRouting = NO;
            [UIApplication sharedApplication].idleTimerDisabled = NO;
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

    if (segments == 0) {
        [instructionsView setHidden:YES];
        if (self.route && self.route.turnInstructions && ((self.route.turnInstructions.count - 1) > 0)) { // remove -1 if you want to see "Finished instruction"
            [minimizedInstructionsView setHidden:NO];
        } else {
            [minimizedInstructionsView setHidden:YES];
        }
        [self repositionInstructionsView:self.view.frame.size.height];
    } else {
        [instructionsView setHidden:NO];
        [minimizedInstructionsView setHidden:YES];
        int maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
//        int topCellHeight = [SMDirectionTopCell getHeight];
//        int cellHeight = [SMDirectionCell getHeight];
//        int newY = maxY - topCellHeight - (segments - 1) * cellHeight;
//        if (newY < self.mpView.frame.origin.y || segments > 3)
//            newY = self.mpView.frame.origin.y;

        /**
         * dynamic cell resizing
         */
        CGFloat tblHeight = 0.0f;
        @synchronized(self.route.turnInstructions) {
            for (int i = 0; i < segments; i++) {
                SMTurnInstruction *turn = (SMTurnInstruction *)[self.route.turnInstructions objectAtIndex:i];
                if (i == 0) {
                    tblHeight += [SMDirectionTopCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                } else {
                    tblHeight += [SMDirectionCell getHeightForDescription:[turn descriptionString] andWayname:turn.wayName];
                }
            }
        }
        int newY = maxY - tblHeight;
        if (newY < self.mpView.frame.origin.y || segments > 3) {
            newY = self.mpView.frame.origin.y;
        }
        
        [self repositionInstructionsView:newY + 1];
    }

    if (segments > 3) {
        CGRect frame = tblDirections.frame;
        frame.size.height = instructionsView.frame.size.height - tblDirections.frame.origin.y;
        [tblDirections setFrame:frame];
        [tblDirections setScrollEnabled:YES];
    } else {
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

    if (newY < progressView.frame.origin.y + progressView.frame.size.height)
        [progressView setHidden:YES];
    else
        [progressView setHidden:NO];
}

- (IBAction)onPanGestureDirections:(UIPanGestureRecognizer *)sender {
    
    [tblDirections scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [instructionsView setHidden:NO];
    [minimizedInstructionsView setHidden:YES];
    if (sender.state == UIGestureRecognizerStateEnded) {
//        float topCellHeight = [SMDirectionTopCell getHeight];
//        float cellHeight = [SMDirectionCell getHeight];
        float maxY = self.view.frame.size.height - tblDirections.frame.origin.y;
        float cellCount = self.route.turnInstructions.count - 1; // remove -1 if you want to see "Finished instruction"
        float newY = [sender locationInView:self.view].y;

        if ((cellCount <= 3) && (cellCount >=0)) {
            [self showDirections:cellCount];
            return;
        }

        
        /**
         * dynamic row height repositioning
         */
        CGFloat tblHeight = 0.0f;
        CGFloat height = 0.0f;
        @synchronized(self.route.turnInstructions) {
            for (int i = 0; i < MAX(4, cellCount); i++) {
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
    }
}



@end
