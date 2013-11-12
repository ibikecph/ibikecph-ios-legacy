//
//  SMAnalytics.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAnalytics.h"

@implementation SMAnalytics

+ (BOOL)trackEventWithCategory:(NSString*)category withAction:(NSString*)action withLabel:(NSString*)label withValue:(NSInteger)value {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder
                                                createEventWithCategory:category
                                                action:action
                                                label:label
                                                value:[NSNumber numberWithInteger:value]]
                                               build]];
    return YES;
}

+ (BOOL)trackTimingWithCategory:(NSString*)category withValue:(NSTimeInterval)time withName:(NSString*)name withLabel:(NSString*)label {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder
                                                createTimingWithCategory:category
                                                interval:[NSNumber numberWithDouble:time]
                                                name:name
                                                label:label]
                                               build]];
    return YES;
}

+ (BOOL)trackSocial:(NSString*)social withAction:(NSString*)action withTarget:(NSString*)url {
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder
                                                createSocialWithNetwork:social
                                                action:action
                                                target:url]
                                               build]];
    return YES;
}


@end
