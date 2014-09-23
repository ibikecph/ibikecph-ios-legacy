//
//  SMLoginController.h
//  I Bike CPH
//
//  Created by Rasko Gojkovic on 5/9/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMAPIRequest.h"

/**
 * \ingroup screens
 * Login from menu
 */

@interface SMLoginController : SMTranslatedViewController<SMAPIRequestDelegate, UITextFieldDelegate> {
    __weak IBOutlet UITextField *loginEmail;
    __weak IBOutlet UITextField *loginPassword;
    __weak IBOutlet UIScrollView *scrlView;
    
}

@end
