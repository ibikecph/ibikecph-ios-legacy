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
                 @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
                 @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
                 @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"]
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
                     @"street" : [d objectForKey:@"description"],
                     @"zip" : @"",
                     @"city" : @""
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
        default:
            break;
    }
}

@end
