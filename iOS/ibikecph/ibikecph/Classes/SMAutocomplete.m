//
//  SMAutocomplete.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMAutocomplete.h"
#import "SBJson.h"
#import "SMLocationManager.h"

@interface SMAutocomplete()
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSMutableData * connData;
@property (nonatomic, weak) id<SMAutocompleteDelegate> delegate;
@property (nonatomic, strong) NSString * srchString;
@property (nonatomic, strong) NSMutableArray * resultsArr;
@end

@implementation SMAutocomplete

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg {
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
    }
    return self;
}

- (void)getAutocomplete:(NSString*)str {
    self.srchString = str;
    self.resultsArr = [NSMutableArray array];
    [self getFoursquareAutocomplete];
    [self getOiorestAutocomplete];
}

- (void)getOiorestRadiusAutocomplete {
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser/%f,%f,%@.json", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, OIOREST_SEARCH_RADIUS]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        NSArray * res = [[[SBJsonParser alloc] init] objectWithData:data];
        NSMutableArray * arr = [NSMutableArray array];
        for (NSDictionary* d in res) {
            NSString * name = [NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]];
            if ([name rangeOfString:self.srchString].location != NSNotFound) {
                [arr addObject:@{
                 @"name" : @"",
                 @"address" : name,
                 @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
                 @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                 @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"],
                 @"country" : @"",
                 @"source" : @"autocomplete",
                 @"subsource" : @"oiorest",
                 @"order" : @3
                 }];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            @synchronized(self.resultsArr) {
                [self.resultsArr addObjectsFromArray:arr];
                [self.resultsArr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                    return [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
                }];
                
            }
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
            }
        });
    }];
}

- (void)getOiorestAutocomplete {
//    completeType = autocompleteOiorest;
//    if (self.conn) {
//        [self.conn cancel];
//    }
//    self.connData = [NSMutableData data];
//    
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@", [self.srchString urlEncode]]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        NSArray * res = [[[SBJsonParser alloc] init] objectWithData:data];
        NSMutableArray * arr = [NSMutableArray array];
        for (NSDictionary* d in res) {
            if ([[[d objectForKey:@"postnummer"] objectForKey:@"nr"] integerValue] >= 1000 && [[[d objectForKey:@"postnummer"] objectForKey:@"nr"] integerValue] <= 2999) {
                [arr addObject:@{
                 @"name" : [NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]],
                 @"address" : [NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]],
                 @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
                 @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                 @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"],
                 @"country" : @"",
                 @"source" : @"autocomplete",
                 @"subsource" : @"oiorest",
                 @"order" : @3
                 }];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            @synchronized(self.resultsArr) {
                [self.resultsArr addObjectsFromArray:arr];
                [self.resultsArr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                    return [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
                }];
                
            }
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
            }
        });
    }];
//    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
//    [self.conn start];
}

- (void)getGooglePlacesAutocomplete{
    completeType = autocompletePlaces;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&sensor=false&key=%@&location=%f,%f&radius=%@&language=%@&types=geocode", [self.srchString urlEncode], GOOGLE_API_KEY, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, PLACES_SEARCH_RADIUS, PLACES_LANGUAGE]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        NSDictionary * res = [[[SBJsonParser alloc] init] objectWithData:data];
        NSMutableArray * arr = [NSMutableArray array];
        if ([[res objectForKey:@"status"] isEqualToString:@"OK"]) {
            for (NSDictionary* d in [res objectForKey:@"predictions"]) {
                [arr addObject:@{
                 @"address" : [d objectForKey:@"description"],
                 @"name" : @"",
                 @"street" : [d objectForKey:@"description"],
                 @"zip" : @"",
                 @"city" : @"",
                 @"country" : @"",
                 @"source" : @"autocomplete",
                 @"subsource" : @"places",
                 @"order" : @2
                 }];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            @synchronized(self.resultsArr) {
                [self.resultsArr addObjectsFromArray:arr];
                [self.resultsArr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                    return [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
                }];
            }
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
            }
        });
    }];
    
//    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
//    [self.conn start];
}

- (void)getGoogleQueryAutocomplete{
    completeType = autocompletePlaces;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/queryautocomplete/json?input=%@&sensor=false&key=%@&location=%f,%f&radius=%@&language=%@", self.srchString, GOOGLE_API_KEY, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, PLACES_SEARCH_RADIUS, PLACES_LANGUAGE]]];
    debugLog(@"%@", req);
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn start];
}

- (void)getFoursquareAutocomplete {
    completeType = autocompleteFoursquare;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
        debugLog(@"%@", req);
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
            NSDictionary * res = [[[SBJsonParser alloc] init] objectWithData:data];
            NSMutableArray * arr = [NSMutableArray array];
            for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"venues"]) {
                NSMutableArray * ar = [NSMutableArray array];
                NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                              @"name" : [d objectForKey:@"name"],
                                              @"zip" : @"",
                                              @"lat" : [[d objectForKey:@"location"] objectForKey:@"lat"],
                                              @"long" : [[d objectForKey:@"location"] objectForKey:@"lng"],
                                              @"source" : @"autocomplete",
                                              @"subsource" : @"foursquare",
                                              @"order" : @1
                                              }];
                if ([d objectForKey:@"name"]) {
                    [dict setValue:[d objectForKey:@"name"] forKey:@"name"];
                } else {
                    [dict setValue:@"" forKey:@"name"];
                }
                
                if ([[d objectForKey:@"location"] objectForKey:@"address"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"address"] forKey:@"street"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"address"]];
                } else {
                    [dict setValue:@"" forKey:@"street"];
                }
                if ([[d objectForKey:@"location"] objectForKey:@"city"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"city"] forKey:@"city"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"city"]];
                } else {
                    [dict setValue:@"" forKey:@"city"];
                }
                if ([[d objectForKey:@"location"] objectForKey:@"country"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"country"] forKey:@"country"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"country"]];
                } else {
                    [dict setValue:@"" forKey:@"country"];
                }
                
                if ([d objectForKey:@"categories"] && [[d objectForKey:@"categories"] count] > 0) {
                    NSDictionary * d2 = [[d objectForKey:@"categories"] objectAtIndex:0];
                    if ([d2 objectForKey:@"icon"]) {
                        NSString * s1 = [NSString stringWithFormat:@"%@%@", [[[d2 objectForKey:@"icon"] objectForKey:@"prefix"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]], [[d2 objectForKey:@"icon"] objectForKey:@"suffix"]];
                        [dict setObject:s1 forKey:@"icon"];
                    }
                    
                }
                
                
                [dict setObject:[ar componentsJoinedByString:@", "] forKey:@"address"];
                
                if ([[dict objectForKey:@"address"] rangeOfString:@"København"].location != NSNotFound
                    || [[dict objectForKey:@"address"] rangeOfString:@"Koebenhavn"].location != NSNotFound
                    || [[dict objectForKey:@"address"] rangeOfString:@"Kobenhavn"].location != NSNotFound
                    || [[dict objectForKey:@"address"] rangeOfString:@"Copenhagen"].location != NSNotFound
                    || [[dict objectForKey:@"address"] rangeOfString:@"Frederiksberg"].location != NSNotFound
                    || [[dict objectForKey:@"address"] rangeOfString:@"Valby"].location != NSNotFound
                    ) {
                    [arr addObject:dict];
                }
                
                [arr sortUsingComparator:^NSComparisonResult(NSDictionary * obj1, NSDictionary * obj2) {
                    double d1 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue] longitude:[[obj1 objectForKey:@"lat"] doubleValue]]];
                    double d2 = [[SMLocationManager instance].lastValidLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue] longitude:[[obj2 objectForKey:@"lat"] doubleValue]]];
                    if (d1 > d2) {
                        return NSOrderedDescending;
                    } else if (d1 < d2) {
                        return NSOrderedAscending;
                    } else {
                        return NSOrderedSame;
                    }
                }];
                
            
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                @synchronized(self.resultsArr) {
                    [self.resultsArr addObjectsFromArray:arr];
                    [self.resultsArr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                        return [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
                    }];
                }
                if (self.delegate) {
                    [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                }
            });
        }];
//        self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
//        [self.conn start];
    } else {
        if (self.delegate) {
            [self.delegate autocompleteEntriesFound:@[] forString:self.srchString];
        }
    }
}

#pragma mark - nsurlconnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.connData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    switch (completeType) {
        case autocompleteOiorest: {
            NSArray * res = [[[SBJsonParser alloc] init] objectWithData:self.connData];
            NSMutableArray * arr = [NSMutableArray array];
            for (NSDictionary* d in res) {
                [arr addObject:@{
                 @"name" : [d objectForKey:@"name"],
                 @"address" : [NSString stringWithFormat:@"%@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]],
                 @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
                 @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                 @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"],
                 @"country" : @"",
                 @"source" : @"autocomplete",
                 @"subsource" : @"oiorest"
                 }];
            }
            self.connData = [NSMutableData data];
            self.conn = nil;
            
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:arr forString:self.srchString];
            }
        }
            break;
        case autocompletePlaces: {
            NSDictionary * res = [[[SBJsonParser alloc] init] objectWithData:self.connData];
            NSMutableArray * arr = [NSMutableArray array];
            if ([[res objectForKey:@"status"] isEqualToString:@"OK"]) {
                for (NSDictionary* d in [res objectForKey:@"predictions"]) {
                    [arr addObject:@{
                     @"address" : [d objectForKey:@"description"],
                     @"name" : [d objectForKey:@"name"],
                     @"street" : [d objectForKey:@"description"],
                     @"zip" : @"",
                     @"city" : @"",
                     @"country" : @"",
                     @"source" : @"autocomplete",
                     @"subsource" : @"places"
                     }];
                }                
            }
            self.connData = [NSMutableData data];
            self.conn = nil;
            
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:arr forString:self.srchString];
            }

        }
            
            break;
        case autocompleteFoursquare: {
            NSDictionary * res = [[[SBJsonParser alloc] init] objectWithData:self.connData];
            NSMutableArray * arr = [NSMutableArray array];
            for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"venues"]) {
                NSMutableArray * ar = [NSMutableArray array];
                NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                              @"name" : [d objectForKey:@"name"],
                                              @"zip" : @"",
                                              @"lat" : [[d objectForKey:@"location"] objectForKey:@"lat"],
                                              @"long" : [[d objectForKey:@"location"] objectForKey:@"lng"],
                                              @"source" : @"autocomplete",
                                              @"subsource" : @"foursquare"
                                              }];
                if ([d objectForKey:@"name"]) {
                    [dict setValue:[d objectForKey:@"name"] forKey:@"name"];
                } else {
                    [dict setValue:@"" forKey:@"name"];
                }
                
                if ([[d objectForKey:@"location"] objectForKey:@"address"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"address"] forKey:@"street"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"address"]];
                } else {
                    [dict setValue:@"" forKey:@"street"];
                }
                if ([[d objectForKey:@"location"] objectForKey:@"city"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"city"] forKey:@"city"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"city"]];
                } else {
                    [dict setValue:@"" forKey:@"city"];
                }
                if ([[d objectForKey:@"location"] objectForKey:@"country"]) {
                    [dict setValue:[[d objectForKey:@"location"] objectForKey:@"country"] forKey:@"country"];
                    [ar addObject:[[d objectForKey:@"location"] objectForKey:@"country"]];
                } else {
                    [dict setValue:@"" forKey:@"country"];
                }
                
                if ([d objectForKey:@"categories"] && [[d objectForKey:@"categories"] count] > 0) {
                    NSDictionary * d2 = [[d objectForKey:@"categories"] objectAtIndex:0];
                    if ([d2 objectForKey:@"icon"]) {
                        NSString * s1 = [NSString stringWithFormat:@"%@%@", [[[d2 objectForKey:@"icon"] objectForKey:@"prefix"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]], [[d2 objectForKey:@"icon"] objectForKey:@"suffix"]];
                        [dict setObject:s1 forKey:@"icon"];
                    }
                    
                }
                
                
                [dict setObject:[ar componentsJoinedByString:@", "] forKey:@"address"];
                
                [arr addObject:dict];
            
            }
            self.connData = [NSMutableData data];
            self.conn = nil;
            if (self.delegate) {
                [self.delegate autocompleteEntriesFound:arr forString:self.srchString];
            }
            
        }
            
            break;
        default:
            break;
    }
}





@end
