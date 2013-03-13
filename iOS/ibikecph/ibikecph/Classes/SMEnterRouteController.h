//
//  SMEnterRouteController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMRequestOSRM.h"

@interface SMEnterRouteController : SMTranslatedViewController <SMRequestOSRMDelegate, UITableViewDataSource, UITableViewDelegate>{
    
    __weak IBOutlet UILabel *fromLabel;
    __weak IBOutlet UILabel *toLabel;
    __weak IBOutlet UITableView *tblView;
    __weak IBOutlet UIView *fadeView;
}

@end
