//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 11/05/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMRegisterController.h"
#import "DAKeyboardControl.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMUtil.h"
#import "SMAppDelegate.h"
#import "UIImage+Resize.h"
#import "Base64.h"

@interface SMRegisterController ()
@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, strong) UIImage * profileImage;
@end

@implementation SMRegisterController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    registerImage.layer.cornerRadius = 5;
    registerImage.layer.masksToBounds = YES;
    
    [scrlView setContentSize:CGSizeMake(320.0f, 410.0f)];
    
    UIScrollView * scr = scrlView;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        CGRect frame = scr.frame;
        frame.size.height = keyboardFrameInView.origin.y;
        scr.frame = frame;
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view removeKeyboardControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    scrlView = nil;
    registerName = nil;
    registerEmail = nil;
    registerPassword = nil;
    registerRepeatPassword = nil;
    registerImage = nil;
    [super viewDidUnload];
}

#pragma mark - button actions

- (IBAction)doRegister:(id)sender {
    [registerEmail resignFirstResponder];
    [registerPassword resignFirstResponder];
    [registerRepeatPassword resignFirstResponder];
    [registerName resignFirstResponder];
    [scrlView setContentOffset:CGPointZero animated:YES];
    
    if([SMUtil validateRegistrationName:registerName.text Email:registerEmail.text Password:registerPassword.text AndRepeatedPassword:registerRepeatPassword.text] != RVR_REGISTRATION_DATA_VALID){
        return;
    }
    
    NSMutableDictionary * user = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"name": registerName.text,
                                  @"email": registerEmail.text,
                                  @"email_confirmation": registerEmail.text,
                                  @"password": registerPassword.text,
                                  @"password_confirmation": registerRepeatPassword.text,
                                  @"account_source" : ORG_NAME
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
    
    if ([registerPassword.text isEqualToString:@""] == NO) {
        [[params objectForKey:@"user"] setValue:registerPassword.text forKey:@"password"];
        [[params objectForKey:@"user"] setValue:registerPassword.text forKey:@"password_confirmation"];
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"register"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_REGISTER withParams:params];
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


- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - api delegate

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

-(void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"register"]) {
//            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
//            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
//            [self.appDelegate.appSettings setValue:registerEmail.text forKey:@"username"];
//            [self.appDelegate.appSettings setValue:registerPassword.text forKey:@"password"];
//            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
//            [self.appDelegate saveSettings];
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"" message:translateString(@"register_successful") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            [self goBack:nil];
            if (![SMAnalytics trackEventWithCategory:@"Register" withAction:@"Completed" withLabel:registerEmail.text withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag + 1;
    [textField resignFirstResponder];
    [[scrlView viewWithTag:tag] becomeFirstResponder];
    if (tag == 105) {
        [scrlView setContentOffset:CGPointZero];
        [self doRegister:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0.0f, MAX(0.0f,textField.frame.origin.y - 116.0f))];
    return YES;
}

#pragma mark - imagepicker delegate

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    self.profileImage = [[info objectForKey:UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    [registerImage setImage:self.profileImage];
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

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
