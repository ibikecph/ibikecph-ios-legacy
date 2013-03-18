//
//  SMSplashController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/03/2013.
//  Copyright (c) 2013. Spoiled Milk. All rights reserved.
//

#import "SMTranslatedViewController.h"

@interface SMSplashController : SMTranslatedViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    
    __weak IBOutlet UIView *registerView;
    __weak IBOutlet UIView *loginView;
    __weak IBOutlet UIScrollView *registerScroll;
    __weak IBOutlet UIView *registerDialog;
    __weak IBOutlet UITextField *nameField;
    __weak IBOutlet UITextField *emailField;
    __weak IBOutlet UITextField *passwordField;
    __weak IBOutlet UITextField *passwordRepeatField;
    __weak IBOutlet UITextField *loginEmail;
    __weak IBOutlet UITextField *loginPassword;
    __weak IBOutlet UIScrollView *loginScroll;
    __weak IBOutlet UIView *loginDialog;
}

@end
