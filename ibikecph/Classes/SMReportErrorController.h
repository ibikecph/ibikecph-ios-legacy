//
//  SMReportErrorController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 05/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SMAPIRequest.h"

/**
 * \ingroup screens
 * Report an error screen
 */
@interface SMReportErrorController : SMTranslatedViewController <UIPickerViewDataSource, UIPickerViewDelegate, MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, SMAPIRequestDelegate> {
    
    __weak IBOutlet UIButton *btnSelectRouteSegment;
    __weak IBOutlet SMCustomCheckbox *switchContactMe;
    __weak IBOutlet UIScrollView *scrlView;
    __weak IBOutlet UIView *fadeView;
    __weak IBOutlet UIPickerView *pckrView;
    __weak IBOutlet UITableView *tblView;
    __weak IBOutlet UIView *reportSentView;
    __weak IBOutlet UITextField *reportEmail;
    
    BOOL pickerOpen;
    NSInteger currentSelection;
    __weak IBOutlet UIView *bottomView;
}

@property (nonatomic, strong) NSArray * routeDirections;
@property (nonatomic, strong) NSString * source;
@property (nonatomic, strong) NSString * destination;
@property (nonatomic, strong) CLLocation * sourceLoc;
@property (nonatomic, strong) CLLocation * destinationLoc;

@end
