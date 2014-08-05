//
//  SMAccountController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 21/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAccountController.h"
#import <QuartzCore/QuartzCore.h>
#import "DAKeyboardControl.h"
#import "UIImage+Resize.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Base64.h"
#import "SMFavoritesUtil.h"

@interface SMAccountController () {
    
}
@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, strong) UIImage * profileImage;
@property (nonatomic, strong) NSDictionary * userData;
@end

@implementation SMAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
    hasChanged = NO;
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [scrlView setContentSize:scrlView.frame.size];
    
    /**
     * rounded corners for images
     */
    fbImage.layer.cornerRadius = 5;
    fbImage.layer.masksToBounds = YES;
    regularImage.layer.cornerRadius = 5;
    regularImage.layer.masksToBounds = YES;
    
    /**
     * decide which view we want to show
     */
    if ([self.appDelegate.appSettings objectForKey:@"loginType"] && [[self.appDelegate.appSettings objectForKey:@"loginType"] isEqualToString:@"FB"]) {
        /**
         * FB account type
         */
        [fbView setHidden:NO];
        [regularView setHidden:YES];
        [fbImage setImage:nil];
        [fbName setText:@""];
        SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
        [self setApr:ap];
        [self.apr setRequestIdentifier:@"getUserFB"];
        [self.apr showTransparentWaitingIndicatorInView:self.view];
        [self.apr executeRequest:@{@"service" : [NSString stringWithFormat:@"users/%@", [self.appDelegate.appSettings objectForKey:@"id"]], @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS} withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
        self.profileImage = nil;
    } else {
        /**
         * regular account type
         */
        [fbView setHidden:YES];
        [regularView setHidden:NO];
        SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
        [self setApr:ap];
        [self.apr setRequestIdentifier:@"getUser"];
        [self.apr showTransparentWaitingIndicatorInView:self.view];
        [self.apr executeRequest:@{@"service" : [NSString stringWithFormat:@"users/%@", [self.appDelegate.appSettings objectForKey:@"id"]], @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS} withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
        self.profileImage = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    fbImage = nil;
    fbName = nil;
    fbView = nil;
    regularView = nil;
    regularImage = nil;
    name = nil;
    email = nil;
    password = nil;
    passwordRepeat = nil;
    scrlView = nil;
    [super viewDidUnload];
}


#pragma mark - button actions

- (void)inputKeyboardWillHide:(NSNotification *)notification {
    [scrlView setContentOffset:CGPointZero];
}


- (IBAction)goBack:(id)sender {
    
    if (([name.text isEqualToString:[self.userData objectForKey:@"name"]] == NO) || ([email.text isEqualToString:[self.userData objectForKey:@"email"]] == NO) || ([password.text isEqualToString:[self.userData objectForKey:@"password"]] == NO) || ([passwordRepeat.text isEqualToString:[self.userData objectForKey:@"repeatPassword"]] == NO)) {
        hasChanged = YES;
    }
    if (hasChanged && [self.appDelegate.appSettings objectForKey:@"loginType"] && [[self.appDelegate.appSettings objectForKey:@"loginType"] isEqualToString:@"FB"] == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"account_not_saved") delegate:self cancelButtonTitle:translateString(@"account_cancel") otherButtonTitles:translateString(@"account_dont_save"), nil];
        [av setTag:100];
        [av show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];        
    }
}

- (IBAction)saveChanges:(id)sender {
    if ([password.text isEqualToString:passwordRepeat.text] == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"register_error_passwords") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSMutableDictionary * user = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"name": name.text,
                                  @"email": email.text
                                  }];
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:@{
                               @"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"],
                               @"id": [self.appDelegate.appSettings objectForKey:@"id"],
                               @"user" : user
                               }];
    
    if (self.profileImage) {
        [[params objectForKey:@"user"] setValue:@{
         @"file" : [UIImageJPEGRepresentation(self.profileImage, 1.0f) base64EncodedString],
         @"original_filename" : @"image.jpg",
         @"filename" : @"image.jpg"
         } forKey:@"image_path"];
    }
    
    if ([password.text isEqualToString:@""] == NO) {
        [[params objectForKey:@"user"] setValue:password.text forKey:@"password"];
        [[params objectForKey:@"user"] setValue:password.text forKey:@"password_confirmation"];
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"updateUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_CHANGE_USER_DATA withParams:params];
}

- (IBAction)changeImage:(id)sender {
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

- (IBAction)deleteAccount:(id)sender {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"delete_account_title") message:translateString(@"delete_account_text") delegate:self cancelButtonTitle:translateString(@"Cancel") otherButtonTitles:translateString(@"Delete"), nil];
    [av setTag:101];
    [av show];

}

- (void)deleteAccountConfirmed {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"deleteUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    NSMutableDictionary * params = [API_DELETE_USER_DATA mutableCopy];
    [params setValue:[NSString stringWithFormat:@"%@/%@", [params objectForKey:@"service"], [self.appDelegate.appSettings objectForKey:@"id"]] forKey:@"service"];
    [self.apr executeRequest:params withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
}

- (IBAction)logout:(id)sender {
    [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
    [self.appDelegate.appSettings removeObjectForKey:@"id"];
    [self.appDelegate.appSettings removeObjectForKey:@"username"];
    [self.appDelegate.appSettings removeObjectForKey:@"password"];
    [self.appDelegate saveSettings];
    [self goBack:nil];
}

#pragma mark - textview delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    [textField resignFirstResponder];
    [[scrlView viewWithTag:nextTag] becomeFirstResponder];
    if (nextTag == 105) {
        [scrlView setContentOffset:CGPointZero];
        [self saveChanges:nil];
    }
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0.0f, MAX(textField.frame.origin.y + 260.0f - scrlView.frame.size.height, 0.0f))];
    return YES;
}

#pragma mark - api request

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"getUser"]) {
            [name setText:[[result objectForKey:@"data"] objectForKey:@"name"]];
            [email setText:[[result objectForKey:@"data"] objectForKey:@"email"]];
            [regularImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[result objectForKey:@"data"] objectForKey:@"image_url"]]] scale:[[UIScreen mainScreen] scale]]];
            self.userData = @{@"name" : name.text, @"email" : email.text, @"password" : @"", @"repeatPassword" : @"", @"image" : regularImage.image?regularImage.image:[[UIImage alloc] init]};
        } else if ([req.requestIdentifier isEqualToString:@"getUserFB"]) {
                [fbName setText:[[result objectForKey:@"data"] objectForKey:@"name"]];
                [fbImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[result objectForKey:@"data"] objectForKey:@"image_url"]]] scale:[[UIScreen mainScreen] scale]]];
        } else if ([req.requestIdentifier isEqualToString:@"updateUser"]) {
            debugLog(@"User updated!!!");
            hasChanged = NO;
            self.userData = @{@"name" : name.text, @"email" : email.text, @"password" : @"", @"repeatPassword" : @"", @"image" : regularImage.image?regularImage.image:[[UIImage alloc] init]};
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Data" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            self.profileImage = nil;
        } else if ([req.requestIdentifier isEqualToString:@"changePassword"]) {
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Password" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Password changed!!!");
        } else if ([req.requestIdentifier isEqualToString:@"deleteUser"]) {
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Delete" withLabel:@"" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Account deleted!!!");
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"account_deleted") message:@"" delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
            [self.appDelegate.appSettings removeObjectForKey:@"id"];
            [self.appDelegate.appSettings removeObjectForKey:@"username"];
            [self.appDelegate.appSettings removeObjectForKey:@"password"];
            [self.appDelegate saveSettings];
            
            [fbImage setImage:nil];
            [fbName setText:@""];
            self.profileImage = nil;
            [regularImage setImage:nil];
            [name setText:@""];
            [email setText:@""];
            [password setText:@""];
            [passwordRepeat setText:@""];
    
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            /**
             * regular account type
             */
            [fbView setHidden:YES];
            [regularView setHidden:NO];

            [SMFavoritesUtil saveFavorites:@[]];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];        
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

#pragma mark - imagepicker delegate

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    self.profileImage = [[info objectForKey:UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    [regularImage setImage:self.profileImage];
    hasChanged = YES;
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

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        switch (buttonIndex) {
            case 1:
                [self deleteAccountConfirmed];
                break;
                
            default:
                break;
        }
    } else if (alertView.tag == 100) {
        switch (buttonIndex) {
            case 1:
                [self.navigationController popViewControllerAnimated:YES];
                break;
                
            default:
                break;
        }    
    }
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
