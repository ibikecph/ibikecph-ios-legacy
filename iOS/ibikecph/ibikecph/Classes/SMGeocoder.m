//
//  SMGeocoder.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMGeocoder.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "SMLocationManager.h"


@implementation SMGeocoder

+ (void)geocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    if (USE_APPLE_GEOCODER) {
        [SMGeocoder appleGeocode:str completionHandler:handler];
    } else {
        [SMGeocoder oiorestGeocode:str completionHandler:handler];
    }
}

+ (void)oiorestGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler{
    NSString * s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@", [str urlEncode]];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError *error) {
        
        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        if (error) {
            handler(@[], error);
        } else if ([(NSArray*)res count] == 0) {
            handler(@[], [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
        } else {
            NSMutableArray * arr = [NSMutableArray array];
            for (NSDictionary * d in (NSArray*) res) {
                NSDictionary * dict = @{
                                        (NSString *)kABPersonAddressStreetKey : [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]],
                                        (NSString *)kABPersonAddressZIPKey : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                                        (NSString *)kABPersonAddressCityKey : [[d objectForKey:@"kommune"] objectForKey:@"navn"],
                                        (NSString *)kABPersonAddressCountryKey : @"Denmark"
                                        };
                MKPlacemark * pl = [[MKPlacemark alloc]
                                    initWithCoordinate:CLLocationCoordinate2DMake([[[d objectForKey:@"wgs84koordinat"] objectForKey:@"bredde"] doubleValue], [[[d objectForKey:@"wgs84koordinat"] objectForKey:@"længde"] doubleValue])
                                    addressDictionary:dict];
                [arr addObject:pl];
            }
            handler(arr, nil);
        }
    }];
}

+ (void)appleGeocode:(NSString*)str completionHandler:(void (^)(NSArray* placemarks, NSError* error)) handler {
    CLGeocoder * cl = [[CLGeocoder alloc] init];
    [cl geocodeAddressString:str completionHandler:^(NSArray *placemarks, NSError *error) {
        NSMutableArray * ret = [NSMutableArray array];
        for (CLPlacemark * pl in placemarks) {
            if ([SMLocationManager instance].hasValidLocation) {
                if ([pl.location distanceFromLocation:[SMLocationManager instance].lastValidLocation] <= GEOCODING_SEARCH_RADIUS) {
                    [ret addObject:[[MKPlacemark alloc] initWithPlacemark:pl]];
                }
            } else {
                [ret addObject:[[MKPlacemark alloc] initWithPlacemark:pl]];
            }
        }
        handler(ret, error);
    }];
}

+ (void)appleReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
    CLGeocoder * cl = [[CLGeocoder alloc] init];
    [cl reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        NSString * title = @"";
        NSString * subtitle = @"";
        NSMutableArray * arr = [NSMutableArray array];
        if ([placemarks count] > 0) {
            MKPlacemark * d = [placemarks objectAtIndex:0];
            title = [NSString stringWithFormat:@"%@", [[d addressDictionary] objectForKey:@"Street"]?[[d addressDictionary] objectForKey:@"Street"]:@""];
            subtitle = [NSString stringWithFormat:@"%@ %@", [[d addressDictionary] objectForKey:@"ZIP"]?[[d addressDictionary] objectForKey:@"ZIP"]:@"", [[d addressDictionary] objectForKey:@"City"]?[[d addressDictionary] objectForKey:@"City"]:@""];
            for (MKPlacemark* d in placemarks) {
                [arr addObject:@{
                 @"street" : [[d addressDictionary] objectForKey:@"Street"]?[[d addressDictionary] objectForKey:@"Street"]:@"",
                 @"house_number" : @"",
                 @"zip" : [[d addressDictionary] objectForKey:@"ZIP"]?[[d addressDictionary] objectForKey:@"ZIP"]:@"",
                 @"city" : [[d addressDictionary] objectForKey:@"City"]?[[d addressDictionary] objectForKey:@"City"]:@""
                 }];
            }
        }
        handler(@{@"title" : title, @"subtitle" : subtitle, @"near": arr}, nil);
    }];
}


+ (void)oiorestReverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
    NSString * s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser/%f,%f,%@.json", coord.latitude, coord.longitude, OIOREST_SEARCH_RADIUS];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            handler(@{}, error);
        } else {
            if (data) {
                id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:data];
                if (res == nil) {
                    handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
                    return;
                }
                if ([res isKindOfClass:[NSArray class]] == NO) {
                    res = @[res];
                }
                NSMutableArray * arr = [NSMutableArray array];
                NSString * title = @"";
                NSString * subtitle = @"";
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
                 handler(@{@"title" : title, @"subtitle" : subtitle, @"near": arr}, nil);
            } else {
                handler(@{}, [NSError errorWithDomain:NSOSStatusErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : @"Wrong data returned from the OIOREST"}]);
            }
        }
    }];
}

+ (void)reverseGeocode:(CLLocationCoordinate2D)coord completionHandler:(void (^)(NSDictionary * response, NSError* error)) handler {
//    if (USE_APPLE_GEOCODER) {
//        [SMGeocoder appleReverseGeocode:coord completionHandler:handler];
//    } else {
        [SMGeocoder oiorestReverseGeocode:coord completionHandler:handler];
//    }
}

@end
