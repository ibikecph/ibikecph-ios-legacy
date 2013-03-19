//
//  SMSplashController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/03/2013.
//  Copyright (c) 2013. Spoiled Milk. All rights reserved.
//

#import "SMSplashController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SMAppDelegate.h"
#import "DAKeyboardControl.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

typedef enum {
    dialogLogin,
    dialogRegister,
    dialogNone
} CurrentDialogType;

@interface SMSplashController () {
    BOOL loginInProcess;
    CurrentDialogType currentDialog;
}

@end


@implementation SMSplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    loginInProcess = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    currentDialog = dialogNone;
}

- (void)viewDidUnload {
    registerView = nil;
    loginView = nil;
    registerScroll = nil;
    nameField = nil;
    emailField = nil;
    passwordField = nil;
    passwordRepeatField = nil;
    registerDialog = nil;
    loginEmail = nil;
    loginPassword = nil;
    loginScroll = nil;
    loginDialog = nil;
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

- (IBAction)skipLogin:(id)sender {
    [self performSegueWithIdentifier:@"splashToMain" sender:nil];
}

- (IBAction)goToFavorites:(id)sender {
    [self performSegueWithIdentifier:@"splashToFavorites" sender:nil];
}

- (IBAction)showRegister:(id)sender {
    [nameField setText:@""];
    [emailField setText:@""];
    [passwordField setText:@""];
    [passwordRepeatField setText:@""];
    [UIView animateWithDuration:0.4f animations:^{
        [registerView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        currentDialog = dialogRegister;
    }];
}

- (IBAction)hideRegister:(id)sender {
    [registerScroll setContentOffset:CGPointZero];
    [nameField resignFirstResponder];
    [emailField resignFirstResponder];
    [passwordField resignFirstResponder];
    [passwordRepeatField resignFirstResponder];
    [UIView animateWithDuration:0.4f animations:^{
        [registerView setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [nameField setText:@""];
        [emailField setText:@""];
        [passwordField setText:@""];
        [passwordRepeatField setText:@""];
        currentDialog = dialogNone;
    }];
}

- (IBAction)showLogin:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [loginView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        [loginPassword setText:@""];
        [loginEmail setText:@""];
        currentDialog = dialogLogin;
    }];
}

- (IBAction)hideLogin:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [loginView setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [loginPassword setText:@""];
        [loginEmail setText:@""];
        currentDialog = dialogNone;
    }];

}

- (IBAction)loginToRegister:(id)sender {
    [UIView animateWithDuration:0.4f animations:^{
        [loginView setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [nameField setText:@""];
        [emailField setText:@""];
        [passwordField setText:@""];
        [passwordRepeatField setText:@""];
        [UIView animateWithDuration:0.4f animations:^{
            [registerView setAlpha:1.0f];
        } completion:^(BOOL finished) {
            currentDialog = dialogRegister;
        }];
    }];
}

- (IBAction)selectImageSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES){
        UIActionSheet * ac  = [[UIActionSheet alloc] initWithTitle:translateString(@"choose_image_source") delegate:self cancelButtonTitle:translateString(@"Cancel") destructiveButtonTitle:nil otherButtonTitles:translateString(@"image_source_camera"), translateString(@"image_source_library"), nil];
        [ac showInView:self.view];
    } else {
        [self takePictureFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)takePictureFromSource:(UIImagePickerControllerSourceType)src {
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:src] == YES){
        cameraUI.sourceType = src;
    }else{
        if (src == UIImagePickerControllerSourceTypeCamera) {
            cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else {
            cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
    }
    
    NSArray* tmpAlloc_NSArray = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    cameraUI.mediaTypes =  tmpAlloc_NSArray;
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentModalViewController: cameraUI animated: YES];
    }
}


- (IBAction)loginWithFB:(id)sender {
    
    @synchronized(self) {
        if (loginInProcess) {
            return;
        }
        loginInProcess = YES;
    }
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *facebookAccountType = [accountStore
                                          accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    // Specify App ID and permissions
    NSDictionary *options = @{
                              ACFacebookAppIdKey: FB_APP_ID,
                              ACFacebookPermissionsKey: @[@"email"],
                              ACFacebookAudienceKey: ACFacebookAudienceFriends
                              };
    
    [accountStore requestAccessToAccountsWithType:facebookAccountType options:options completion:^(BOOL granted, NSError *e) {
        if (granted) {
            NSArray *accounts = [accountStore
                                 accountsWithAccountType:facebookAccountType];
            ACAccount * facebookAccount = [accounts lastObject];
            
            ACAccountCredential *fbCredential = [facebookAccount credential];
            NSString *accessToken = [fbCredential oauthToken];
            NSLog(@"Facebook Access Token: %@", accessToken);
            
            SLRequest * me = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://graph.facebook.com/me"] parameters:@{}];
            me.account = facebookAccount;
            [me performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (error) {
                    /*
                     * handle request error
                     */
                } else {
                    
//                    NSString * str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSDictionary * d = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];//[[SBJsonParser new] objectWithString:str];
                    /*
                     * handle FB login
                     */
                    
                    [self skipLogin:nil];
                }
            }];
        } else {
            /*
             * permission not granted
             * try with traditional method
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginWithFacebook:sender];
            });
        }
    }];
}

- (IBAction)loginWithFacebook:(id)sender {
    SMAppDelegate * appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    if (!appDelegate.session || appDelegate.session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        appDelegate.session = [[FBSession alloc] initWithPermissions:@[@"email"]];
    }
    
    // if the session isn't open, let's open it now and present the login UX to the user
    [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                     FBSessionState status,
                                                     NSError *error) {
        [FBSession setActiveSession:session];
        if (appDelegate.session.isOpen) {
            [[FBRequest requestForMe] startWithCompletionHandler:
             ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                 if (!error) {
                     /*
                      * handle FB login
                      */
                    
                     [self skipLogin:nil];
                 }
             }];
            
        }
    }];
    
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag + 1;
    [textField resignFirstResponder];
    
    if (currentDialog == dialogRegister) {
        [[registerDialog viewWithTag:tag] becomeFirstResponder];
        if (tag == 104) {
            [registerScroll setContentOffset:CGPointZero];
            [self goToFavorites:nil];
        }   
    } else if (currentDialog == dialogLogin) {
        [[loginDialog viewWithTag:tag] becomeFirstResponder];
        if (tag == 104) {
            [loginScroll setContentOffset:CGPointZero];
            [self goToFavorites:nil];
        }
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (currentDialog == dialogRegister) {
        [registerScroll setContentOffset:CGPointMake(0.0f, textField.frame.origin.y - 110.0f)];
    } else if (currentDialog == dialogLogin) {
        [loginScroll setContentOffset:CGPointMake(0.0f, textField.frame.origin.y - 80.0f)];
    }
    return YES;
}

#pragma mark - imagepicker delegate

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    UIImage * imageToSave = [info objectForKey:UIImagePickerControllerOriginalImage];
}

#pragma mark - actin sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self takePictureFromSource:UIImagePickerControllerSourceTypeCamera];
            break;
        case 1:
            [self takePictureFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        default:
            break;
    }
}



@end
