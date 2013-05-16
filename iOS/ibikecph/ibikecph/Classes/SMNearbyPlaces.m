//
//  SMNerbyPlaces.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMNearbyPlaces.h"

@interface SMNearbyPlaces()
@property (nonatomic, strong) NSURLConnection * conn;
@property (nonatomic, strong) NSMutableData * responseData;
@end

@implementation SMNearbyPlaces

- (id)initWithDelegate:(id<SMNearbyPlacesDelegate>)dlg {
    self = [super init];
    if (self) {
        [self setDelegate:dlg];
        self.title = @"";
        self.subtitle = @"";
        self.coord = nil;
    }
    return self;
}

- (void)findPlacesForLocation:(CLLocation*) loc {
    self.coord = loc;
    NSString* s = [NSString stringWithFormat:@"http://geo.oiorest.dk/adresser/%f,%f,%@.json", loc.coordinate.latitude, loc.coordinate.longitude, OIOREST_SEARCH_RADIUS];
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    if (self.conn) {
        [self.conn cancel];
        self.conn = nil;
    }
    NSURLConnection * c = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
    self.conn = c;
    self.responseData = [NSMutableData data];
    [self.conn start];
}

#pragma mark - url connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([self.responseData length] > 0) {
//        NSString * str = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        id res = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:nil];//[[[SBJsonParser alloc] init] objectWithData:self.responseData];
        
        if (res == nil) {
            return;
        }
        
        if ([res isKindOfClass:[NSArray class]] == NO) {
            res = @[res];
        }
        
        NSMutableArray * arr = [NSMutableArray array];
        
        if ([(NSArray*)res count] > 0) {
            NSDictionary * d = [res objectAtIndex:0];
            self.title = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"]];
            self.subtitle = [NSString stringWithFormat:@"%@ %@", [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]];
        }
        for (NSDictionary* d in res) {
            [arr addObject:@{
             @"street" : [[d objectForKey:@"vejnavn"] objectForKey:@"navn"],
             @"house_number" : [d objectForKey:@"husnr"],
             @"zip" : [[d objectForKey:@"postnummer"] objectForKey:@"nr"],
             @"city" : [[d objectForKey:@"kommune"] objectForKey:@"navn"]
             }];
        }
        if ([self.delegate conformsToProtocol:@protocol(SMNearbyPlacesDelegate)]) {
            [self.delegate nearbyPlaces:self foundLocations:arr];
        }
    }
}

@end
