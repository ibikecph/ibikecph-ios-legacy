	//
//  SMViewController.m
//  I Bike CPH
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

#import "SMEnterRouteController.h"
#import "SMUtil.h"
#import "SMAddFavoriteCell.h"
#import "SMEmptyFavoritesCell.h"

#import "DAKeyboardControl.h"

typedef enum {
    menuFavorites = 0,
    menuAccount = 1,
    menuInfo = 2
} MenuType;

typedef enum {
    typeFavorite,
    typeHome,
    typeWork,
    typeSchool,
    typeNone
} FavoriteType;

@interface SMViewController () {
    MenuType menuOpen;
    
    FavoriteType currentFav;
}

@property (nonatomic, strong) SMContacts *contacts;
@property (nonatomic, strong) RMMapView *mpView;

/**
 * data sources for tables
 */
@property (nonatomic, strong) NSMutableArray * favoritesList;
@property (nonatomic, strong) NSMutableArray * favorites;
@property (nonatomic, strong) NSArray * eventsGroupedArray;
@property (nonatomic, strong) SMEvents * events;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) NSString * source;

@property (nonatomic, strong) NSString * findFrom;
@property (nonatomic, strong) NSString * findTo;
@property (nonatomic, strong) NSArray * findMatches;
@property (nonatomic, strong) SMAnnotation * destinationPin;

@property (nonatomic, strong) id jsonRoot;



@property CLLocationCoordinate2D startLoc;
@property CLLocationCoordinate2D endLoc;
@property (nonatomic, strong) NSString * startName;
@property (nonatomic, strong) NSString * endName;

@property (nonatomic, strong) NSDictionary * locDict;
@property (nonatomic, strong) NSString * favName;

@end

@implementation SMViewController




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - view lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    
    [RMMapView class];
    
    menuOpen = menuFavorites;
    
    [SMLocationManager instance];
    
    
    /**
     * start with empty contacts and favorites array
     */
    self.contactsArr = @[];
    self.favorites = [@[] mutableCopy];
    [self setFavoritesList:[SMUtil getFavorites]];

    /**
     * removed for alpha
     */
//    [self performSelector:@selector(getPhoneContacts) withObject:nil afterDelay:0.001f];
    /**
     * end alpha remove
     */

    /**
     * menu table array
     */
    
//    self.menuArr = @[
//                     @{@"text" : translateString(@"favorites"), @"image" : @"favListStar", @"type" : [NSNumber numberWithInteger:menuFavorites], @"segue" : @"openFavorites", @"items" : [SMUtil getFavorites]},
//                     @{@"text" : translateString(@"account"), @"image" : @"favListUser", @"type" : [NSNumber numberWithInteger:menuAccount], @"segue" : @"openAccount", @"items" : @[]},
//    @{@"text" : translateString(@"about_ibikecph"), @"image" : @"favListInfo", @"type" : [NSNumber numberWithInteger:menuInfo], @"segue" : @"openAbout", @"items" : @[]}
//    ];
    
    self.eventsArr = @[];
    self.eventsGroupedArray = @[];
    
    
    currentScreen = screenMap;
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    
    NSLog(@"%@", OSRM_SERVER);
    
    UILongPressGestureRecognizer * lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dropPin:)];
    [lp setDelegate:self];
    [lp setCancelsTouchesInView:YES];
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(55.675455,12.566643) animated:NO];
    [self.mpView addGestureRecognizer:lp];
    [self.mpView setZoom:16];
    [self.mpView zoomByFactor:1 near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:NO];
    [self.mpView setEnableBouncing:TRUE];
    
    [self openMenu:menuFavorites];
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
    debugLabel = nil;
    buttonTrackUser = nil;
    tblFavorites = nil;
    favHeader = nil;
    accHeader = nil;
    infHeader = nil;
    favEditStart = nil;
    favEditDone = nil;
    addFavFavoriteButton = nil;
    addFavHomeButton = nil;
    addFavWorkButton = nil;
    addFavSchoolButton = nil;
    addFavAddress = nil;
    addFavName = nil;
    mainMenu = nil;
    addMenu = nil;
    editTitle = nil;
    editSaveButton = nil;
    editDeleteButton = nil;
    addSaveButton = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self readjustViewsForRotation:self.interfaceOrientation];
    
    self.findFrom = @"";
    self.findTo = @"";
    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"settings.plist"]] == NO) {
//        [self performSegueWithIdentifier:@"enterEmail" sender:nil];
//    }
    [debugLabel setText:BUILD_STRING];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    @try{
        [self.mpView removeObserver:self forKeyPath:@"userTrackingMode" context:nil];

    }@catch(id anException){
        
    }
    
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
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
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)",CURRENT_POSITION_STRING, [[d objectForKey:@"startLat"] doubleValue], [[d objectForKey:@"startLong"] doubleValue], [d objectForKey:@"destination"], [[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Crash" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        [self findRouteFrom:CLLocationCoordinate2DMake([[d objectForKey:@"startLat"] doubleValue], [[d objectForKey:@"startLong"] doubleValue]) to:CLLocationCoordinate2DMake([[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]) fromAddress:@"" toAddress:[d objectForKey:@"destination"]];
        
        
        CLLocation * loc = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"endLat"] doubleValue] longitude:[[d objectForKey:@"endLong"] doubleValue]];
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setRequestIdentifier:@"getNearestForPinDrop"];
        [r findNearestPointForLocation:loc];
        
        [self.mpView removeAllAnnotations];
        SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:CLLocationCoordinate2DMake([[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]) andTitle:@""];
        endMarkerAnnotation.annotationType = @"marker";
        endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
        endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
        [self.mpView addAnnotation:endMarkerAnnotation];
        [self setDestinationPin:endMarkerAnnotation];
    } else {
        [self.mpView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
        [tblMenu addObserver:self forKeyPath:@"editing" options:0 context:nil];
    }
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];
    
}

#pragma mark - custom methods

- (CGFloat)heightForFavorites {
    if ([self.favoritesList count] == 0) {
        return [SMEmptyFavoritesCell getHeight] + 46.0f;
    } else {
        CGFloat startY = favHeader.frame.origin.y;
        CGFloat maxHeight = menuView.frame.size.height - startY;
        return MIN(tblMenu.contentSize.height + 46.0f, maxHeight - 2 * 45.0f);
    }
    return 45.0f;
}

- (void)openMenu:(NSInteger)menuType {
    
    CGFloat startY = favHeader.frame.origin.y;
    CGFloat maxHeight = menuView.frame.size.height - startY;
    [tblMenu reloadData];
    switch (menuType) {
        case menuInfo: {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
            CGRect frame = infHeader.frame;
            frame.origin.y = startY + 2 * 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [infHeader setFrame:frame];
            
            frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];
        }
            break;
        case menuAccount: {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:YES];
            CGRect frame = accHeader.frame;
            frame.origin.y = startY + 45.0f;
            frame.size.height = maxHeight - 2 * 45.0f;
            [accHeader setFrame:frame];
            
            frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = 45.0f;
            [favHeader setFrame:frame];
            
            frame = infHeader.frame;
            frame.origin.y = accHeader.frame.size.height + accHeader.frame.origin.y;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
        }
            break;
        case menuFavorites: {
            if ([self.favoritesList count] == 0) {
                [favEditDone setHidden:YES];
                [favEditStart setHidden:YES];
            } else {
                if (tblMenu.isEditing) {
                    [favEditDone setHidden:NO];
                    [favEditStart setHidden:YES];
                } else {
                    [favEditDone setHidden:YES];
                    [favEditStart setHidden:NO];
                }                
            }
            CGRect frame = favHeader.frame;
            frame.origin.y = startY;
            frame.size.height = [self heightForFavorites];
            [favHeader setFrame:frame];
            frame = accHeader.frame;
            frame.origin.y = startY + favHeader.frame.size.height;
            frame.size.height = 45.0f;
            [accHeader setFrame:frame];
            frame = infHeader.frame;
            frame.origin.y = accHeader.frame.origin.y + 45.0f;
            frame.size.height = 45.0f;
            [infHeader setFrame:frame];
        }
            break;
        default:
            break;
    }    
}

- (IBAction)tapFavorites:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [self openMenu:menuFavorites];
    }];
}


- (IBAction)tapAccount:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [self openMenu:menuAccount];
    }];
}

- (IBAction)tapInfo:(id)sender {
    [self performSegueWithIdentifier:@"openAbout" sender:nil];
}


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
            [self.mpView removeAllAnnotations];
            SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:@""];
            endMarkerAnnotation.annotationType = @"marker";
            endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
            endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
            [self.mpView addAnnotation:endMarkerAnnotation];
            [self setDestinationPin:endMarkerAnnotation];
            
            [im removeFromSuperview];

            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
            [r setRequestIdentifier:@"getNearestForPinDrop"];
            [r findNearestPointForLocation:loc];
            
        }];
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
    frame.origin.x = scrWidth - 60.0f;
    [centerView setFrame:frame];
    [scrlView setContentSize:CGSizeMake(scrWidth, scrHeight)];
    
//    [menuView setHidden:YES];
    [addressView setHidden:YES];
    /**
     * end alpha
     */
    
    /**
     * removed for alpha. uncomment when needed
     */
//    frame = menuView.frame;
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
    [scrlView setContentSize:CGSizeMake(scrWidth * 2.0f - 60.0f, scrHeight)];


    if (currentScreen == screenMenu) {
        [scrlView setContentOffset:CGPointMake(0.0f, 0.0f) animated:NO];
        [self.view sendSubviewToBack:scrlView];
        [self.view bringSubviewToFront:menuView];
    } else if (currentScreen == screenMap) {
        [scrlView setContentOffset:CGPointMake(scrWidth - 60.0f, 0.0f) animated:NO];
        [self.view sendSubviewToBack:menuView];
        [self.view bringSubviewToFront:scrlView];
    }
    
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView != scrlView) {
        return;
    }
    [self.view sendSubviewToBack:menuView];
    [self.view bringSubviewToFront:scrlView];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != scrlView) {
        return;
    }
    if (decelerate == NO) {
        if (scrollView.contentOffset.x < (self.view.frame.size.width - 60.0f) / 2.0f) {
            [scrollView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
            currentScreen = screenMenu;
        } else {
            [scrollView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
            currentScreen = screenMap;
        }        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != scrlView) {
        return;
    }
    if (scrollView.contentOffset.x < (self.view.frame.size.width - 60.0f) / 2.0f) {
        [scrollView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
        currentScreen = screenMenu;
        [self.view sendSubviewToBack:scrlView];
        [self.view bringSubviewToFront:menuView];

    } else {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
        [self.view sendSubviewToBack:menuView];
        [self.view bringSubviewToFront:scrlView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != scrlView) {
        return;
    }
    if (scrollView.contentOffset.x < (self.view.frame.size.width - 60.0f) / 2.0f) {
        [scrollView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
        currentScreen = screenMenu;
        [self.view sendSubviewToBack:scrlView];
        [self.view bringSubviewToFront:menuView];

    } else {
        [scrollView setContentOffset:CGPointMake(self.view.frame.size.width - 60.0f, 0.0f) animated:YES];
        currentScreen = screenMap;
        [self.view sendSubviewToBack:menuView];
        [self.view bringSubviewToFront:scrlView];

    }
}

#pragma mark - button actions

- (IBAction)editFavoriteShow:(id)sender {
    addFavAddress.text = [self.locDict objectForKey:@"address"];
    addFavName.text = [self.locDict objectForKey:@"name"];
    editTitle.text = translateString(@"edit_favorite");
    [addSaveButton setHidden:YES];
    [editSaveButton setHidden:NO];
    [editDeleteButton setHidden:NO];
    
    if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"home"]) {
        currentFav = typeHome;
        [self addSelectHome:nil];
    } else if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"work"]) {
        currentFav = typeWork;
        [self addSelectWork:nil];
    } else if ([[self.locDict objectForKey:@"subsource"] isEqualToString:@"school"]) {
        currentFav = typeSchool;
        [self addSelectSchool:nil];
    } else {
        currentFav = typeFavorite;
        [self addSelectFavorite:nil];
    }
    
    [self animateEditViewShow];


}

- (IBAction)addFavoriteShow:(id)sender {
    self.locDict = nil;
    addFavAddress.text = @"";
    addFavName.text = @"";
    currentFav = typeFavorite;
    [self addSelectFavorite:nil];
    editTitle.text = translateString(@"add_favorite");
    [addSaveButton setHidden:NO];
    [editSaveButton setHidden:YES];
    [editDeleteButton setHidden:YES];
    
    [self animateEditViewShow];
}

- (void)animateEditViewShow {
    CGRect frame = mainMenu.frame;
    frame.origin.x = 0.0f;
    [mainMenu setFrame:frame];
    
    frame.origin.x = 260.0f;
    [addMenu setFrame:frame];
    [addMenu setHidden:NO];
    
    [self.view sendSubviewToBack:menuView];
    [self.view bringSubviewToFront:scrlView];
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = -260.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 0.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
        [self.view sendSubviewToBack:scrlView];
        [self.view bringSubviewToFront:menuView];
    }];
    
}

- (IBAction)addFavoriteHide:(id)sender{
    [self.view sendSubviewToBack:menuView];
    [self.view bringSubviewToFront:scrlView];
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = 0.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 260.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
        [self.view sendSubviewToBack:scrlView];
        [self.view bringSubviewToFront:menuView];
        [mainMenu setHidden:NO];
        [addMenu setHidden:YES];
        [self setFavoritesList:[SMUtil getFavorites]];
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    }];
}

- (IBAction)saveFavorite:(id)sender {
    NSString * favType;
    switch (currentFav) {
        case typeFavorite:
            favType = @"favorite";
            break;
        case typeHome:
            favType = @"home";
            break;
        case typeWork:
            favType = @"work";
            break;
        case typeSchool:
            favType = @"school";
            break;
        default:
            favType = @"favorite";
            break;
    }
        
    if (self.locDict && [addFavName.text isEqualToString:@""] == NO) {
        [SMUtil saveToFavorites:@{
         @"name" : addFavName.text,
         @"address" : [self.locDict objectForKey:@"address"],
         @"startDate" : [NSDate date],
         @"endDate" : [NSDate date],
         @"source" : @"favorites",
         @"subsource" : favType,
         @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude],
         @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude],
         @"order" : @0
         }];        
    }
    
    [self addFavoriteHide:nil];
}

- (IBAction)deleteFavorite:(id)sender {
    [self.favoritesList removeObject:self.locDict];
    [SMUtil saveFavorites:self.favoritesList];
    [self addFavoriteHide:nil];
}

- (IBAction)editSaveFavorite:(id)sender {
    NSString * favType;
    switch (currentFav) {
        case typeFavorite:
            favType = @"favorite";
            break;
        case typeHome:
            favType = @"home";
            break;
        case typeWork:
            favType = @"work";
            break;
        case typeSchool:
            favType = @"school";
            break;
        default:
            favType = @"favorite";
            break;
    }
    
    NSDictionary * dict = @{
                        @"name" : addFavName.text,
                        @"address" : [self.locDict objectForKey:@"address"],
                        @"startDate" : [NSDate date],
                        @"endDate" : [NSDate date],
                        @"source" : @"favorites",
                        @"subsource" : favType,
                        @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude],
                        @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude],
                        @"order" : @0
                        };
    
    [self.favoritesList replaceObjectAtIndex:[self.favoritesList indexOfObject:self.locDict] withObject:dict];
    [SMUtil saveFavorites:self.favoritesList];
    [self addFavoriteHide:nil];
}


- (IBAction)findAddress:(id)sender {
    self.favName = addFavAddress.text;
    [self performSegueWithIdentifier:@"mainToSearch" sender:nil];
}

- (IBAction)addSelectFavorite:(id)sender {
    [addFavFavoriteButton setSelected:YES];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeFavorite;
}

- (IBAction)addSelectHome:(id)sender {
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:YES];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeHome;
}

- (IBAction)addSelectWork:(id)sender {
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:YES];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeWork;
}

- (IBAction)addSelectSchool:(id)sender {
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:YES];
    currentFav = typeSchool;
}




- (IBAction)startEdit:(id)sender {
    [tblMenu setEditing:YES];
    [tblMenu reloadData];
}

- (IBAction)stopEdit:(id)sender {
    [tblMenu setEditing:NO];
}

- (void)trackingOn {
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
}

- (IBAction)trackUser:(id)sender {
    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing)
        debugLog(@"Warning: trackUser button state was invalid: 0x%0x", buttonTrackUser.gpsTrackState);

    if ([SMLocationManager instance].hasValidLocation) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
        [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
        [self.mpView setCenterCoordinate:[SMLocationManager instance].lastValidLocation.coordinate];
    } else {
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
    if ([segue.identifier isEqualToString:@"enterRouteSegue"]) {
        SMEnterRouteController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"goToNavigationView"]) {
        NSDictionary * params = (NSDictionary*)sender;
        SMRouteNavigationController *destViewController = segue.destinationViewController;
        [destViewController setStartLocation:[params objectForKey:@"start"]];
        [destViewController setEndLocation:[params objectForKey:@"end"]];
        [destViewController setDestination:self.destination];
        [destViewController setSource:self.source];
        [destViewController setJsonRoot:self.jsonRoot];
        
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
    } else if ([segue.identifier isEqualToString:@"mainToSearch"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setSearchText:self.favName];
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
        if ([self.favoritesList count] > 0) {
            if (tblMenu.isEditing) {
                return [self.favoritesList count];
            } else {
                return [self.favoritesList count] + 1;
            }
        } else {
            return 1;
        }
        return [self.favoritesList count];
    } else if (tableView == tblFavorites) {
        return [self.favoritesList count];
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
        
        SMContactsCell * cell = [tableView dequeueReusableCellWithIdentifier:@"contactsCell"];
        
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
        if ([self.favoritesList count] > 0) {
            if (tblMenu.isEditing) {
                NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                [cell.image setContentMode:UIViewContentModeCenter];
                [cell setDelegate:self];
                [cell.image setImage:[UIImage imageNamed:@"favReorder"]];
                [cell.editBtn setHidden:NO];
                [cell.text setText:[currentRow objectForKey:@"name"]];
                return cell;
            } else {
                if (indexPath.row < [self.favoritesList count]) {
                    NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                    SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                    [cell.image setContentMode:UIViewContentModeCenter];
                    [cell setDelegate:self];
                    if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favHome"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favWork"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favBookmark"]];
                    } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
                        [cell.image setImage:[UIImage imageNamed:@"favStar"]];
                    } else {
                        [cell.image setImage:nil];
                    }
                    [cell.editBtn setHidden:YES];
                    [cell.text setText:[currentRow objectForKey:@"name"]];
                    return cell;
                } else {
                    SMAddFavoriteCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesAddCell"];
                    [cell.image setContentMode:UIViewContentModeCenter];
                    [cell.text setText:translateString(@"cell_add_favorite")];
                    return cell;
                }
            }
        } else {
            SMEmptyFavoritesCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesEmptyCell"];
            [cell.text setText:translateString(@"cell_add_favorite")];
            [cell.addFavoritesText setText:translateString(@"cell_empty_favorite_text")];
            return cell;
        }
        
        
        
    } else if (tableView == tblEvents) {
        NSDictionary * currentRow = [[[self.eventsGroupedArray objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
        if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
            SMEventsCalendarCell * cell = [tableView dequeueReusableCellWithIdentifier:@"eventsCalendarCell"];
            
            if ((indexPath.row % 2) == 0) {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowEvenBG"]];
            } else {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowOddBG"]];
            }
            
            NSDateFormatter * df = [[NSDateFormatter alloc] init];
            [df setDateFormat:TIME_FORMAT];
            [cell.timeLabel setText:[NSString stringWithFormat:@"%@ - %@", [df stringFromDate:[currentRow objectForKey:@"startDate"]], [df stringFromDate:[currentRow objectForKey:@"endDate"]]]];
            [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
            [cell.addressLabel setText:[currentRow objectForKey:@"address"]];

            [df setDateFormat:@"dd"];
            [cell.dayLabel setText:[df stringFromDate:[currentRow objectForKey:@"startDate"]]];
            [df setDateFormat:@"MMM"];
            [cell.monthLabel setText:[df stringFromDate:[currentRow objectForKey:@"startDate"]]];

            return cell;
        } else {
            SMEventsFacebookCell * cell = [tableView dequeueReusableCellWithIdentifier:@"eventsFacebookCell"];
            if ((indexPath.row % 2) == 0) {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowEvenBG"]];
            } else {
                [cell.cellBG setImage:[UIImage imageNamed:@"eventsRowOddBG"]];
            }

            [cell.eventImg loadImage:[currentRow objectForKey:@"picture"]];
            NSDateFormatter * df = [[NSDateFormatter alloc] init];
            [df setDateFormat:TIME_FORMAT];
            [cell.timeLabel setText:[NSString stringWithFormat:@"%@ - %@", [df stringFromDate:[currentRow objectForKey:@"startDate"]], [df stringFromDate:[currentRow objectForKey:@"endDate"]]]];
            [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
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
            }];
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];            
        }
    } else if (tableView == tblMenu) {
        if ([self.favoritesList count] == 0) {
            /**
             * add favorite
             */
            [self addFavoriteShow:nil];
        } else {
            if (tblMenu.isEditing) {
                /**
                 * edit favorite
                 */
                self.locDict = [self.favoritesList objectAtIndex:indexPath.row];
                [self editFavoriteShow:nil];
            } else {
                /**
                 * navigate to favorite
                 */
                if (indexPath.row < [self.favoritesList count]) {
                    NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                    
                    [self.view bringSubviewToFront:fadeView];
                    [UIView animateWithDuration:0.4f animations:^{
                        [fadeView setAlpha:1.0f];
                    }];
                    
                    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] floatValue] longitude:[[currentRow objectForKey:@"long"] floatValue]];
                    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                    [r setRequestIdentifier:@"rowSelectRoute"];
                    [r setAuxParam:[currentRow objectForKey:@"name"]];
                    [r findNearestPointForStart:cStart andEnd:cEnd];
                } else {
                    /**
                     * add favorite
                     */
                    [self addFavoriteShow:nil];
                }
            }
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == tblContacts) {
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
    if (tableView == tblMenu) {
        if ([self.favoritesList count] == 0) {
            return [SMEmptyFavoritesCell getHeight];
        } else {
            return [SMMenuCell getHeight];
        }
    }
    return 45.0f;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == tblMenu) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (tableView == tblMenu) {
        NSDictionary * dst = [self.favoritesList objectAtIndex:destinationIndexPath.row];
        NSDictionary * src = [self.favoritesList objectAtIndex:sourceIndexPath.row];
        [self.favoritesList removeObjectAtIndex:destinationIndexPath.row];
        [self.favoritesList insertObject:src atIndex:destinationIndexPath.row];
        [self.favoritesList removeObjectAtIndex:sourceIndexPath.row];
        [self.favoritesList insertObject:dst atIndex:sourceIndexPath.row];
        [SMUtil saveFavorites:self.favoritesList];
    } else if (tableView == tblEvents) {
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
    }
    

    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	//	Grip customization code goes in here...
	for(UIView* view in cell.subviews) {
		if([[[view class] description] isEqualToString:@"UITableViewCellReorderControl"]) {
			UIView* resizedGripView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame))];
			[resizedGripView addSubview:view];
			[cell addSubview:resizedGripView];
            
			CGSize sizeDifference = CGSizeMake(resizedGripView.frame.size.width - view.frame.size.width, resizedGripView.frame.size.height - view.frame.size.height);
			CGSize transformRatio = CGSizeMake(resizedGripView.frame.size.width / view.frame.size.width, resizedGripView.frame.size.height / view.frame.size.height);
            
			//	Original transform
			CGAffineTransform transform = CGAffineTransformIdentity;
            
			//	Scale custom view so grip will fill entire cell
			transform = CGAffineTransformScale(transform, transformRatio.width, transformRatio.height);
            
			//	Move custom view so the grip's top left aligns with the cell's top left
			transform = CGAffineTransformTranslate(transform, -sizeDifference.width / 2.0, -sizeDifference.height / 2.0);
            
			[resizedGripView setTransform:transform];
            
			for(UIImageView* cellGrip in view.subviews)
			{
				if([cellGrip isKindOfClass:[UIImageView class]])
					[cellGrip setImage:nil];
			}
		}
	}
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
    [self findRouteFrom:from to:to fromAddress:src toAddress:dst withJSON:nil];
}

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst withJSON:(id)jsonRoot{
    CLLocation * start = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * end = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];    
    self.destination = dst;
    self.source = src;
    self.jsonRoot = jsonRoot;
    if (self.navigationController.topViewController == self) {
        [self performSegueWithIdentifier:@"goToNavigationView" sender:@{@"start" : start, @"end" : end}];
    }
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
    [self checkCallouts];
}

- (void)mapView:(RMMapView *)mapView didUpdateUserLocation:(RMUserLocation *)userLocation {
    [self checkCallouts];
}

- (void)tapOnAnnotation:(SMAnnotation *)annotation onMap:(RMMapView *)map {
    if ([annotation.annotationType isEqualToString:@"marker"]) {
        
        [self.mpView setCenterCoordinate:annotation.coordinate animated:YES];
        [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
        
        
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
    self.findTo = [NSString stringWithFormat:@"%@, %@", annotation.title, annotation.subtitle];
    self.findMatches = annotation.nearbyObjects;
    
    [self.view bringSubviewToFront:fadeView];
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:annotation.routingCoordinate.coordinate.latitude longitude:annotation.routingCoordinate.coordinate.longitude];
    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setRequestIdentifier:@"rowSelectRoute"];
    [r setAuxParam:annotation.title];
    [r findNearestPointForStart:cStart andEnd:cEnd];

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
    [self.destinationPin showCallout];
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
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", s.coordinate.latitude, s.coordinate.longitude, @"", e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        self.startName = CURRENT_POSITION_STRING;
        self.endName = req.auxParam;
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:s.coordinate to:e.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        } else {
            [self findRouteFrom:self.startLoc to:self.endLoc fromAddress:self.startName toAddress:self.endName withJSON:jsonRoot];
            [self dismissViewControllerAnimated:YES completion:^{
            }];
            
        }
        [UIView animateWithDuration:0.2f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    }
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

#pragma mark - observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.mpView && [keyPath isEqualToString:@"userTrackingMode"]) {
        if (self.mpView.userTrackingMode == RMUserTrackingModeFollow) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowing];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeFollowWithHeading) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateFollowingWithHeading];
        } else if (self.mpView.userTrackingMode == RMUserTrackingModeNone) {
            [buttonTrackUser newGpsTrackState:SMGPSTrackButtonStateNotFollowing];
        }
    } else if (object == tblMenu && [keyPath isEqualToString:@"editing"]) {
        if (tblMenu.editing) {
            [favEditDone setHidden:NO];
            [favEditStart setHidden:YES];
        } else {
            [favEditDone setHidden:YES];
            [favEditStart setHidden:NO];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    }
}

#pragma mark - menu header delegate

- (void)editFavorite:(SMMenuCell *)cell {
    NSInteger ind = [tblMenu indexPathForCell:cell].row;
    debugLog(@"%d", ind);
}

#pragma mark - search delegate

- (void)locationFound:(NSDictionary *)locationDict {
    [self setLocDict:locationDict];
    [addFavAddress setText:[locationDict objectForKey:@"address"]];
    [addFavName setText:[locationDict objectForKey:@"name"]];
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end


