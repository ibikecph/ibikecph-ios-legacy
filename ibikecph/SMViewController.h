//
//  SMViewController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMContacts.h"
#import "SMContactsHeader.h"
#import "SMEnterRouteController.h"
#import "SMEvents.h"

#import "RMMapView.h"
#import "SMAnnotation.h"
#import "SMNearbyPlaces.h"
#import "SMRequestOSRM.h"

#import "SMGPSTrackButton.h"
#import "SMMenuCell.h"
#import "SMSearchController.h"

#import "SMAddFavoriteCell.h"
#import "SMFavoritesUtil.h"

#import "FlickableView.h"

typedef enum {
    screenMenu,
    screenMap,
    screenContacts
} CurrentScreenType;

/**
 * \ingroup screens
 * Main app view
 */

@interface SMViewController : SMTranslatedViewController <RMMapViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, EnterRouteDelegate, UIGestureRecognizerDelegate, SMAnnotationActionDelegate, SMNearbyPlacesDelegate, SMRequestOSRMDelegate, SMMenuCellDelegate, SMSearchDelegate, UITextFieldDelegate, ViewTapDelegate, SMFavoritesDelegate>  {
    IBOutlet UIView *menuView;
    __weak IBOutlet FlickableView *centerView;
    __weak IBOutlet UIView *dropPinView;
    
    CurrentScreenType currentScreen;
    
    __weak IBOutlet UITableView *tblMenu;
    __weak IBOutlet UIView *fadeView;

    __weak IBOutlet SMGPSTrackButton *buttonTrackUser;
    __weak IBOutlet UIView *favHeader;
    __weak IBOutlet UIView *accHeader;
    __weak IBOutlet UIView *infHeader;
    __weak IBOutlet UIButton *favEditStart;
    __weak IBOutlet UIButton *favEditDone;
    __weak IBOutlet UIButton *addFavFavoriteButton;
    __weak IBOutlet UIButton *addFavHomeButton;
    __weak IBOutlet UIButton *addFavWorkButton;
    __weak IBOutlet UIButton *addFavSchoolButton;
    __weak IBOutlet UITextField *addFavAddress;
    __weak IBOutlet UITextField *addFavName;

    __weak IBOutlet UIView *mainMenu;
    __weak IBOutlet UIView *addMenu;
    
    __weak IBOutlet UILabel *editTitle;
    __weak IBOutlet UIButton *editSaveButton;
    __weak IBOutlet UIButton *editDeleteButton;
    __weak IBOutlet UIButton *addSaveButton;
    
    __weak IBOutlet UIView *blockingView;
    
    __weak IBOutlet UIButton *findRouteBig;
    __weak IBOutlet UIButton *findRouteSmall;
    BOOL animationShown;
    __weak IBOutlet UILabel *account_label;
    __weak IBOutlet UILabel *routeStreet;
    __weak IBOutlet UIView *menuBtn;
    __weak IBOutlet UIButton *pinButton;
    __weak IBOutlet UIView *statusbarView;
}

/**
 * properties for table
 */
@property (nonatomic, strong) IBOutlet SMAddFavoriteCell *tableFooter;

@end
