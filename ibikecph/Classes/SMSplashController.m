//
//  SMSplashController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/03/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMSplashController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "SMAppDelegate.h"
#import "DAKeyboardControl.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMUtil.h"
#import "SMAppDelegate.h"
#import "UIImage+Resize.h"
#import "Base64.h"
#import "SMFavoritesUtil.h"

typedef enum {
    dialogLogin,
    dialogRegister,
    dialogNone
} CurrentDialogType;

@interface SMSplashController () {
    BOOL loginInProcess;
    CurrentDialogType currentDialog;
}

@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, strong) UIImage * profileImage;
@property (nonatomic, strong) SMFavoritesUtil * favfetch;
@property (nonatomic, strong) SMAPIRequest * locale;
@end


@implementation SMSplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    loginInProcess = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    currentDialog = dialogNone;
    [self.appDelegate loadSettings];
    
    /**
     * rounded corners for images
     */
    registerImage.layer.cornerRadius = 5;
    registerImage.layer.masksToBounds = YES;
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        SMSearchHistory * sh = [SMSearchHistory instance];
        [sh setDelegate:self.appDelegate];
        [sh fetchSearchHistoryFromServer];
        [[SMFavoritesUtil instance] fetchFavoritesFromServer];
    }    
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
    registerImage = nil;
    dialogView = nil;
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self skipLogin:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dialogView.transform = CGAffineTransformMakeScale(0.8f,0.8f);
    CGRect frame = dialogView.frame;
    frame.origin.y += 50.0f;
    [dialogView setFrame:frame];
    frame.origin.y -= 50.0f;
    dialogView.alpha = 0.0f;
    [UIView animateWithDuration:0.3f animations:^{
        dialogView.alpha = 1.0f;
        [dialogView setFrame:frame];
        dialogView.transform = CGAffineTransformMakeScale(1.0f,1.0f);
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

/**
 * Login with e-mail
 */
- (IBAction)doLogin:(id)sender {
    [loginEmail resignFirstResponder];
    [loginPassword resignFirstResponder];
    [loginScroll setContentOffset:CGPointZero animated:YES];
    if ([loginEmail.text isEqualToString:@""] || [loginPassword.text isEqualToString:@""]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"login_error_fields") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"login"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    self.apr.manualRemove = YES;
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"email": loginEmail.text, @"password": loginPassword.text}}];
}

/**
 * Login with facebook
 */
- (IBAction)doFBLogin:(NSString*)fbToken {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"loginFB"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    self.apr.manualRemove = YES;
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"fb_token": fbToken, @"account_source" : ORG_NAME}}];
}

/**
 * Registration
 */
- (IBAction)doRegister:(id)sender {
    [emailField resignFirstResponder];
    [passwordField resignFirstResponder];
    [passwordRepeatField resignFirstResponder];
    [nameField resignFirstResponder];
    [registerScroll setContentOffset:CGPointZero animated:YES];
    
    if([SMUtil validateRegistrationName:nameField.text Email:emailField.text Password:passwordField.text AndRepeatedPassword:passwordRepeatField.text] != RVR_REGISTRATION_DATA_VALID){
        return;
    }
        
    NSMutableDictionary * user = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"name": nameField.text,
                                  @"email": emailField.text,
                                  @"email_confirmation": emailField.text,
                                  @"password": passwordField.text,
                                  @"password_confirmation": passwordRepeatField.text,
                                  @"account_source": ORG_NAME
                                  }];
    
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"user" : user
                                    }];
    
    if (self.profileImage) {
        [[params objectForKey:@"user"] setValue:@{
         @"file" : [UIImageJPEGRepresentation(self.profileImage, 1.0f) base64EncodedString],
         @"original_filename" : @"image.jpg",
         @"filename" : @"image.jpg"
         } forKey:@"image_path"];
    }
    
    if ([passwordField.text isEqualToString:@""] == NO) {
        [[params objectForKey:@"user"] setValue:passwordField.text forKey:@"password"];
        [[params objectForKey:@"user"] setValue:passwordField.text forKey:@"password_confirmation"];
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"register"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_REGISTER withParams:params];
}


- (IBAction)skipLogin:(id)sender {
    [self performSegueWithIdentifier:@"splashToMain" sender:nil];
}

- (IBAction)goToFavorites:(id)sender {
    [self.apr hideWaitingView];
    if ([[SMFavoritesUtil getFavorites] count] > 0) {
        [self performSegueWithIdentifier:@"splashToMain" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"splashToFavorites" sender:nil];
    }
}

- (IBAction)showRegister:(id)sender {
    [nameField setText:@""];
    [emailField setText:@""];
    [passwordField setText:@""];
    [passwordRepeatField setText:@""];
    self.profileImage = nil;
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
        if (![SMAnalytics trackEventWithCategory:@"Register" withAction:@"Cancel" withLabel:loginEmail.text withValue:0]) {
            debugLog(@"error in trackEvent");
        }
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
            if (![SMAnalytics trackEventWithCategory:@"Register" withAction:@"Start" withLabel:loginEmail.text withValue:0]) {
                debugLog(@"error in trackEvent");
            }
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
    
    [self loginWithFacebook:nil];
    return;
    
    
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
            [self doFBLogin:accessToken];
            
//            SLRequest * me = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://graph.facebook.com/me"] parameters:@{}];
//            me.account = facebookAccount;
//            [me performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//                if (error) {
//                    /*
//                     * handle request error
//                     */
//                } else {
//                    
////                    NSString * str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
////                    NSDictionary * d = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];//[[SBJsonParser new] objectWithString:str];
//                    /*
//                     * handle FB login
//                     */
//                    
//                    [self doFBLogin:accessToken];
//                }
//            }];
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

- (void)getFBData {
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
             /*
              * handle FB login
              */
             SMAppDelegate * appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
             NSString *accessToken = appDelegate.session.accessTokenData.accessToken;


             [self doFBLogin:accessToken];
         } else {
             UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"fb_login_error") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
             [av show];
         }
     }];
}

- (IBAction)loginWithFacebook:(id)sender {
    SMAppDelegate * appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    if (!appDelegate.session) {
        // Create a new, logged out session.
        appDelegate.session = [[FBSession alloc] initWithPermissions:@[@"email"]];
    }
    if (appDelegate.session.state == FBSessionStateCreatedOpening) {
        appDelegate.session = [[FBSession alloc] initWithPermissions:@[@"email"]];
    }
    if (appDelegate.session.isOpen) {
        [self getFBData];
    } else {
        // if the session isn't open, let's open it now and present the login UX to the user
        [appDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                         FBSessionState status,
                                                         NSError *error) {
            [FBSession setActiveSession:session];
            SMAppDelegate * appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
            if (appDelegate.session.isOpen) {
                [self getFBData];
            }
        }];
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag + 1;
    [textField resignFirstResponder];
    
    if (currentDialog == dialogRegister) {
        [[registerDialog viewWithTag:tag] becomeFirstResponder];
        if (tag == 104) {
            [registerScroll setContentOffset:CGPointZero];
            [self doRegister:nil];
        }   
    } else if (currentDialog == dialogLogin) {
        [[loginDialog viewWithTag:tag] becomeFirstResponder];
        if (tag == 203) {
            [loginScroll setContentOffset:CGPointZero];
            [self doLogin:nil];
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
    self.profileImage = [[info objectForKey:UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    [registerImage setImage:self.profileImage forState:UIControlStateNormal];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - action sheet delegate

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


#pragma mark - api delegate 

-(void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
    [self.apr hideWaitingView];
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"login"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:loginEmail.text forKey:@"username"];
            [self.appDelegate.appSettings setValue:loginPassword.text forKey:@"password"];
            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self fetchFavs];
        } else if ([req.requestIdentifier isEqualToString:@"autoLogin"]) {
                [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
                [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
                [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
                [self.appDelegate saveSettings];
                [self fetchFavs];
        } else if ([req.requestIdentifier isEqualToString:@"loginFB"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:@"FB" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self fetchFavs];
        } else if ([req.requestIdentifier isEqualToString:@"register"]) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"" message:translateString(@"register_successful") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            [self hideRegister:nil];
            if (![SMAnalytics trackEventWithCategory:@"Register" withAction:@"Completed" withLabel:loginEmail.text withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
    } else {
        if ([result objectForKey:@"info_title"]) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:[result objectForKey:@"info_title"] message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        } else {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        }
        [req hideWaitingView];
    }
}

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}

#pragma mark - favorites delegate 

- (void)fetchFavs {
    SMFavoritesUtil * sh = [SMFavoritesUtil instance];
    [sh setDelegate:self];
    [self setFavfetch:sh];
    [self.favfetch fetchFavoritesFromServer];

}

- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data {
    [self.apr hideWaitingView];
    [self goToFavorites:nil];
}

- (void)favoritesOperation:(id)req failedWithError:(NSError *)error {
    [self.apr hideWaitingView];
    [self goToFavorites:nil];
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
