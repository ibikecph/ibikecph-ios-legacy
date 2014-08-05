	//
//  SMViewController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMViewController.h"

#import "SMContactsCell.h"
#import "SMContactsHeader.h"

#import "SMLocationManager.h"

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
#import "SMFavoritesUtil.h"
#import "SMAPIRequest.h"
#import "UIView+LocateSubview.h"

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

@interface SMViewController () <SMAPIRequestDelegate>{
    MenuType menuOpen;
    
    FavoriteType currentFav;
    BOOL pinWorking;
}

@property (nonatomic, strong) SMContacts *contacts;
@property (nonatomic, strong) RMMapView *mpView;

/**
 * data sources for tables
 */
@property (nonatomic, strong) NSMutableArray * favoritesList;
@property (nonatomic, strong) NSMutableArray * favorites;
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
@property NSInteger locIndex;
@property (nonatomic, strong) NSString * favName;

@property (nonatomic, strong) SMFavoritesUtil * favs;

@property (nonatomic, strong) SMAPIRequest * request;
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
    pinWorking = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];
    }
    
    [RMMapView class];
    
    animationShown = NO;
    
    menuOpen = menuFavorites;
    
    [SMLocationManager instance];
    
    
    /**
     * start with empty favorites array
     */
    self.favorites = [@[] mutableCopy];
    [self setFavoritesList:[SMFavoritesUtil getFavorites]];

    /**
     * removed for alpha
     */
//    [self performSelector:@selector(getPhoneContacts) withObject:nil afterDelay:0.001f];
    /**
     * end alpha remove
     */
    
    currentScreen = screenMap;
    [self.mpView setTileSource:TILE_SOURCE];
    [self.mpView setDelegate:self];
    [self.mpView setMaxZoom:MAX_MAP_ZOOM];

    
    [self.mpView setCenterCoordinate:CLLocationCoordinate2DMake(55.675455,12.566643) animated:NO];
    [self.mpView setZoom:16];
//    [self.mpView zoomByFactor:1 near:CGPointMake(self.mpView.frame.size.width/2.0f, self.mpView.frame.size.height/2.0f) animated:NO];
    [self.mpView setEnableBouncing:TRUE];
    
    [self openMenu:menuFavorites];
    
    UITapGestureRecognizer * dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [dblTap setNumberOfTapsRequired:2];
    [blockingView addGestureRecognizer:dblTap];
    

    self.tableFooter = [SMAddFavoriteCell getFromNib];
    [self.tableFooter setDelegate:self];
    [self.tableFooter.text setText:translateString(@"cell_add_favorite")];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoritesChanged:) name:kFAVORITES_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidToken:) name:@"invalidToken" object:nil];
    
    [centerView setupForHorizontalSwipeWithStart:0.0f andEnd:260.0f andStart:0.0f andPullView:menuBtn];
    [centerView addPullView:blockingView];

}

- (void)invalidToken:(NSNotification*)notification {
    [SMFavoritesUtil saveFavorites:@[]];
    [account_label setText:translateString(@"account_login")];
    self.favoritesList = [SMFavoritesUtil getFavorites];
    [self openMenu:menuFavorites];
}

- (IBAction)doubleTap:(UITapGestureRecognizer*)sender {
    
}

- (void)viewDidUnload {
    self.mpView = nil;
    menuView = nil;
    centerView = nil;
    dropPinView = nil;
    tblMenu = nil;
    fadeView = nil;
    buttonTrackUser = nil;
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
    blockingView = nil;
    findRouteBig = nil;
    findRouteSmall = nil;
    self.tableFooter = nil;
    account_label = nil;
    routeStreet = nil;
    menuBtn = nil;
    menuBtn = nil;
    pinButton = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        statusbarView.hidden = YES;
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent];

    
    [self readjustViewsForRotation:self.interfaceOrientation];
    
    self.findFrom = @"";
    self.findTo = @"";
    
//#if DEBUG
//    [debugLabel setText:BUILD_STRING];
//#else
//    [debugLabel setText:@""];
//#endif
    
    findRouteSmall.alpha = 1.0f;
    findRouteBig.alpha = 0.0f;
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [account_label setText:translateString(@"account")];
    } else {
        [SMFavoritesUtil saveFavorites:@[]];
        [account_label setText:translateString(@"account_login")];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mpView setUserTrackingMode:RMUserTrackingModeNone];
    @try{
        [self.mpView removeObserver:self forKeyPath:@"userTrackingMode" context:nil];
        [centerView removeObserver:self forKeyPath:@"frame"];
        [tblMenu removeObserver:self forKeyPath:@"editing"];
    }@catch(id anException){
    }
    
    CGRect frame = dropPinView.frame;
    frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
    [dropPinView setFrame:frame];
    frame = buttonTrackUser.frame;
    frame.origin.y = dropPinView.frame.origin.y - 65.0f;
    [buttonTrackUser setFrame:frame];

    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]]) {
        NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"lastRoute.plist"]];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)",CURRENT_POSITION_STRING, [[d objectForKey:@"startLat"] doubleValue], [[d objectForKey:@"startLong"] doubleValue], [d objectForKey:@"destination"], [[d objectForKey:@"endLat"] doubleValue], [[d objectForKey:@"endLong"] doubleValue]];
        debugLog(@"%@", st);
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Resume" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        /**
         * show new route
         */
        CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"endLat"] floatValue] longitude:[[d objectForKey:@"endLong"] floatValue]];
        CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[[d objectForKey:@"startLat"] floatValue] longitude:[[d objectForKey:@"startLong"] floatValue]];
        
        
        
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setRequestIdentifier:@"rowSelectRoute"];
        [r setAuxParam:[d objectForKey:@"destination"]];
        [r findNearestPointForStart:cStart andEnd:cEnd];                
    } else {
        [self.mpView addObserver:self forKeyPath:@"userTrackingMode" options:0 context:nil];
        [tblMenu addObserver:self forKeyPath:@"editing" options:0 context:nil];
        [centerView addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
    
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        SMFavoritesUtil * fv = [[SMFavoritesUtil alloc] initWithDelegate:self];
        [self setFavs:fv];
        [self.favs fetchFavoritesFromServer];
    } else {
        [self favoritesChanged:nil];
    }
}

#pragma mark - custom methods

- (CGFloat)heightForFavorites {
    if ([self.favoritesList count] == 0) {
        return [SMEmptyFavoritesCell getHeight] + 45.0f;
    } else {
        CGFloat startY = favHeader.frame.origin.y;
        CGFloat maxHeight = menuView.frame.size.height - startY;
        return MIN(tblMenu.contentSize.height + 45.0f, maxHeight - 2 * 45.0f);
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
            
            if (favHeader.frame.size.height < tblMenu.contentSize.height) {
                [tblMenu setBounces:YES];
            } else {
                [tblMenu setBounces:NO];
            }
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
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self performSegueWithIdentifier:@"mainToAccount" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"mainToLogin" sender:nil];
    }
}

- (IBAction)tapInfo:(id)sender {
    [self performSegueWithIdentifier:@"openAbout" sender:nil];
}

- (void)longSingleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    if (blockingView.alpha > 0) {
        return;
    }
    
    for (SMAnnotation * annotation in self.mpView.annotations) {
        if ([annotation.annotationType isEqualToString:@"marker"] && [annotation isKindOfClass:[SMAnnotation class]]) {
            if (annotation.calloutShown) {
                [annotation hideCallout];
            }
        }
    }
    
    CLLocationCoordinate2D coord = [self.mpView pixelToCoordinate:point];
    CLLocation * loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    debugLog(@"pin drop LOC: %@", loc);
    debugLog(@"pin drop POINT: %@", NSStringFromCGPoint(point));
    
    
    UIImageView * im = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 17.0f, 0.0f, 34.0f, 34.0f)];
    [im setImage:[UIImage imageNamed:@"markerFinish"]];
    [self.mpView addSubview:im];
    [UIView animateWithDuration:0.2f animations:^{
        [im setFrame:CGRectMake(point.x - 17.0f, point.y - 34.0f, 34.0f, 34.0f)];
    } completion:^(BOOL finished) {
        debugLog(@"dropped pin");
        [self.mpView removeAllAnnotations];
        SMAnnotation *endMarkerAnnotation = [SMAnnotation annotationWithMapView:self.mpView coordinate:coord andTitle:@""];
        endMarkerAnnotation.annotationType = @"marker";
        endMarkerAnnotation.annotationIcon = [UIImage imageNamed:@"markerFinish"];
        endMarkerAnnotation.anchorPoint = CGPointMake(0.5, 1.0);
        [self.mpView addAnnotation:endMarkerAnnotation];
        [self setDestinationPin:endMarkerAnnotation];
        
        [self.destinationPin setSubtitle:@""];
        [self.destinationPin setDelegate:self];
        [self.destinationPin setRoutingCoordinate:loc];

        
        [im removeFromSuperview];
        
        [self showPinDrop];
        
        [SMGeocoder reverseGeocode:coord completionHandler:^(NSDictionary *response, NSError *error) {
            [routeStreet setText:[response objectForKey:@"title"]];
            if ([routeStreet.text isEqualToString:@""]) {
                [routeStreet setText:[NSString stringWithFormat:@"%f, %f", coord.latitude, coord.longitude]];
            }
            
            NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
            NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
            if ([arr count] > 0) {
                [pinButton setSelected:YES];
            } else {
                [pinButton setSelected:NO];
            }
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"] && [[self.appDelegate.appSettings objectForKey:@"auth_token"] isKindOfClass:[NSString class]] && [[self.appDelegate.appSettings objectForKey:@"auth_token"] isEqualToString:@""] == NO) {
                pinButton.enabled = YES;
            } else {
                pinButton.enabled = NO;
            }
            
//            [self.destinationPin setSubtitle:@""];
            [self.destinationPin setTitle:[response objectForKey:@"title"]];
//            [self.destinationPin setDelegate:self];
//            [self.destinationPin setRoutingCoordinate:loc];
        }];
        
//        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
//        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude]];
    }];

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
    
    CGRect frame = centerView.frame;
    frame.size.width = scrWidth;
    frame.size.height = scrHeight;
//    frame.origin.x = 0.0f;
    [centerView setFrame:frame];
    
    frame = dropPinView.frame;
    frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
    [dropPinView setFrame:frame];
}

#pragma mark - rotation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self readjustViewsForRotation:toInterfaceOrientation];
}

#pragma mark - button actions

- (IBAction)goToPin:(id)sender {
    [self annotationActivated:self.destinationPin];
    [self hidePinDrop];
}

- (void)delayedAddPin {
    NSDictionary * d = @{
                         @"name" : routeStreet.text,
                         @"address" : routeStreet.text,
                         @"startDate" : [NSDate date],
                         @"endDate" : [NSDate date],
                         @"source" : @"favorites",
                         @"subsource" : @"favorite",
                         @"lat" :[NSNumber numberWithDouble: self.destinationPin.coordinate.latitude],
                         @"long" : [NSNumber numberWithDouble: self.destinationPin.coordinate.longitude],
                         @"order" : @0
                         };
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    fv.delegate = self;
    if ([arr count] > 0) {
        [pinButton setSelected:NO];
        [fv deleteFavoriteFromServer:[arr objectAtIndex:0]];
        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    } else {
        [pinButton setSelected:YES];
        [fv addFavoriteToServer:d];
        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    }
}

- (IBAction)pinAddToFavorites:(id)sender {
    if (pinWorking == NO) {
        pinWorking = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAddPin) object:nil];
        [self performSelector:@selector(delayedAddPin) withObject:nil afterDelay:0.2f];
    }
}

- (void)showPinDrop {
    CGRect frame = dropPinView.frame;
    frame.origin.y = centerView.frame.size.height - 6.0f;
    [dropPinView setFrame:frame];
    [dropPinView setHidden:NO];
    routeStreet.text = @"";
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAddPin) object:nil];
    pinWorking = NO;
    pinButton.enabled = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = dropPinView.frame;
        frame.origin.y = centerView.frame.size.height - dropPinView.frame.size.height;
        [dropPinView setFrame:frame];
        
        frame = buttonTrackUser.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [buttonTrackUser setFrame:frame];
        
    } completion:^(BOOL finished) {
    }];
}

- (void)hidePinDrop {
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect frame = dropPinView.frame;
        frame.origin.y = self.mpView.frame.origin.y + self.mpView.frame.size.height;
        [dropPinView setFrame:frame];
        frame = buttonTrackUser.frame;
        frame.origin.y = dropPinView.frame.origin.y - 65.0f;
        [buttonTrackUser setFrame:frame];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (IBAction)slideMenuOpen:(id)sender {
    if (centerView.frame.origin.x == 0.0f) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 260.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            [self setNeedsStatusBarAppearanceUpdate];
            blockingView.alpha = 1.0f;
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 0.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            [self setNeedsStatusBarAppearanceUpdate];
            blockingView.alpha = 0.0f;
        }];        
    }    
}

- (IBAction)enterRoute:(id)sender {
    [self performSegueWithIdentifier:@"enterRouteSegue" sender:nil];
}

- (IBAction)editFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];

    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
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
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

- (IBAction)addFavoriteShow:(id)sender {
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];


    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
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
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
    
    
}

- (void)animateEditViewShow {
    CGRect frame = mainMenu.frame;
    frame.origin.x = 0.0f;
    [mainMenu setFrame:frame];
    
    frame.origin.x = 260.0f;
    [addMenu setFrame:frame];
    [addMenu setHidden:NO];
    
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = -260.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 0.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
    }];
    
}

- (IBAction)addFavoriteHide:(id)sender{
    [self.view hideKeyboard];
    [self.view removeKeyboardControl];
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = mainMenu.frame;
        frame.origin.x = 0.0f;
        [mainMenu setFrame:frame];
        frame = addMenu.frame;
        frame.origin.x = 260.0f;
        [addMenu setFrame:frame];
    } completion:^(BOOL finished) {
        [mainMenu setHidden:NO];
        [addMenu setHidden:YES];
        [self setFavoritesList:[SMFavoritesUtil getFavorites]];
        if ([self.favoritesList count] == 0) {
            [tblMenu setEditing:NO];
        }
        [UIView animateWithDuration:0.4f animations:^{
            [self openMenu:menuFavorites];
        }];
    }];
}

- (IBAction)saveFavorite:(id)sender {
   
    NSMutableArray * favs = [SMFavoritesUtil getFavorites];
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"name == %@", addFavName.text];
    NSArray * arr = [favs filteredArrayUsingPredicate:pred];
    if (arr.count > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_duplicate_favorite_name") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [av show];
        return;
    }
        
    if (self.locDict && [self.locDict objectForKey:@"address"] && [addFavName.text isEqualToString:@""] == NO) {
        if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
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
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
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
            
            [self addFavoriteHide:nil];
            
            
            if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        }
    }
}

- (IBAction)deleteFavorite:(id)sender {
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
        [fv deleteFavoriteFromServer:@{
         @"id" : [[self.favoritesList objectAtIndex:self.locIndex] objectForKey:@"id"]
         }];
        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
        [self addFavoriteHide:nil];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];

    }
    
    
    }

- (IBAction)editSaveFavorite:(id)sender {
    
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
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
                                @"id" : [[self.favoritesList objectAtIndex:self.locIndex] objectForKey:@"id"],
                                @"name" : addFavName.text,
                                @"address" : [self.locDict objectForKey:@"address"],
                                @"startDate" : [NSDate date],
                                @"endDate" : [NSDate date],
                                @"source" : @"favorites",
                                @"subsource" : favType,
                                @"lat" : [self.locDict objectForKey:@"location"]?[NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude]:[self.locDict objectForKey:@"lat"],
                                @"long" : [self.locDict objectForKey:@"location"]?[NSNumber numberWithDouble:((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude]:[self.locDict objectForKey:@"long"],
                                @"order" : @0
                                };
        
        debugLog(@"%@", dict);
        
        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
        [fv editFavorite:dict];
        [self addFavoriteHide:nil];
        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Save" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.latitude, ((CLLocation*)[self.locDict objectForKey:@"location"]).coordinate.longitude] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        
    }
}


- (IBAction)findAddress:(id)sender {
    [self.view hideKeyboard];
    self.favName = addFavAddress.text;
    [self performSegueWithIdentifier:@"mainToSearch" sender:nil];
    
}

- (IBAction)addSelectFavorite:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"Schoole")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Favorite")];
    }
    
    
    [addFavFavoriteButton setSelected:YES];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeFavorite;
}

- (IBAction)addSelectHome:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Home")];
    }
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:YES];
    [addFavWorkButton setSelected:NO];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeHome;
}

- (IBAction)addSelectWork:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"Work")];
    }
    [addFavFavoriteButton setSelected:NO];
    [addFavHomeButton setSelected:NO];
    [addFavWorkButton setSelected:YES];
    [addFavSchoolButton setSelected:NO];
    currentFav = typeWork;
}

- (IBAction)addSelectSchool:(id)sender {
    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
        [addFavName.text isEqualToString:@""]) {
        [addFavName setText:translateString(@"School")];
    }
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
    int i = 0;
    NSMutableArray * arr = [NSMutableArray array];
    for (NSDictionary * d in self.favoritesList) {
        [arr addObject:@{
         @"id" : [d objectForKey:@"id"],
         @"position" : [NSString stringWithFormat:@"%d", i]
         }];
        i += 1;
    }
    self.request = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self.request executeRequest:API_SORT_FAVORITES withParams:@{@"auth_token" : [self.appDelegate.appSettings objectForKey:@"auth_token"], @"pos_ary" : arr}];
}

- (void)trackingOn {
    [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
}

- (IBAction)trackUser:(id)sender {
    if (buttonTrackUser.gpsTrackState != SMGPSTrackButtonStateNotFollowing)
        debugLog(@"Warning: trackUser button state was invalid: 0x%0x", buttonTrackUser.gpsTrackState);

    if ([SMLocationManager instance].hasValidLocation) {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackingOn) object:nil];
//        [self performSelector:@selector(trackingOn) withObject:nil afterDelay:1.0];
        [self.mpView setCenterCoordinate:[SMLocationManager instance].lastValidLocation.coordinate];
    } else {
        [self.mpView setUserTrackingMode:RMUserTrackingModeFollow];
    }
}

- (IBAction)showMenu:(id)sender {
    if (currentScreen == screenMenu) {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 0.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            currentScreen = screenMap;
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            CGRect frame = centerView.frame;
            frame.origin.x = 260.0f;
            [centerView setFrame:frame];
        } completion:^(BOOL finished) {
            currentScreen = screenMenu;
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"enterRouteSegue"]) {
        SMEnterRouteController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"goToNavigationView"]) {
        [self.mpView removeAllAnnotations];
        for (id v in self.mpView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }

        
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
                             @"destination": ((self.destination == nil) ? @"" : self.destination),
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.favoritesList count] > 0) {
        return [self.favoritesList count];
    } else {
        return 1;
    }
    return [self.favoritesList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == tblMenu) {
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
                NSDictionary * currentRow = [self.favoritesList objectAtIndex:indexPath.row];
                SMMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesCell"];
                [cell.image setContentMode:UIViewContentModeCenter];
                [cell setDelegate:self];
                [cell setIndentationLevel:2];
                if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
                    [cell.image setImage:[UIImage imageNamed:@"favHomeGrey"]];
                    [cell.image setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
                } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
                    [cell.image setImage:[UIImage imageNamed:@"favWorkGrey"]];
                    [cell.image setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
                } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
                    [cell.image setImage:[UIImage imageNamed:@"favSchoolGrey"]];
                    [cell.image setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
                } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
                    [cell.image setImage:[UIImage imageNamed:@"favStarGreySmall"]];
                    [cell.image setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
                } else {
                    [cell.image setImage:nil];
                }
                [cell.editBtn setHidden:YES];
                [cell.text setText:[currentRow objectForKey:@"name"]];
                
                UIView * v = [cell viewWithTag:10001];
                if (v) {
                    [v removeFromSuperview];
                }
                return cell;
            }
        } else {
            SMEmptyFavoritesCell * cell = [tableView dequeueReusableCellWithIdentifier:@"favoritesEmptyCell"];
            [cell.text setText:translateString(@"cell_add_favorite")];
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                [cell.addFavoritesText setText:translateString(@"cell_empty_favorite_text")];
                [cell.addFavoritesText setTextColor:[UIColor whiteColor]];
                [cell.text setTextColor:[UIColor colorWithRed:0.0f/255.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"favAdd"]];
//                [cell.text setTextColor:[UIColor greenColor]];
            } else {
                [cell.addFavoritesText setText:translateString(@"favorites_login")];                
//                [cell.addFavoritesText setTextColor:[UIColor colorWithRed:96.0f/255.0f green:96.0f/255.0f blue:96.0f/255.0f alpha:1.0f]];
                [cell.addFavoritesText setTextColor:[UIColor colorWithRed:123.0f/255.0f green:123.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
                [cell.text setTextColor:[UIColor colorWithRed:123.0f/255.0f green:123.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
//                [cell.text setTextColor:[UIColor redColor]];
                [cell.addFavoritesSymbol setImage:[UIImage imageNamed:@"fav_plus_none_grey"]];

            }
            
            return cell;
        }
    }
    UITableViewCell * cell;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == tblMenu) {
        if ([self.favoritesList count] == 0) {
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                /**
                 * add favorite
                 */
                [self addFavoriteShow:nil];
            }
        } else {
            if (tblMenu.isEditing) {
                /**
                 * edit favorite
                 */
                self.locDict = [self.favoritesList objectAtIndex:indexPath.row];
                self.locIndex = indexPath.row;
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
                    
                    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Menu" withLabel:@"Favorites" withValue:0]) {
                        debugLog(@"error in trackEvent");
                    }
                    
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
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (tableView == tblMenu) {
        if ([self.favoritesList count] <= 1) {
            return;
        }
        NSDictionary * src = [self.favoritesList objectAtIndex:sourceIndexPath.row];
        [self.favoritesList removeObjectAtIndex:sourceIndexPath.row];
        [self.favoritesList insertObject:src atIndex:destinationIndexPath.row];
        [SMFavoritesUtil saveFavorites:self.favoritesList];
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
    UIView* view = [cell subviewWithClassName:@"UITableViewCellReorderControl"];
    
    if (view) {
        [view setExclusiveTouch:NO];
        UIView* resizedGripView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame))];
        resizedGripView.exclusiveTouch = YES;
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

        for(UIImageView* cellGrip in view.subviews) {
            if([cellGrip isKindOfClass:[UIImageView class]]) {
                [cellGrip setImage:nil];
            }
        }

        UIView * v = [cell viewWithTag:10001];
        if (v == nil) {
            UIButton * btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn2 setFrame:CGRectMake(52.0f, 0.0f, 156.0f, cell.frame.size.height)];
            [btn2 setTag:10001];
            [cell addSubview:btn2];
        }

        
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(208.0f, 0.0f, 52.0f, cell.frame.size.height)];
        [btn setTag:indexPath.row];
        [btn addTarget:self action:@selector(rowSelected:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btn];
        
    } else {
        UIView * v = [cell viewWithTag:10001];
        if (v) {
            [v removeFromSuperview];
        }
    }
}

- (IBAction)rowSelected:(id)sender {
    [self tableView:tblMenu didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:((UIButton*)sender).tag inSection:0]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == tblMenu) {
        if (tableView.isEditing) {
            return [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            if ([self.favoritesList count] > 0) {
                return self.tableFooter;
            } else {
                return [[UIView alloc] initWithFrame:CGRectZero];
            }
        }
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == tblMenu) {
        if (tableView.isEditing) {
            return 0.0f;
        } else {
            if ([self.favoritesList count] > 0) {
                return [SMAddFavoriteCell getHeight];
            } else {
                return 0.0f;
            }
        }
    } else {
        return 0.0f;
    }
}

#pragma mark - route finder delegate
- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst{
    [self findRouteFrom:from to:to fromAddress:src toAddress:dst withJSON:nil];
}

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString *)src toAddress:(NSString *)dst withJSON:(id)jsonRoot{
    CLLocation * start = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation * end = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];    
    self.destination = (dst == nil ? @"" : dst);
    self.source = (src == nil ? @"" : src);
    self.jsonRoot = jsonRoot;
    if (self.navigationController.topViewController == self) {
        [self performSegueWithIdentifier:@"goToNavigationView" sender:@{@"start" : start, @"end" : end}];
    }
}

#pragma mark - gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
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
        for (id v in self.mpView.subviews) {
            if ([v isKindOfClass:[SMCalloutView class]]) {
                [v removeFromSuperview];
            }
        }
        [self.mpView removeAllAnnotations];
        [self hidePinDrop];
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
//    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
//    [r setRequestIdentifier:@"rowSelectRoute"];
//    [r setAuxParam:annotation.title];
//    [r findNearestPointForStart:cStart andEnd:cEnd];
    
    
    /**
     * remove this if we need to find the closest point
     */
    NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", @"", cStart.coordinate.latitude, cStart.coordinate.longitude, @"", cEnd.coordinate.latitude, cEnd.coordinate.longitude];
    debugLog(@"%@", st);
    if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
        debugLog(@"error in trackPageview");
    }
    self.startName = CURRENT_POSITION_STRING;
    self.endName = annotation.title;
    self.startLoc = cStart.coordinate;
    self.endLoc = cEnd.coordinate;
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r getRouteFrom:cStart.coordinate to:cEnd.coordinate via:nil];
    /**
     * end routing
     */
}


#pragma mark - nearby places delegate

- (void) nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
//    [self.destinationPin setNearbyObjects:locations];
    [routeStreet setText:owner.title];
    if ([routeStreet.text isEqualToString:@""]) {
        [routeStreet setText:[NSString stringWithFormat:@"%f, %f", owner.coord.coordinate.latitude, owner.coord.coordinate.longitude]];
    }
    
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF.name = %@ AND SELF.address = %@", routeStreet.text, routeStreet.text];
    NSArray * arr = [[SMFavoritesUtil getFavorites] filteredArrayUsingPredicate:pred];
    if ([arr count] > 0) {
        [pinButton setSelected:YES];
    } else {
        [pinButton setSelected:NO];
    }
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"] && [[self.appDelegate.appSettings objectForKey:@"auth_token"] isEqualToString:@""] == NO) {
        pinWorking = NO;
        pinButton.enabled = YES;
    }
    
    
//    [self.destinationPin setSubtitle:owner.subtitle];
//    [self.destinationPin setTitle:owner.title];
//    [self.destinationPin setDelegate:self];
//    [self.destinationPin setRoutingCoordinate:owner.coord];
//    [self.destinationPin showCallout];
    
    
    
    [self showPinDrop];
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
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Pin" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        
        self.startName = CURRENT_POSITION_STRING;
        self.endName = req.auxParam;
        self.startLoc = s.coordinate;
        self.endLoc = e.coordinate;
        
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
    } else if (object == centerView  && [keyPath isEqualToString:@"frame"]) {
        if (centerView.frame.origin.x == 260.0f) {
            blockingView.alpha = 1.0f;
        } else if (centerView.frame.origin.x == 0.0f) {
            blockingView.alpha = 0.0f;            
            /**
             * close edit/save/delete menu if open
             */
            [self.view hideKeyboard];
            CGRect frame = mainMenu.frame;
            frame.origin.x = 0.0f;
            [mainMenu setFrame:frame];
            frame = addMenu.frame;
            frame.origin.x = 260.0f;
            [addMenu setFrame:frame];
            [mainMenu setHidden:NO];
            [addMenu setHidden:YES];
            [self setFavoritesList:[SMFavoritesUtil getFavorites]];
            if ([self.favoritesList count] == 0) {
                [tblMenu setEditing:NO];
            }
            [UIView animateWithDuration:0.4f animations:^{
                [self openMenu:menuFavorites];
            }];
        }
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
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
    if ([locationDict objectForKey:@"subsource"] && [[locationDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
        [addFavName setText:[locationDict objectForKey:@"name"]];
    } else {
        switch (currentFav) {
            case typeFavorite:
                [addFavName setText:translateString(@"Favorite")];
                break;
            case typeHome:
                [addFavName setText:translateString(@"Home")];
                break;
            case typeWork:
                [addFavName setText:translateString(@"Work")];
                break;
            case typeSchool:
                [addFavName setText:translateString(@"School")];
                break;
            default:
                [addFavName setText:translateString(@"Favorite")];
                break;
        }
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Add cell delegate

- (void)viewTapped:(id)view {
    [self addFavoriteShow:nil];
}

#pragma mark - custom methods

- (void)inputKeyboardWillHide:(NSNotification *)notification {
    CGRect frame = addMenu.frame;
    frame.size.height = menuView.frame.size.height;
    [addMenu setFrame:frame];
}

#pragma mark - notifications

- (void)favoritesChanged:(NSNotification*) notification {
    self.favoritesList = [SMFavoritesUtil getFavorites];
    [self openMenu:menuFavorites];
    
}

#pragma mark - smfavorites delegate

- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data {
    pinWorking = NO;
}

#pragma mark - api request delegate

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    
}

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
//    if (centerView.frame.origin.x == 0.0f) {
//        return UIStatusBarStyleDefault;
//    } else {
        return UIStatusBarStyleLightContent;
//    }
}

@end

