//
//  SMViewController.h
//  iBike
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMContacts.h"
#import "SMContactsHeader.h"
#import "SMFindAddressController.h"
#import "SMEvents.h"

#import "SMMapView.h"
#import "SMAnnotation.h"
#import "SMNearbyPlaces.h"
#import "SMRequestOSRM.h"

typedef enum {
    screenMenu,
    screenMap,
    screenContacts
} CurrentScreenType;

@interface SMViewController : UIViewController <RMMapViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, SMContactsDelegate, SMContactsHeaderDelegate, RouteFinderDelegate, SMEventsDelegate, UIGestureRecognizerDelegate, SMAnnotationActionDelegate, SMNearbyPlacesDelegate, SMRequestOSRMDelegate>  {
    __weak IBOutlet UIScrollView *scrlView;
    IBOutlet UIView *menuView;
    IBOutlet UIView *addressView;
    __weak IBOutlet UIView *centerView;
    __weak IBOutlet UIView *eventsView;
    
    CurrentScreenType currentScreen;
    
    __weak IBOutlet UITableView *tblEvents;
    __weak IBOutlet UITableView *tblContacts;
    __weak IBOutlet UITableView *tblMenu;
    __weak IBOutlet UIButton *buttonTrackUser;
    __weak IBOutlet UIView *fadeView;
}

/**
 * properties for table
 */
@property (nonatomic, strong) NSArray * contactsArr;
@property (nonatomic, strong) NSArray * eventsArr;


@end
