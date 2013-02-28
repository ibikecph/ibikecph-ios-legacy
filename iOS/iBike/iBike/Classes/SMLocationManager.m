//
//  SMLocationManager.m
//  TestMap
//
//  Created by Ivan Pavlovic on 11/1/12.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "SBJson.h"

@implementation SMLocationManager

@synthesize hasValidLocation, lastValidLocation, locationServicesEnabled;

+ (SMLocationManager *)instance {
	static SMLocationManager *instance;
	
	if (instance == nil) {
		instance = [[SMLocationManager alloc] init];
	}
	
	return instance;
}

- (id)init {
	self = [super init];
	
	if (self != nil)
	{
		hasValidLocation = NO;
		locationManager = [[CLLocationManager alloc] init];
		
		BOOL enabled;
		/*if([locationManager respondsToSelector:@selector(locationServicesEnabled)]){
         enabled = [locationManager locationServicesEnabled];
         } else {
         enabled = locationManager.locationServicesEnabled;
         }*/
        
        enabled = [CLLocationManager locationServicesEnabled];
		
		if (enabled == YES)
		{
			locationManager.delegate = self;
			locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
			locationManager.distanceFilter = kCLDistanceFilterNone;
			[locationManager startUpdatingLocation];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopLocationService:)  name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLocationService:) name:UIApplicationWillEnterForegroundNotification object:nil];
		}
        locationServicesEnabled = YES;
	}
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	hasValidLocation = NO;
	lastValidLocation = nil;
	
	if (!signbit(newLocation.horizontalAccuracy)) {
		hasValidLocation = YES;
		lastValidLocation = newLocation;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPosition" object:nil];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError");
	if ([error domain] == kCLErrorDomain)
	{
		switch ([error code])
		{
			case kCLErrorDenied:
				[locationManager stopUpdatingLocation];
                locationServicesEnabled = NO;
                NSLog(@"Location services denied!");
				break;
			case kCLErrorLocationUnknown:
                NSLog(@"Location unknown!");
				break;
		}
	}
}

+ (CLLocationCoordinate2D)getNearest:(CLLocationCoordinate2D)coord {
    NSString *url = [NSString stringWithFormat:@"%@/nearest?loc=%g,%g", OSRM_SERVER, coord.latitude, coord.longitude];
    NSString *response = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil];
    NSDictionary * r = [[[SBJsonParser alloc] init] objectWithString:response];
    if ([r objectForKey:@"mapped_coordinate"] && [[r objectForKey:@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([[r objectForKey:@"mapped_coordinate"] count] > 1)) {
        return CLLocationCoordinate2DMake([[[r objectForKey:@"mapped_coordinate"] objectAtIndex:0] doubleValue], [[[r objectForKey:@"mapped_coordinate"] objectAtIndex:1] doubleValue]);
    } else {
        return coord;
    }
}

+ (NSDictionary*)reverseGeocode:(CLLocationCoordinate2D)coord {    
    NSMutableArray * arr = [NSMutableArray array];
    NSString * title = @"";
    NSString * subtitle = @"";
    NSString * s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser/%f,%f,%@.json", coord.latitude, coord.longitude, OIOREST_SEARCH_RADIUS];
    NSString * str = [NSString stringWithContentsOfURL:[NSURL URLWithString:s] encoding:NSUTF8StringEncoding error:nil];
    if (str) {
        id res = [[[SBJsonParser alloc] init] objectWithString:str];
        
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        
        if ([(NSArray*)res count] > 0) {
            NSDictionary * d = [res objectAtIndex:0];
            title = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]];
            subtitle = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]];
        }
        for (NSDictionary* d in res) {
            [arr addObject:@{
             @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
             @"house_number" : [d objectForKey:@"husnr"],
             @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
             @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"]
             }];
        }
    }
    return @{@"title" : title, @"subtitle" : subtitle, @"near": arr};
}

+ (NSDictionary*)nearbyPlaces:(CLLocationCoordinate2D)coord {
//    
    
    NSMutableArray * arr = [NSMutableArray array];
    NSString * title = @"";
    NSString * subtitle = @"";
    NSString * s = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%f&key=%@&sensor=false&radius=%@", coord.latitude, coord.longitude, GOOGLE_API_KEY, PLACES_SEARCH_RADIUS];
    NSString * str = [NSString stringWithContentsOfURL:[NSURL URLWithString:s] encoding:NSUTF8StringEncoding error:nil];
    if (str) {
        id res = [[[SBJsonParser alloc] init] objectWithString:str];
        
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        
        if ([(NSArray*)res count] > 0) {
            NSDictionary * d = [res objectAtIndex:0];
            title = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]];
            subtitle = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]];
        }
        for (NSDictionary* d in res) {
            [arr addObject:@{
             @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
             @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
             @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"]
             }];
        }
    }
    return @{@"title" : title, @"subtitle" : subtitle, @"near": arr};
    
}

#pragma mark  - location service


- (void)stopLocationService:(UIApplication *)application {
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        [locationManager stopUpdatingHeading];
    }
}


- (void)restartLocationService:(UIApplication *)application {
    if (locationManager != nil) {
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
    }
}

@end
