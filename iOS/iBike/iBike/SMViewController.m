	//
//  SMViewController.m
//  iBike
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMViewController.h"

#import "SMContactsCell.h"
#import "SMContactsHeader.h"

#import "SMLocationManager.h"
#import "SMEventsCalendarCell.h"
#import "SMEventsFacebookCell.h"
#import "SMEventsHeader.h"

#import "RMMapView.h"
#import "RMAnnotation.h"
#import "RMMarker.h"
#import "RMShape.h"

#import "SMiBikeCPHMapTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "SMRouteNavigationController.h"
#import "SMAppDelegate.h"
#import "SMAnnotation.h"
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>

@interface SMViewController ()

@property (nonatomic, strong) SMContacts *contacts;
@property (nonatomic, strong) RMMapView *mpView;

/**
 * data sources for tables
 */
@property (nonatomic, strong) NSArray * menuArr;
@property (nonatomic, strong) NSMutableArray * favorites;
@property (nonatomic, strong) NSArray * eventsGroupedArray;
@property (nonatomic, strong) SMEvents * events;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;

@property (nonatomic, strong) NSString * findFrom;
@property (nonatomic, strong) NSString * findTo;
@property (nonatomic, strong) NSArray * findMatches;
@property (nonatomic, strong) SMAnnotation * destinationPin;
@end

@implementation SMViewController

typedef enum {
    menuLink,
    menuGear,
    menuInfo
} MenuType;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [RMMapView class];
    
    [SMLocationManager instance];
    
    
    /**
     * start with empty contacts and favorites array
     */
    self.contactsArr = @[];
    self.favorites = [@[] mutableCopy];

    /**
     * removed for alpha
     */
    [self performSelector:@selector(getPhoneContacts) withObject:nil afterDelay:0.001f];
    /**
     * end alpha remove
     */

    /**
     * menu table array
     */
    
    self.menuArr = @[
                     @{@"text" : translateString(@"accounts"), @"image" : @"menuLink", @"type" : [NSNumber numberWithInteger:menuLink], @"segue" : @"openAccounts"},
    @{@"text" : translateString(@"settings"), @"image" : @"menuGear", @"type" : [NSNumber numberWithInteger:menuGear], @"segue" : @"openSettings"},
    @{@"text" : translateString(@"about_ibikecph"), @"image" : @"menuInfo", @"type" : [NSNumber numberWithInteger:menuInfo], @"segue" : @"openAbout"}
    ];
    
    self.eventsArr = @[];
    self.eventsGroupedArray = @[];
    
    currentScreen = screenMap;
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    
    NSLog(@"%@", OSRM_SERVER);
    
    UILongPressGestureRecognizer * lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dropPin:)];
    [lp setDelegate:self];
    [lp setCancelsTouchesInView:YES];
    [self.mpView addGestureRecognizer:lp];
}

- (void)viewDidUnload {
    self.mpView = nil;
    scrlView = nil;
    menuView = nil;
    addressView = nil;
    centerView = nil;
    tblEvents = nil;
    tblContacts = nil;
    eventsView = nil;
    tblMenu = nil;
    fadeView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    [self.mpView setZoom:16];
    [self.mpView zoomByFactor:1 near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:NO];
    [self readjustViewsForRotation:self.interfaceOrientation];
    
    self.findFrom = @"";
    self.findTo = @"";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"settings.plist"]] == NO) {
        [self performSegueWithIdentifier:@"enterEmail" sender:nil];
    } 


    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"]]) {
        NSMutableArray * rts = [NSMutableArray array];
        NSArray * arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"] error:nil];
        NSLog(@"%@", arr);
        for (NSString * file in arr) {
            NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile:[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"] stringByAppendingPathComponent:file]];
            if (d) {
                NSString * from = [[[d objectForKey:@"fromName"] componentsSeparatedByString:@","] objectAtIndex:0];
                NSString * to = [[[d objectForKey:@"toName"] componentsSeparatedByString:@","] objectAtIndex:0];
                [rts addObject:@{
                 @"name" : [NSString stringWithFormat:@"%@ - %@", from, to],
                 @"address" : [d objectForKey:@"toName"],
                 @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                 @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                 @"source" : @"pastRoutes"
                 }];
                [rts addObject:@{
                 @"name" : [NSString stringWithFormat:@"%@ - %@", to, from],
                 @"address" : [d objectForKey:@"fromName"],
                 @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                 @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                 @"source" : @"pastRoutes"
                 }];
            }
        }
        SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
        [appd setPastRoutes:rts];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /**
     * removed for alpha. remove comment later
     */
//    if ([self.eventsArr count] == 0) {
//        self.events = [[SMEvents alloc] init];
//        [self.events setDelegate:self];
//        [self.events getLocalEvents];
//        [self.events getFacebookEvents];
//    }
    /**
     * end comment alpha
     */
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]]) {
        NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]];
        [self findRouteFrom:CLLocationCoordinate2DMake([[d objectForKey:@"startLat"] doubleValue], [[d objectForKey:@"startLong"] doubleValue]) to:CLLocationCoordinate2DMake([[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]) fromAddress:@"" toAddress:[d objectForKey:@"destination"]];
    }
    
}

#pragma mark - custom methods

- (void)dropPin:(UILongPressGestureRecognizer*) gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        for (SMAnnotation * annotation in self.mpView.annotations) {
            if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
                if (annotation.calloutShown) {
                    [annotation hideCallout];
                }
            }
        }
        
        
        CGPoint point = [gesture locationInView:self.mpView];
        CLLocationCoordinate2D coord = [self.mpView pixelToCoordinate:point];
        CLLocation * loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];

        UIImageView * im = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 17.0f, 0.0f, 34.0f, 34.0f)];
        [im setImage:[UIImage imageNamed:@"markerFinish"]];
        [self.mpView addSubview:im];
        
        [UIView animateWithDuration:0.2f animations:^{
            [im setFrame:CGRectMake(point.x - 17.0f, point.y - 34.0f, 34.0f, 34.0f)];
        } completion:^(BOOL finished) {
            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
            [r setRequestIdentifier:@"getNearestForPinDrop"];
            [r findNearestPointForLocation:loc];
            
            [self.mpView removeAllAnnotations];
            SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:@""];
            endMarkerAnnotation.annotationType = @"marker";
            endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
            endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
            [self.mpView addAnnotation:endMarkerAnnotation];
            [self setDestinationPin:endMarkerAnnotation];
            
            [im removeFromSuperview];
        }];
        
        
        
//    SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
//    [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude]];
    }
    
    
}

- (void)readjustViewsForRotation:(UIInterfaceOrientation) orientation {
    CGFloat scrWidth;
    CGFloat scrHeight;
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        scrWidth = self.view.frame.size.width;
        scrHeight = self.view.frame.size.height;
    } else {
        scrWidth = self.view.frame.size.height;
        scrHeight = self.view.frame.size.width;
    }
    
    /**
     * alpha. no side menus
     */
    CGRect frame = centerView.frame;
    frame.size.width = scrWidth;
    frame.size.height = scrHeight;
    frame.origin.x = 0.0f;
    [centerView setFrame:frame];
    [scrlView setContentSize:CGSizeMake(scrWidth, scrHeight)];
    
    [menuView setHidden:YES];
    [addressView setHidden:YES];
    /**
     * end alpha
     */
    
    /**
     * removed for alpha. uncomment when needed
     */
//    CGRect frame = menuView.frame;
//    frame.size.width = scrWidth - 60.0f;
//    frame.size.height = scrHeight;
//    frame.origin.x = 0.0f;
//    [menuView setFrame:frame];
//    
//    frame = centerView.frame;
//    frame.size.width = scrWidth;
//    frame.size.height = scrHeight;
//    frame.origin.x = scrWidth - 60.0f;
//    [centerView setFrame:frame];
//    
//    
//    frame = addressView.frame;
//    frame.size.width = scrWidth - 60.0f;
//    frame.size.height = scrHeight;
//    frame.origin.x = scrWidth * 2.0f - 60.0f;
//    [addressView setFrame:frame];
//    
//    [scrlView setContentSize:CGSizeMake(scrWidth * 3.0f - 120.0f, scrHeight)];
//    
//    
//    if (currentScreen == screenMenu) {
//        [scrlView setContentOffset:CGPointMake(0.0f, 0.0f) animated:NO];
//    } else if (currentScreen == screenMap) {
//        [scrlView setContentOffset:CGPointMake(scrWidth - 60.0f, 0.0f) animated:NO];
//    } else {
//        [scrlView setContentOffset:CGPointMake(scrWidth * 2.0f - 120.0f, 0.0f) animated:NO];
//    }
//    
//    if ([self.eventsGroupedArray count] > 0) {
//        [self drawEventsTable];        
//    }
    /**
     * end remove alpha
     */
}

#pragma mark - rotation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self readjustViewsForRotation:toInterfaceOrientation];
}

#pragma mark - scrollView delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != scrlView) {
        return;
    }
    [scrollView setContentOffset:scrollView.contentOffset animated:NO];
    if (scrollView.contentOffset.x < (self.view.frame.size.width - 60.0f) / 2.0f) {
        [scrollView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
        currentScreen = screenMenu;
    } else if (scrollView.contentOffset.x > (self.view.frame.size.width * 1.5f - 60.0f)) {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width * 2.0f - 120.0f, 0.0f) animated:YES];
        currentScreen = screenContacts;
    } else {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != scrlView) {
        return;
    }
    if (scrollView.contentOffset.x < (self.view.frame.size.width - 60.0f) / 2.0f) {
        [scrollView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
        currentScreen = screenMenu;
    } else if (scrollView.contentOffset.x > (self.view.frame.size.width * 1.5f - 60.0f)) {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width * 2.0f - 120.0f, 0.0f) animated:YES];
        currentScreen = screenContacts;
    } else {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
    }
}

#pragma mark - button actions

- (void)trackingOn {
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    
}

- (IBAction)trackUser:(id)sender {
    if ([SMLocationManager instance].hasValidLocation) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
        [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
        [self.mpView setCenterCoordinate:[SMLocationManager instance].lastValidLocation.coordinate];
        [buttonTrackUser setEnabled:NO];
    } else {
        [buttonTrackUser setEnabled:NO];
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    }
}

- (IBAction)showMenu:(id)sender {
    if (currentScreen == screenMenu) {
        [scrlView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
    } else {
        [scrlView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
        currentScreen = screenMenu;
    }
}

- (IBAction)showContacts:(id)sender {
    if (currentScreen == screenContacts) {
        [scrlView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
    } else {
        [scrlView setContentOffset:CGPointMake(self.view.frame.size.width * 2.0f - 120.0f, 0.0f) animated:YES];
        currentScreen = screenContacts;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"goToFinderSegue"]){
        SMFindAddressController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setLocationFrom:self.findFrom];
        [destViewController setLocationTo:self.findTo];
        [destViewController loadMatches:self.findMatches];
    } else if ([segue.identifier isEqualToString:@"goToNavigationView"]) {
        NSDictionary * params = (NSDictionary*)sender;
        SMRouteNavigationController *destViewController = segue.destinationViewController;
        [destViewController setStartLocation:[params objectForKey:@"start"]];
        [destViewController setEndLocation:[params objectForKey:@"end"]];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
        
        NSDictionary * d = @{
                             @"endLat": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"end"]).coordinate.latitude],
                             @"endLong": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"end"]).coordinate.longitude],
                             @"startLat": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"start"]).coordinate.latitude],
                             @"startLong": [NSNumber numberWithDouble:((CLLocation*)[params objectForKey:@"start"]).coordinate.longitude],
                             @"destination": self.destination,
                             };
        
        NSString * s = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"];
        BOOL x = [d writeToFile:s atomically:NO];
        if (x == NO) {
            NSLog(@"Temp route not saved!");
        }
//        [destViewController setDelegate:self];
    }
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == tblContacts) {
        return 2;
    } else if (tableView == tblEvents) {
        return [self.eventsGroupedArray count];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == tblContacts) {
        if (section == 0) {
            return [self.favorites count];
        } else {
            return [self.contactsArr count];            
        }
    } else if (tableView == tblMenu) {
        return  [self.menuArr count];
    } else {
        return [[[self.eventsGroupedArray objectAtIndex:section] objectForKey:@"items"] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == tblContacts) {
        NSDictionary * currentRow;
        
        if (indexPath.section == 0) {
            currentRow = [self.favorites objectAtIndex:indexPath.row];
        } else {
            currentRow = [self.contactsArr objectAtIndex:indexPath.row];
        }
        
        NSString * identifier = @"contactsCell";
        SMContactsCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//        if (cell == nil) {
//            cell = [SMContactsCell getCell];
//        }
        
        [cell.contactImage setContentMode:UIViewContentModeScaleAspectFill];
        [cell.contactImage setImage:[currentRow objectForKey:@"image"]];
        [cell.contactName setText:[currentRow objectForKey:@"name"]];
        
        if (tblContacts.editing) {
            [cell.contactDisclosure setHidden:YES];
        } else {
            [cell.contactDisclosure setHidden:NO];
        }
        return cell;
    } else if (tableView == tblMenu) {
        NSDictionary * currentRow = [self.menuArr objectAtIndex:indexPath.row];
                
        NSString * identifier = @"menuCell";
        SMContactsCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//        if (cell == nil) {
//            cell = [SMContactsCell getCell];
//        }
        [cell.contactImage setContentMode:UIViewContentModeCenter];
        [cell.contactImage setImage:[UIImage imageNamed:[currentRow objectForKey:@"image"]]];
        [cell.contactName setText:[currentRow objectForKey:@"text"]];        
        return cell;
    } else if (tableView == tblEvents) {
        NSDictionary * currentRow = [[[self.eventsGroupedArray objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
        if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
            NSString * identifier = @"eventsCalendarCell";
            SMEventsCalendarCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//            if (cell == nil) {
//                cell = [SMEventsCalendarCell getCell];
//            }
            
            if ((indexPath.row % 2) == 0) {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowEvenBG"]];
            } else {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowOddBG"]];
            }
            
            NSDateFormatter * df = [[NSDateFormatter alloc] init];
            [df setDateFormat:TIME_FORMAT];
            [cell.timeLabel setText:[NSString stringWithFormat:@"%@ - %@", [df stringFromDate:[currentRow objectForKey:@"startDate"]], [df stringFromDate:[currentRow objectForKey:@"endDate"]]]];
            [cell.nameLabel setText:[[currentRow objectForKey:@"name"] uppercaseString]];
            [cell.addressLabel setText:[currentRow objectForKey:@"address"]];

            [df setDateFormat:@"dd"];
            [cell.dayLabel setText:[df stringFromDate:[currentRow objectForKey:@"startDate"]]];
            [df setDateFormat:@"MMM"];
            [cell.monthLabel setText:[[df stringFromDate:[currentRow objectForKey:@"startDate"]] uppercaseString]];

            return cell;
        } else {
            NSString * identifier = @"eventsFacebookCell";
            SMEventsFacebookCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//            if (cell == nil) {
//                cell = [SMEventsFacebookCell getCell];
//            }
            if ((indexPath.row % 2) == 0) {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowEvenBG"]];
            } else {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowOddBG"]];
            }

            [cell.eventImg loadImage:[currentRow objectForKey:@"picture"]];
            NSDateFormatter * df = [[NSDateFormatter alloc] init];
            [df setDateFormat:TIME_FORMAT];
            [cell.timeLabel setText:[NSString stringWithFormat:@"%@ - %@", [df stringFromDate:[currentRow objectForKey:@"startDate"]], [df stringFromDate:[currentRow objectForKey:@"endDate"]]]];
            [cell.nameLabel setText:[[currentRow objectForKey:@"name"] uppercaseString]];
            [cell.addressLabel setText:[currentRow objectForKey:@"address"]];
            
            return cell;
        }
    }
    UITableViewCell * cell;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == tblEvents) {
        if ([SMLocationManager instance].hasValidLocation) {
            NSDictionary * currentRow = [[[self.eventsGroupedArray objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
            [SMGeocoder geocode:[currentRow objectForKey:@"address"] completionHandler:^(NSArray *placemarks, NSError *error) {
                MKPlacemark *coord = [placemarks objectAtIndex:0];
                if (coord == nil) {
                    UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                    [av show];
                    return;
                }
                
                CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude];
                CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                [r setRequestIdentifier:@"rowSelectRoute"];
                [r setAuxParam:[currentRow objectForKey:@"address"]];
                [r findNearestPointForStart:cStart andEnd:cEnd];
                
//                CLLocationCoordinate2D cTo = [SMLocationManager getNearest: CLLocationCoordinate2DMake(coord.region.center.latitude, coord.region.center.longitude)];
//                CLLocationCoordinate2D cFrom = [SMLocationManager getNearest: CLLocationCoordinate2DMake([SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude)];
//                [self findRouteFrom:cFrom to:cTo fromAddress:[NSString stringWithFormat:@"(%f,%f)", cFrom.latitude, cFrom.longitude] toAddress:[currentRow objectForKey:@"address"]];
            }];
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];            
        }
    } else if (tableView == tblContacts) {
        if ([SMLocationManager instance].hasValidLocation) {
            NSDictionary * currentRow = [self.contactsArr objectAtIndex:indexPath.row];
            [SMGeocoder geocode:[currentRow objectForKey:@"address"] completionHandler:^(NSArray *placemarks, NSError *error) {
                MKPlacemark *coord = [placemarks objectAtIndex:0];
                if (coord == nil) {
                    UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                    [av show];
                    return;
                }
                CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude];
                CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                [r setRequestIdentifier:@"rowSelectRoute"];
                [r setAuxParam:[currentRow objectForKey:@"address"]];
                [r findNearestPointForStart:cStart andEnd:cEnd];
                
//                CLLocationCoordinate2D cTo = [SMLocationManager getNearest: CLLocationCoordinate2DMake(coord.region.center.latitude, coord.region.center.longitude)];
//                CLLocationCoordinate2D cFrom = [SMLocationManager getNearest: CLLocationCoordinate2DMake([SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude)];
//                [self findRouteFrom:cFrom to:cTo  fromAddress:[NSString stringWithFormat:@"(%f,%f)", cFrom.latitude, cFrom.longitude] toAddress:[currentRow objectForKey:@"address"]];
            }];
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];            
        }
    } else if (tableView == tblMenu) {
        [self performSegueWithIdentifier:[[self.menuArr objectAtIndex:indexPath.row] objectForKey:@"segue"] sender:nil];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == tblContacts) {
//        SMContactsHeader * v = [SMContactsHeader getView];
        SMContactsHeader * v = [tableView dequeueReusableCellWithIdentifier:@"contactsHeader"];
        if (section == 0) {
            [v.headerImage setImage:[UIImage imageNamed:@"contactsFavorites"]];
            [v.headerText setText:translateString(@"favorites")];
            [v.headerButton setHidden:NO];
            [v setDelegate:self];
        } else {
            [v.headerImage setImage:[UIImage imageNamed:@"contactsList"]];
            [v.headerText setText:translateString(@"contacts")];
            [v.headerButton setHidden:YES];
            [v setDelegate:nil];
        }
        return v;
    } else if (tableView == tblEvents) {
//        SMEventsHeader * v = [SMEventsHeader getView];
        SMEventsHeader * v = [tableView dequeueReusableCellWithIdentifier:@"eventsHeader"];
        [v setupHeaderWithData:[self.eventsGroupedArray objectAtIndex:section]];
        return v;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == tblContacts) {
        return [SMContactsHeader getHeight];
    } else if (tableView == tblEvents) {
        return [SMEventsHeader getHeight];
    }
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((tableView == tblContacts) || (tableView == tblMenu)) {
        return [SMContactsHeader getHeight];
    } else if (tableView == tblEvents) {
        return [SMEventsCalendarCell getHeight];
    }
    return 45.0f;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ((sourceIndexPath.section == 0) && (destinationIndexPath.section == 0)) {
        NSDictionary * dst = [self.favorites objectAtIndex:destinationIndexPath.row];
        NSDictionary * src = [self.favorites objectAtIndex:sourceIndexPath.row];
        [self.favorites removeObjectAtIndex:destinationIndexPath.row];
        [self.favorites insertObject:src atIndex:destinationIndexPath.row];
        [self.favorites removeObjectAtIndex:sourceIndexPath.row];
        [self.favorites insertObject:dst atIndex:sourceIndexPath.row];
        /**
         * reordering favorites
         */
        NSLog(@"Reorder");
    } else if ((sourceIndexPath.section == 0) && (destinationIndexPath.section != 0)) {
        /**
         * remove from favorites
         */
        NSLog(@"Remove from favorites");
        [self.favorites removeObjectAtIndex:sourceIndexPath.row];
    } else if ((sourceIndexPath.section != 0) && (destinationIndexPath.section == 0)) {
        /**
         * add to favorites
         */
        NSLog(@"Add to favorites");
        [self.favorites insertObject:[self.contactsArr objectAtIndex:sourceIndexPath.row] atIndex:destinationIndexPath.row];
    }

    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - addressbook functions

- (void)getPhoneContacts {
    self.contacts = [[SMContacts alloc] initWithDelegate:self];
    [self.contacts loadContacts];
}

#pragma mark - contacts delegate

- (void)addressBookHelper:(SMContacts *)helper finishedLoading:(NSArray *)contacts {
    self.contactsArr = contacts;
    [tblContacts reloadData];
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appd setCurrentContacts:[NSArray arrayWithArray:self.contactsArr]];
}

- (void)addressBookHelperDeniedAcess:(SMContacts *)obj {
    
}

- (void)addressBookHelperError:(SMContacts *)obj {
    
}

#pragma mark - contacts header delegate

- (void)buttonPressed:(id)btn {
    if (tblContacts.editing) {
        [tblContacts setEditing:NO];
    } else {
        [tblContacts setEditing:YES];
    }
    [tblContacts reloadData];
}

#pragma mark - route finder delegate

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    CLLocation * start = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * end = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];    
    self.destination = dst;
    self.source = src;
    [self performSegueWithIdentifier:@"goToNavigationView" sender:@{@"start" : start, @"end" : end}];
}

#pragma mark - events delegate

-(void)drawEventsTable {
    CGFloat scrWidth;
    CGFloat scrHeight;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        scrWidth = self.view.frame.size.width;
        scrHeight = self.view.frame.size.height;
    } else {
        scrWidth = self.view.frame.size.height;
        scrHeight = self.view.frame.size.width;
    }
    
    CGFloat height = tblEvents.contentSize.height;    
    if (height > MAX_HEIGHT_FOR_EVENTS_TABLE) {
        height = MAX_HEIGHT_FOR_EVENTS_TABLE;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = eventsView.frame;
        frame.size.height = height;
        frame.origin.y = scrHeight - height;
        [eventsView setFrame:frame];
        frame = tblEvents.frame;
        frame.size.height = height;
        [tblEvents setFrame:frame];        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = self.mpView.frame;
            frame.size.height = scrHeight - 49.0f - height;
            [self.mpView setFrame:frame];
        }];
    }];
    
}

- (void)appendEvents:(NSArray*)evnts {
    NSMutableArray * arr = [NSMutableArray arrayWithArray:self.eventsArr];
    arr = [[arr arrayByAddingObjectsFromArray:evnts] mutableCopy];
    [arr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
        NSDate * d1 = [obj1 objectForKey:@"startDate"];
        NSDate * d2 = [obj2 objectForKey:@"startDate"];
        return [d1 compare:d2];
    }];
    self.eventsArr = arr;
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    [appd setCurrentEvents:[NSArray arrayWithArray:self.eventsArr]];

    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    NSMutableArray * groupedArr = [NSMutableArray array];
    [df setDateFormat:@"eeee d. MMM."];

    NSCalendar * cal = [NSCalendar currentCalendar];
    for (NSDictionary * d in arr) {
        NSString * dstr = [df stringFromDate:[d objectForKey:@"startDate"]];

        NSDateComponents * comp = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[d objectForKey:@"startDate"]];
        comp.hour = 0;
        comp.minute = 0;
        comp.second = 0;
        NSDate * dayDate = [cal dateFromComponents:comp];
        NSMutableDictionary * m = nil;
        for (NSMutableDictionary * gd in groupedArr) {
            if ([[gd objectForKey:@"text"] isEqualToString:dstr]) {
                m = gd;
                break;
            }
        }
        if (m == nil) {
            m = [NSMutableDictionary dictionaryWithObjectsAndKeys:dstr, @"text", [NSMutableArray array], @"items", dayDate, @"dayDate", nil];
            [groupedArr addObject:m];
        }
        [[m objectForKey:@"items"] addObject:d];
    }
    debugLog(@"%@", groupedArr);
    [self setEventsGroupedArray:groupedArr];
    
    [tblEvents reloadData];
}

- (void)localEventsFound:(NSArray *)evnts {
    @synchronized(self.eventsArr) {
        [self appendEvents:evnts];
        [self drawEventsTable];        
    }
}

- (void)facebookEventsFound:(NSArray *)evnts {
    @synchronized(self.eventsArr) {
        [self appendEvents:evnts];
        [self drawEventsTable];
    }
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - mapView delegate

- (void)afterMapMove:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        [buttonTrackUser setEnabled:YES];
    }
    [self checkCallouts];
}

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

- (RMMapLayer *)mapView:(RMMapView *)aMapView layerForAnnotation:(SMAnnotation *)annotation {
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        RMMarker * m = [[RMMarker alloc] initWithUIImage:annotation.annotationIcon anchorPoint:annotation.anchorPoint];
        return m;
    }
    return nil;
}

- (void)afterMapZoom:(RMMapView *)map byUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        [buttonTrackUser setEnabled:YES];
    }
    [self checkCallouts];
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
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

#pragma mark - SMAnnotation delegate methods

- (void)annotationActivated:(SMAnnotation *)annotation {
    self.findFrom = @"";
    self.findTo = annotation.title;
    self.findMatches = annotation.nearbyObjects;
    
#ifdef START_DIRECTIONS
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:annotation.routingCoordinate.coordinate.latitude longitude:annotation.routingCoordinate.coordinate.longitude];
    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setRequestIdentifier:@"rowSelectRoute"];
    [r setAuxParam:@"TEST"];
    [r findNearestPointForStart:cStart andEnd:cEnd];
#else
    [self performSegueWithIdentifier:@"goToFinderSegue" sender:nil];
#endif

    for (SMAnnotation * annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation hideCallout];
            }
        }
    }
    

}


#pragma mark - nearby places delegate

- (void) nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
    [self.destinationPin setNearbyObjects:locations];
    [self.destinationPin setSubtitle:owner.subtitle];
    [self.destinationPin setTitle:owner.title];
    [self.destinationPin setDelegate:self];
    [self.destinationPin setRoutingCoordinate:owner.coord];
    
//    [self.mpView removeAllAnnotations];
//    SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:owner.coord.coordinate andTitle:owner.title];
//    [endMarkerAnnotation setNearbyObjects:locations];
//    [endMarkerAnnotation setSubtitle:owner.subtitle];
//    [endMarkerAnnotation setDelegate:self];
//    endMarkerAnnotation.annotationType = @"marker";
//    endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
//    endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
//    [self.mpView addAnnotation:endMarkerAnnotation];
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.requestIdentifier isEqualToString:@"getNearestForPinDrop"]) {
        NSDictionary * r = res;
        CLLocation * coord;
        if ([r objectForKey:@"mapped_coordinate"] && [[r objectForKey:@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([[r objectForKey:@"mapped_coordinate"] count] > 1)) {
            coord = [[CLLocation alloc] initWithLatitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:0] doubleValue] longitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:1] doubleValue]];
        } else {
            coord = req.coord;
        }
        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]];
    } else if ([req.requestIdentifier isEqualToString:@"rowSelectRoute"]) {
        CLLocation * s = [res objectForKey:@"start"];
        CLLocation * e = [res objectForKey:@"end"];
        [self findRouteFrom:s.coordinate to:e.coordinate  fromAddress:[NSString stringWithFormat:@"(%f,%f)", s.coordinate.latitude, s.coordinate.longitude] toAddress:(NSString*)req.auxParam];
        [UIView animateWithDuration:0.4f animations:^{
            [fadeView setAlpha:0.0f];
        }];

    }
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

@end


