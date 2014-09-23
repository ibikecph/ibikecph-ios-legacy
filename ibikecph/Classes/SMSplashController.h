//
//  SMSplashController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/03/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMAPIRequest.h"
#import "SMFavoritesUtil.h"

/**
 * \ingroup screens
 * Splash screen controller
 *
 * Handles (auto)login and register
 */
@interface SMSplashController : SMTranslatedViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SMAPIRequestDelegate, SMFavoritesDelegate>{
    
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
    __weak IBOutlet UIButton *registerImage;
    __weak IBOutlet UIView *dialogView;
}

@end
