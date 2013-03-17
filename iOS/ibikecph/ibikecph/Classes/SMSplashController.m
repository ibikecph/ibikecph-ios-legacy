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
#import "SBJson.h"
#import "SMAppDelegate.h"

@interface SMSplashController () {
    BOOL loginInProcess;
}

@end


@implementation SMSplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    loginInProcess = NO;
}

#pragma mark - button actions

- (IBAction)skipLogin:(id)sender {
    [self performSegueWithIdentifier:@"splashToMain" sender:nil];
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
                    NSString * str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSDictionary * d = [[SBJsonParser new] objectWithString:str];
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


@end
