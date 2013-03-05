//
//  SMGPSUtil.h
//  iBike
//
//  Created by Ivan Pavlovic on 05/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SMGPSUtil : NSObject

// Calculates distance between location C and path AB in meters.
double distanceFromLineInMeters(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B);

CLLocationCoordinate2D closestCoordinate(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B);

/**
 * Compares coordinates of two CLLocations - returnns true if they are the same
 */
BOOL sameCoordinates(CLLocation *loc1, CLLocation *loc2);
+ (double) bearingBetweenStartLocation:(CLLocation *)startLocation andEndLocation:(CLLocation *)endLocation;


@end
