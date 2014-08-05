//
//  SMLoginController.m
//  I Bike CPH
//
//  Created by Rasko Gojkovic on 5/9/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMLoginController.h"
#import "DAKeyboardControl.h"

@interface SMLoginController ()
@property (nonatomic, strong) SMAPIRequest * apr;

//- (IBAction)loginWithFacebook:(id)sender;
//- (IBAction)doLogin:(id)sender;

@end

@implementation SMLoginController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self goBack:nil];
    } else {
        [scrlView setContentSize:CGSizeMake(320.0f, 410.0f)];
        
        UIScrollView * scr = scrlView;
        
        [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
            CGRect frame = scr.frame;
            frame.size.height = keyboardFrameInView.origin.y;
            scr.frame = frame;
        }];
    }
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

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - button actions

- (IBAction)doLogin:(id)sender {
    [loginEmail resignFirstResponder];
    [loginPassword resignFirstResponder];
    [scrlView setContentOffset:CGPointZero animated:YES];
    if ([loginEmail.text isEqualToString:@""] || [loginPassword.text isEqualToString:@""]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"login_error_fields") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"login"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"email": loginEmail.text, @"password": loginPassword.text}}];
}

- (IBAction)doFBLogin:(NSString*)fbToken {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"loginFB"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"fb_token": fbToken, @"account_source" : ORG_NAME}}];
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
        if ([req.requestIdentifier isEqualToString:@"login"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:loginEmail.text forKey:@"username"];
            [self.appDelegate.appSettings setValue:loginPassword.text forKey:@"password"];
            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self goBack:nil];
        } else if ([req.requestIdentifier isEqualToString:@"autoLogin"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self goBack:nil];
        } else if ([req.requestIdentifier isEqualToString:@"loginFB"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:@"FB" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self goBack:nil];
        } else if ([req.requestIdentifier isEqualToString:@"register"]) {
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
            [self.appDelegate saveSettings];
            [self goBack:nil];
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
    }
}


- (IBAction)loginWithMail:(id)sender {
    [self performSegueWithIdentifier:@"mainToRegister" sender:nil];
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag + 1;
    [textField resignFirstResponder];
    [[scrlView viewWithTag:tag] becomeFirstResponder];
    if (tag == 103) {
        [scrlView setContentOffset:CGPointZero];
        [self doLogin:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [scrlView setContentOffset:CGPointMake(0.0f, MAX(0.0f,textField.frame.origin.y - 82.0f))];
    return YES;
}

- (void)viewDidUnload {
    loginEmail = nil;
    loginPassword = nil;
    scrlView = nil;
    [super viewDidUnload];
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
