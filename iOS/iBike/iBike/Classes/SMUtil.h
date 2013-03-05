//
//  SMUtil.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMUtil : NSObject


// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float distance);
// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds);
// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate);
// Calculate how many calories are burned given speed and time spent cycling
float caloriesBurned(float avgSpeed, float timeSpent);

NSString *formatTimeLeft(NSInteger seconds);

/**
 * creates filename from current timestamp
 */
+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext;

+ (NSArray*)getSearchHistory;
+ (BOOL)saveToSearchHistory:(NSDictionary*)dict;

@end
