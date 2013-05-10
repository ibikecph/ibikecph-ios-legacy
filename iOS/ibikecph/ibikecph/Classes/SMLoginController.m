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

- (IBAction)loginWithFacebook:(id)sender;
- (IBAction)doLogin:(id)sender;

@end

@implementation SMLoginController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {}];

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
//    [loginScroll setContentOffset:CGPointZero animated:YES];
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
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"fb_token": fbToken}}];
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
                     NSString *accessToken = appDelegate.session.accessToken;
                     
                     [self doFBLogin:accessToken];
                 } else {
                     UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"fb_login_error") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                     [av show];
                 }
             }];
            
        }
    }];
    
}

#pragma mark - api delegate

-(void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    [av show];
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
            if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Register" withAction:@"Completed" withLabel:loginEmail.text withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}


- (IBAction)loginWithMail:(id)sender {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Not implemented yet" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [av show];
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {

    return YES;
}

- (void)viewDidUnload {
    loginEmail = nil;
    loginPassword = nil;
    [super viewDidUnload];
}
@end
