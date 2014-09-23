//
//  SMAnalytics.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Google analytics wrapper
 */
@interface SMAnalytics : NSObject

+ (BOOL)trackEventWithCategory:(NSString*)category withAction:(NSString*)action withLabel:(NSString*)label withValue:(NSInteger)value;
+ (BOOL)trackTimingWithCategory:(NSString*)category withValue:(NSTimeInterval)time withName:(NSString*)name withLabel:(NSString*)label;
+ (BOOL)trackSocial:(NSString*)social withAction:(NSString*)action withTarget:(NSString*)url;

@end
