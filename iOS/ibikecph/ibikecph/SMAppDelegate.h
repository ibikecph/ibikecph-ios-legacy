//
//  SMAppDelegate.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SMSearchHistory.h"

@interface SMAppDelegate : UIResponder <UIApplicationDelegate, SMSearchHistoryDelegate>

@property (strong, nonatomic) UIWindow *window;
@property BOOL fbLoggedIn;
@property (nonatomic, strong) FBSession *session;
@property (nonatomic, strong) FBRequestConnection * fbConnection;

@property (nonatomic, strong) NSArray * currentContacts;
@property (nonatomic, strong) NSArray * currentEvents;
@property (nonatomic, strong) NSArray * pastRoutes;
@property (nonatomic, strong) NSArray * searchHistory;

@property(nonatomic, strong) id<GAITracker> tracker;

@property (nonatomic, strong) NSMutableDictionary * appSettings;
- (BOOL)saveSettings;
- (void)loadSettings;

@end
