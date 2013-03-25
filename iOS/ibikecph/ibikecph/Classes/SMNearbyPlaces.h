//
//  SMNerbyPlaces.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SMNearbyPlaces;

@protocol SMNearbyPlacesDelegate <NSObject>

- (void)nearbyPlaces:(SMNearbyPlaces*)owner foundLocations:(NSArray*)locations;

@end

@interface SMNearbyPlaces : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<SMNearbyPlacesDelegate> delegate;

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * subtitle;
@property (nonatomic, strong) CLLocation * coord;

- (id)initWithDelegate:(id<SMNearbyPlacesDelegate>)dlg;
- (void)findPlacesForLocation:(CLLocation*) loc;

@end
