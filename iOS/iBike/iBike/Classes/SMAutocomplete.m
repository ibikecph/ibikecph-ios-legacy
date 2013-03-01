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
    [self getFoursquareAutocomplete:str];
}

- (void)getOiorestAutocomplete:(NSString*)str {
    completeType = autocompleteOiorest;
    self.srchString = str;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@", str]]];
    debugLog(@"%@", req);
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn start];
}

- (void)getGooglePlacesAutocomplete:(NSString*)str {
    completeType = autocompletePlaces;
    self.srchString = str;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&sensor=false&key=%@&location=%f,%f&radius=%@&language=%@&types=geocode", str, GOOGLE_API_KEY, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, PLACES_SEARCH_RADIUS, PLACES_LANGUAGE]]];
    debugLog(@"%@", req);
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn start];
}

- (void)getGoogleQueryAutocomplete:(NSString*)str {
    completeType = autocompletePlaces;
    self.srchString = str;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/queryautocomplete/json?input=%@&sensor=false&key=%@&location=%f,%f&radius=%@&language=%@", str, GOOGLE_API_KEY, [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, PLACES_SEARCH_RADIUS, PLACES_LANGUAGE]]];
    debugLog(@"%@", req);
    self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    [self.conn start];
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

- (void)getFoursquareAutocomplete:(NSString*)str {
    completeType = autocompleteFoursquare;
    self.srchString = str;
    if (self.conn) {
        [self.conn cancel];
    }
    self.connData = [NSMutableData data];
    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, str, @"20130301"]]];
        debugLog(@"%@", req);
        self.conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
        [self.conn start];
    } else {
        if (self.delegate) {
            [self.delegate autocompleteEntriesFound:@[] forString:self.srchString];
        }
    }
}



@end
