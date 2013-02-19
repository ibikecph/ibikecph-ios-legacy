//
//  SMFindAddressController.h
//  iBike
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SMAutocomplete.h"
#import "SMRequestOSRM.h"

@protocol RouteFinderDelegate <NSObject>

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString*)src toAddress:(NSString*)dst;

@end

@interface SMFindAddressController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SMAutocompleteDelegate, UIScrollViewDelegate, SMRequestOSRMDelegate> {
    
    __weak IBOutlet UITableView *tblView;
    __weak IBOutlet UITextField *routeFrom;
    __weak IBOutlet UITextField *routeTo;
    __weak IBOutlet UIView *fadeView;
    __weak IBOutlet UIButton *btnStart;
}

@property (nonatomic, weak) id<RouteFinderDelegate> delegate;
@property (nonatomic, strong) NSString * locationFrom;
@property (nonatomic, strong) NSString * locationTo;

@property (nonatomic, strong) CLLocation * startLocation;
@property (nonatomic, strong) CLLocation * endLocation;

- (void)loadMatches:(NSArray*)nearby;

@end
