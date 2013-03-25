//
//  SMUtil.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
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
// Calculate expected arrival time
NSString *expectedArrivalTime(NSInteger seconds);

NSString *formatTimeLeft(NSInteger seconds);

/**
 * creates filename from current timestamp
 */
+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext;

+ (NSArray*)getSearchHistory;
+ (BOOL)saveToSearchHistory:(NSDictionary*)dict;

+ (NSMutableArray*)getFavorites;
+ (BOOL)saveToFavorites:(NSDictionary*)dict;
+ (BOOL)saveFavorites:(NSArray*)fav;

+ (NSInteger)pointsForName:(NSString*)name andAddress:(NSString*)address andTerms:(NSString*)srchString;

@end
