//
//  SMRequestOSRM.h
//  iBike
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SMRequestOSRM;

@protocol SMRequestOSRMDelegate <NSObject>

- (void)request:(SMRequestOSRM*)req finishedWithResult:(id)res;
- (void)request:(SMRequestOSRM*)req failedWithError:(NSError*)error;

@end

@interface SMRequestOSRM : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<SMRequestOSRMDelegate> delegate;
@property (nonatomic, strong) CLLocation * coord;
@property (nonatomic, strong) NSString * requestIdentifier;
@property (nonatomic, strong) id auxParam;
@property (nonatomic, strong) NSMutableData * responseData;

- (id)initWithDelegate:(id<SMRequestOSRMDelegate>)dlg;

- (void)findNearestPointForLocation:(CLLocation*)loc;
- (void)getRouteFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end via:(NSArray *)viaPoints;
- (void)findNearestPointForStart:(CLLocation*)start andEnd:(CLLocation*)end;

@end
