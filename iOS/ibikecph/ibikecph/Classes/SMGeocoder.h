//
//  SMGeocoder.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SMGeocoder : NSObject

/**
 * geocoding function that uses eithe Apple's or OIOREST geocoder
 */
+ (void)geocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;
+ (void)oiorestGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;
+ (void)appleGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler;

/**
 * reverse geocoding
 * currently only supports OIOREST
 */
+ (void)reverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler;
+ (void)oiorestReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler;

@end
