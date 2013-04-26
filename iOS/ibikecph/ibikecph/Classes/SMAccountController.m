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
@end

@implementation SMAccountController

- (void)viewDidLoad {
    [super viewDidLoad];
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [scrlView setContentSize:CGSizeMake(320.0f, 517.0f)];
    
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
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
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
    [self.navigationController popViewControllerAnimated:YES];
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
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"getUser"]) {
            [name setText:[[result objectForKey:@"data"] objectForKey:@"name"]];
            [email setText:[[result objectForKey:@"data"] objectForKey:@"email"]];
            [regularImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[result objectForKey:@"data"] objectForKey:@"image_url"]]]]];
        } else if ([req.requestIdentifier isEqualToString:@"getUserFB"]) {
                [fbName setText:[[result objectForKey:@"data"] objectForKey:@"name"]];
                [fbImage setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[result objectForKey:@"data"] objectForKey:@"image_url"]]]]];
        } else if ([req.requestIdentifier isEqualToString:@"updateUser"]) {
            debugLog(@"User updated!!!");
            if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Data" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            self.profileImage = nil;
        } else if ([req.requestIdentifier isEqualToString:@"changePassword"]) {
            if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Password" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Password changed!!!");
        } else if ([req.requestIdentifier isEqualToString:@"deleteUser"]) {
            if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Account" withAction:@"Delete" withLabel:@"" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Password changed!!!");
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"account_deleted") message:@"" delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
            [self.appDelegate.appSettings removeObjectForKey:@"id"];
            [self.appDelegate.appSettings removeObjectForKey:@"username"];
            [self.appDelegate.appSettings removeObjectForKey:@"password"];
            [self.appDelegate saveSettings];

            [SMFavoritesUtil saveFavorites:@[]];
            [self goBack:nil];
            return;
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];        
    }
}

#pragma mark - imagepicker delegate

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    self.profileImage = [[info objectForKey:UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    [regularImage setImage:self.profileImage];
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
    switch (buttonIndex) {
        case 1:
            [self deleteAccountConfirmed];
            break;
            
        default:
            break;
    }
}

@end
