//
//  SMRegisterController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 11/05/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMAPIRequest.h"

@interface SMRegisterController : SMTranslatedViewController <SMAPIRequestDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    __weak IBOutlet UIScrollView *scrlView;
    __weak IBOutlet UITextField *registerName;
    __weak IBOutlet UITextField *registerEmail;
    __weak IBOutlet UITextField *registerPassword;
    __weak IBOutlet UITextField *registerRepeatPassword;
    __weak IBOutlet UIImageView *registerImage;
}

@end
