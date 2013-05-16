//
//  SMAccountController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 21/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMAPIRequest.h"

@interface SMAccountController : SMTranslatedViewController <UITextFieldDelegate, SMAPIRequestDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>{
    
    __weak IBOutlet UIImageView *fbImage;
    __weak IBOutlet UILabel *fbName;
    __weak IBOutlet UIView *fbView;
    
    __weak IBOutlet UIScrollView *scrlView;
    
    
    __weak IBOutlet UIImageView *regularImage;
    __weak IBOutlet UITextField *name;
    __weak IBOutlet UITextField *email;
    __weak IBOutlet UITextField *password;
    __weak IBOutlet UITextField *passwordRepeat;
    __weak IBOutlet UIView *regularView;
    BOOL hasChanged;
}

@end
