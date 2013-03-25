//
//  SMAppDelegate.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAppDelegate.h"
#import "HockeySDK.h"
#import "SMUtil.h"


@interface SMAppDelegate(HockeyProtocols) <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate> {}
@property (nonatomic, strong) NSMutableDictionary * fbDict;
@end

@implementation SMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.pastRoutes = @[];
    self.currentContacts = @[];
    self.currentEvents = @[];
    self.searchHistory = [SMUtil getSearchHistory];
    
    /**
     * init default settings
     */
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defaults objectForKey:@"AppleLanguages"];
    NSDictionary *appDefaults;
    if ([[languages objectAtIndex:0] isEqualToString:@"da"] || [[languages objectAtIndex:0] isEqualToString:@"dan"]) {
        appDefaults = [NSDictionary dictionaryWithObject:@"dk" forKey:@"appLanguage"];
    } else {
        appDefaults = [NSDictionary dictionaryWithObject:@"en" forKey:@"appLanguage"];
    }
    [defaults registerDefaults:appDefaults];
    [defaults synchronize];
    
    /**
     * initialize Google Analytics
     */
    [GAI sharedInstance].debug = YES;
    [GAI sharedInstance].dispatchInterval = GOOGLE_ANALYTICS_DISPATCH_INTERVAL;
#ifdef TEST_VERSION
    [GAI sharedInstance].trackUncaughtExceptions = YES;
#endif
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_KEY];
    [[GAI sharedInstance] setDefaultTracker:self.tracker];
    [[GAI sharedInstance].defaultTracker setAnonymize:GOOGLE_ANALYTICS_ANONYMIZE];
    [[GAI sharedInstance].defaultTracker setSampleRate:GOOGLE_ANALYTICS_SAMPLE_RATE];
    [[GAI sharedInstance].defaultTracker setSessionTimeout:GOOGLE_ANALYTICS_SESSION_TIMEOUT];

    
    /**
     * hockey app crash reporting
     */
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:HOCKEYAPP_BETA_IDENTIFIER
                                                         liveIdentifier:HOCKEYAPP_LIVE_IDENTIFIER
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];

    
//#ifdef ENGLISH_VERSION
//    UIStoryboard *iPhone4Storyboard = [UIStoryboard storyboardWithName:@"EnglishStoryboard_iPhone" bundle:nil];
//#else
    UIStoryboard *iPhone4Storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//#endif

    SMTranslatedViewController *initialViewController = [iPhone4Storyboard instantiateInitialViewController];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController  = initialViewController;
    [self.window makeKeyAndVisible];
    
    
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.session close];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self.session handleOpenURL:url];
}

- (void) fbAuth {
    if (!self.session.isOpen) {
        self.session = [[FBSession alloc] initWithPermissions:[NSArray arrayWithObjects:@"publish_stream", @"status_update", nil]];
        [self.session openWithCompletionHandler:^(FBSession *session,
                                                  FBSessionState status,
                                                  NSError *error) {
            if (status == FBSessionStateOpen) {
                debugLog(@"New session: %@", [FBSession activeSession]);
                _fbLoggedIn = YES;
                
                FBRequestConnection *connection = [FBRequestConnection new];
                FBRequestHandler handler =
                ^(FBRequestConnection *connection, id result, NSError *error) {
                    [self showAlert:@"" result:result error:error];
                };
                
                FBRequest  * req = [[FBRequest alloc] initWithSession:self.session graphPath:@"me/feed" parameters:[NSDictionary dictionaryWithDictionary:self.fbDict] HTTPMethod:@"POST"];
                [connection addRequest:req completionHandler:handler];
                [connection start];
                [self setFbConnection:connection];
            }
        }];
        
    } else {
        debugLog(@"ALready active session: %@", [FBSession activeSession]);
        FBRequestConnection *connection = [FBRequestConnection new];
        FBRequestHandler handler =
        ^(FBRequestConnection *connection, id result, NSError *error) {
            [self showAlert:@"" result:result error:error];
        };
        FBRequest  * req = [[FBRequest alloc] initWithSession:self.session graphPath:@"me/feed" parameters:[NSDictionary dictionaryWithDictionary:self.fbDict] HTTPMethod:@"POST"];
        [connection addRequest:req completionHandler:handler];
        [connection start];
        [self setFbConnection:connection];
    }
}

- (void)fbGetEvents {
    if (!self.session.isOpen) {
        self.session = [[FBSession alloc] initWithPermissions:[NSArray arrayWithObjects:@"publish_stream", @"user_events", nil]];
        [self.session openWithCompletionHandler:^(FBSession *session,
                                                  FBSessionState status,
                                                  NSError *error) {
            if (status == FBSessionStateOpen) {
                debugLog(@"New session: %@", [FBSession activeSession]);
                _fbLoggedIn = YES;
                
                FBRequestConnection *connection = [FBRequestConnection new];
                FBRequestHandler handler =
                ^(FBRequestConnection *connection, id result, NSError *error) {
                    [self showAlert:@"" result:result error:error];
                };
                
                FBRequest  * req = [[FBRequest alloc] initWithSession:self.session graphPath:@"me/events" parameters:@{} HTTPMethod:@"POST"];
                [connection addRequest:req completionHandler:handler];
                [connection start];
                [self setFbConnection:connection];
            }
        }];
        
    } else {
        debugLog(@"Already active session: %@", [FBSession activeSession]);
        FBRequestConnection *connection = [FBRequestConnection new];
        FBRequestHandler handler =
        ^(FBRequestConnection *connection, id result, NSError *error) {
            [self showAlert:@"" result:result error:error];
        };
        FBRequest  * req = [[FBRequest alloc] initWithSession:self.session graphPath:@"me/events" parameters:@{} HTTPMethod:@"POST"];
        [connection addRequest:req completionHandler:handler];
        [connection start];
        [self setFbConnection:connection];
    }
}

- (void) postFbMessage:(NSMutableDictionary*) dict {
    [self setFbDict:[NSMutableDictionary dictionaryWithDictionary:dict]];
    [self fbAuth];
}

// UIAlertView helper for post buttons
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error {
    NSString *alertMsg;
    NSString *alertTitle;
    if (error) {
        alertMsg = error.localizedDescription;
        alertTitle = @"Facebook error";
    } else {
        alertMsg = @"Successfully posted!";
        alertTitle = @"";
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMsg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}



@end
