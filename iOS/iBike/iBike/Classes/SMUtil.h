//
//  SMUtil.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMUtil : NSObject

// Calculates distance between location C and path AB in meters.
double distanceFromPathInMeters(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B);

// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float distance);
// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds);
// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate);
// Calculate how many calories are burned given speed and time spent cycling
float caloriesBurned(float avgSpeed, float timeSpent);

/**
 * creates filename from current timestamp
 */
+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext;

/**
 * Compares coordinates of two CLLocations - returnns true if they are the same
 */
BOOL sameCoordinates(CLLocation *loc1, CLLocation *loc2);

@end
