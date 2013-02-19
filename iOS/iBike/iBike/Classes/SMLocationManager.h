//
//  SMLocationManager.h
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h> 
#import <CoreLocation/CoreLocation.h>

@interface SMLocationManager : NSObject<CLLocationManagerDelegate>
{
	CLLocationManager *locationManager;
	CLLocation *lastValidLocation;
	BOOL hasValidLocation;
    BOOL locationServicesEnabled;
}

@property (readonly, nonatomic) BOOL hasValidLocation;
@property (readonly, nonatomic) CLLocation *lastValidLocation;
@property BOOL locationServicesEnabled;


+ (SMLocationManager *)instance;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

+ (CLLocationCoordinate2D)getNearest:(CLLocationCoordinate2D)coord;
+ (NSDictionary*)reverseGeocode:(CLLocationCoordinate2D)coord;

@end
