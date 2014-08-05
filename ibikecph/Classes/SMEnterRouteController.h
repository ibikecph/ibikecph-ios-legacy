//
//  SMEnterRouteController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMRequestOSRM.h"
#import "SMSearchController.h"

@protocol EnterRouteDelegate <NSObject>

- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString*)src toAddress:(NSString*)dst;
- (void)findRouteFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to fromAddress:(NSString*)src toAddress:(NSString*)dst withJSON:(id)jsonRoot;

@end

@interface SMEnterRouteController : SMTranslatedViewController <SMRequestOSRMDelegate, UITableViewDataSource, UITableViewDelegate, SMSearchDelegate>{
    
    __weak IBOutlet UILabel *fromLabel;
    __weak IBOutlet UITableView *tblView;
    __weak IBOutlet UIView *fadeView;
    __weak IBOutlet UITextField *toLabel;
    __weak IBOutlet UIImageView *locationArrow;
    __weak IBOutlet UIButton *swapButton;
    __weak IBOutlet UIButton *startButton;
}

@property (nonatomic, weak) id<EnterRouteDelegate> delegate;

@end
