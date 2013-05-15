//
//  SMEvents.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 28/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEvents.h"

#import <EventKit/EventKit.h>
#import "SMAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation SMEvents

- (void)getLocalEvents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addTime = [[NSDateComponents alloc] init];
    addTime.day = CALENDAR_MAX_DAYS;
    NSDate *toDate = [calendar dateByAddingComponents:addTime toDate:[NSDate date] options:0];
    
    EKEventStore * es = [[EKEventStore alloc] init];
    if ([es respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [es requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {                
                NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
                NSArray * arr = [es eventsMatchingPredicate:pred];
//                debugLog(@"Found events (iOS6): %@", arr);
                if (arr && self.delegate) {
                    NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
                    for (EKEvent * ek in arr) {
                        if (ek.location) {
                            NSString * title = @"";
                            NSString * location = @"";
                            NSDate * startDate = [NSDate date];
                            NSDate * endDate = [NSDate date];
                            
                            if (ek.title) {
                                title = ek.title;
                            }
                            location = ek.location;
                            if (ek.startDate) {
                                startDate = ek.startDate;
                                endDate = startDate;
                            }
                            if (ek.endDate) {
                                endDate = ek.endDate;
                            }
                            
                            [ret addObject:@{
                             @"name" : title,
                             @"address" : location,
                             @"startDate" : startDate,
                             @"endDate" : endDate,
                             @"source" : @"ios"
                             }];
                        }
                    }
                    [self.delegate localEventsFound:ret];
                }
            }
        }];
    } else {
        NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
        NSArray * arr = [es eventsMatchingPredicate:pred];
//        debugLog(@"Found events (iOS5): %@", arr);
        if (arr && self.delegate) {
            NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
            for (EKEvent * ek in arr) {
                if (ek.location) {
                    NSString * title = @"";
                    NSString * location = @"";
                    NSDate * startDate = [NSDate date];
                    NSDate * endDate = [NSDate date];
                    
                    if (ek.title) {
                        title = ek.title;
                    }
                    location = ek.location;
                    if (ek.startDate) {
                        startDate = ek.startDate;
                        endDate = startDate;
                    }
                    if (ek.endDate) {
                        endDate = ek.endDate;
                    }
                    
                    [ret addObject:@{
                     @"name" : title,
                     @"address" : location,
                     @"startDate" : startDate,
                     @"endDate" : endDate,
                     @"source" : @"ios"
                     }];
                }
            }
            [self.delegate localEventsFound:ret];
        }
    }
}

- (void)getFacebookEvents {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addTime = [[NSDateComponents alloc] init];
    addTime.day = CALENDAR_MAX_DAYS;
    NSDate *toDate = [calendar dateByAddingComponents:addTime toDate:[NSDate date] options:0];
    
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    if (!appd.session || !appd.session.isOpen) {
        appd.session = [[FBSession alloc] initWithPermissions:@[@"user_events", @"create_event"]];
        [appd.session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (status == FBSessionStateOpen) {
                appd.session = [FBSession activeSession];
//                debugLog(@"New session: %@ \n\n %@", [FBSession activeSession], appd.session.accessToken);
                appd.fbLoggedIn = YES;

                FBRequestConnection *connection = [FBRequestConnection new];
                FBRequest * req = [[FBRequest alloc] initWithSession:session graphPath:@"me/events" parameters:@{@"fields" : @"id,start_time,end_time,picture,name,location"} HTTPMethod:@"GET"];
                [connection addRequest:req completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (error) {
                        NSLog(@"Error fetching results from Facebook: %@", error);
                    } else {
                        debugLog(@"New session result: %@", result);
                        NSArray * arr = @[];
                        if ([(NSDictionary*)result objectForKey:@"data"] && [[(NSDictionary*)result objectForKey:@"data"] isKindOfClass:[NSArray class]]) {
                            arr = [(NSDictionary*)result objectForKey:@"data"];
                        }
                        if (arr && self.delegate) {
                            NSMutableArray * ret = [NSMutableArray array];
                            for (NSDictionary * ek in arr) {
                                if ([ek objectForKey:@"location"]) {
                                    NSString * title = @"";
                                    NSString * location = @"";
                                    NSDate * startDate = [NSDate date];
                                    NSDate * endDate = [NSDate date];
                                    NSString * picture = @"";
                                    
                                    if ([ek objectForKey:@"name"]) {
                                        title = [ek objectForKey:@"name"];
                                    }
                                    location = [ek objectForKey:@"location"];
                                    if ([ek objectForKey:@"start_time"]) {
                                        NSDateFormatter * df = [[NSDateFormatter alloc] init];
                                        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                                        NSDate * d = [df dateFromString:[ek objectForKey:@"start_time"]];
                                        startDate = d;
                                        endDate = d;
                                    }
                                    
                                    if ([ek objectForKey:@"end_time"]) {
                                        NSDateFormatter * df = [[NSDateFormatter alloc] init];
                                        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                                        NSDate * d = [df dateFromString:[ek objectForKey:@"end_time"]];
                                        endDate = d;
                                    }
                                    
                                    if ([[[ek objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]) {
                                        picture = [[[ek objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"];
                                    }
                                    
                                    if ([startDate compare:toDate] != NSOrderedDescending) {
                                        [ret addObject:@{
                                         @"id" : [ek objectForKey:@"id"],
                                         @"name" : title,
                                         @"address" : location,
                                         @"startDate" : startDate,
                                         @"endDate" : endDate,
                                         @"picture" : picture,
                                         @"source" : @"fb"
                                         }];   
                                    }
                                }
                            }
                            [self.delegate facebookEventsFound:ret];
                        }
                    }
                }];
                [connection start];
                [appd setFbConnection:connection];
            }
        }];
        
    } else {
        debugLog(@"Already active session: %@", [FBSession activeSession]);
        FBRequestConnection *connection = [FBRequestConnection new];
        FBRequest * req = [[FBRequest alloc] initWithSession:appd.session graphPath:@"me/events" parameters:@{@"fields" : @"id,start_time,end_time,picture,name,location"} HTTPMethod:@"GET"];
        [connection addRequest:req completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) {
                NSLog(@"Error fetching results from Facebook: %@", error);
            } else {
                debugLog(@"New session result: %@", result);
                NSArray * arr = @[];
                if ([(NSDictionary*)result objectForKey:@"data"] && [[(NSDictionary*)result objectForKey:@"data"] isKindOfClass:[NSArray class]]) {
                    arr = [(NSDictionary*)result objectForKey:@"data"];
                }
                if (self.delegate) {
                    NSMutableArray * ret = [NSMutableArray array];
                    for (NSDictionary * ek in arr) {
                        if ([ek objectForKey:@"location"]) {
                            NSString * title = @"";
                            NSString * location = @"";
                            NSDate * startDate = [NSDate date];
                            NSDate * endDate = [NSDate date];
                            NSString * picture = @"";
                            
                            if ([ek objectForKey:@"name"]) {
                                title = [ek objectForKey:@"name"];
                            }
                            location = [ek objectForKey:@"location"];
                            if ([ek objectForKey:@"start_time"]) {
                                NSDateFormatter * df = [[NSDateFormatter alloc] init];
                                [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                                NSDate * d = [df dateFromString:[ek objectForKey:@"start_time"]];
                                startDate = d;
                                endDate = d;
                            }
                            
                            if ([ek objectForKey:@"end_time"]) {
                                NSDateFormatter * df = [[NSDateFormatter alloc] init];
                                [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                                NSDate * d = [df dateFromString:[ek objectForKey:@"end_time"]];
                                endDate = d;
                            }
                            
                            if ([[[ek objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]) {
                                picture = [[[ek objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"];
                            }
                            if ([startDate compare:toDate] != NSOrderedDescending) {
                                [ret addObject:@{
                                 @"id" : [ek objectForKey:@"id"],
                                 @"name" : title,
                                 @"address" : location,
                                 @"startDate" : startDate,
                                 @"endDate" : endDate,
                                 @"picture" : picture,
                                 @"source" : @"fb"
                                 }];
                            }
                        }
                    }
                    [self.delegate facebookEventsFound:ret];
                }
            }
        }];
        [connection start];
        [appd setFbConnection:connection];
    }
}

- (void)getAllEvents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addTime = [[NSDateComponents alloc] init];
    addTime.day = CALENDAR_MAX_DAYS;
    NSDate *toDate = [calendar dateByAddingComponents:addTime toDate:[NSDate date] options:0];
    
    EKEventStore * es = [[EKEventStore alloc] init];
    if ([es respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [es requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
                NSArray * arr = [es eventsMatchingPredicate:pred];
                //                debugLog(@"Found events (iOS6): %@", arr);
                if (arr && self.delegate) {
                    NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
                    for (EKEvent * ek in arr) {
                        if (ek.location) {
                            NSString * title = @"";
                            NSString * location = @"";
                            NSDate * startDate = [NSDate date];
                            NSDate * endDate = [NSDate date];
                            
                            if (ek.title) {
                                title = ek.title;
                            }
                            location = ek.location;
                            if (ek.startDate) {
                                startDate = ek.startDate;
                                endDate = startDate;
                            }
                            if (ek.endDate) {
                                endDate = ek.endDate;
                            }
                            
                            [ret addObject:@{
                             @"name" : title,
                             @"address" : location,
                             @"startDate" : startDate,
                             @"endDate" : endDate,
                             @"source" : @"ios"
                             }];
                        }
                    }
                    [self.delegate localEventsFound:ret];
                    [self getFacebookEvents];
                }
            } else {
                [self getFacebookEvents];
            }
        }];
    } else {
        NSPredicate * pred = [es predicateForEventsWithStartDate:[NSDate date] endDate:toDate calendars:nil];
        NSArray * arr = [es eventsMatchingPredicate:pred];
        //        debugLog(@"Found events (iOS5): %@", arr);
        if (arr && self.delegate) {
            NSMutableArray * ret = [NSMutableArray arrayWithCapacity:[arr count]];
            for (EKEvent * ek in arr) {
                if (ek.location) {
                    NSString * title = @"";
                    NSString * location = @"";
                    NSDate * startDate = [NSDate date];
                    NSDate * endDate = [NSDate date];
                    
                    if (ek.title) {
                        title = ek.title;
                    }
                    location = ek.location;
                    if (ek.startDate) {
                        startDate = ek.startDate;
                        endDate = startDate;
                    }
                    if (ek.endDate) {
                        endDate = ek.endDate;
                    }
                    
                    [ret addObject:@{
                     @"name" : title,
                     @"address" : location,
                     @"startDate" : startDate,
                     @"endDate" : endDate,
                     @"source" : @"ios"
                     }];
                }
            }
            [self.delegate localEventsFound:ret];
            [self getFacebookEvents];
        }
    }
}

@end
