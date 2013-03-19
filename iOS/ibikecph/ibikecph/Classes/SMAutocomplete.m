//
//  SMAutocomplete.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMAutocomplete.h"
#import "SMLocationManager.h"
#import "NSString+Relevance.h"

typedef enum {
    autocompleteOiorest,
    autocompleteFoursquare
} AutocompleteType;

@interface SMAutocomplete() {
    AutocompleteType completeType;
}
@property (nonatomic, weak) id<SMAutocompleteDelegate> delegate;
@property (nonatomic, strong) NSString * srchString;
@property (nonatomic, strong) NSMutableArray * resultsArr;
@end

@implementation SMAutocomplete

#define POINTS_EXACT_NAME 20
#define POINTS_EXACT_ADDRESS 10
#define POINTS_PART_NAME 1
#define POINTS_PART_ADDRESS 1


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



- (NSInteger)pointsForName:(NSString*)name andAddress:(NSString*)address andTerms:(NSArray*)terms {
    NSString * srchString = [terms componentsJoinedByString:@" "];
    NSInteger total = 0;
    
    NSInteger points = [name numberOfOccurenciesOfString:srchString];
    if (points > 0) {
        total += points * POINTS_EXACT_NAME;
    } else {
        for (NSString * str in terms) {
            points = [name numberOfOccurenciesOfString:str];
            if (points > 0) {
                total += points * POINTS_PART_NAME;
            }
        }
    }

    
    points = [address numberOfOccurenciesOfString:srchString];
    if (points > 0) {
        total += points * POINTS_EXACT_ADDRESS;
    } else {
        for (NSString * str in terms) {
            points = [address numberOfOccurenciesOfString:str];
            if (points > 0) {
                total += points * POINTS_PART_NAME;
            }
        }
    }
    
    return total;
}

- (void)getOiorestAutocomplete {
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@", [self.srchString urlEncode]]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        NSDictionary * res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSMutableArray * arr = [NSMutableArray array];
        NSMutableArray * terms = [NSMutableArray array];
        for (NSString * str in [[self.srchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "]) {
            if ([terms indexOfObject:str] == NSNotFound) {
                [terms addObject:str];
            }
        }
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
                 @"relevance" : [NSNumber numberWithInteger:[self pointsForName:[NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]] andAddress:[NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]] andTerms:terms]],
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
}

- (void)getFoursquareAutocomplete {
    completeType = autocompleteFoursquare;
    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/suggestcompletion?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
//        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
        debugLog(@"%@", req);
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
            NSDictionary * res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSMutableArray * arr = [NSMutableArray array];
            NSMutableArray * terms = [NSMutableArray array];
            for (NSString * str in [[self.srchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "]) {
                if ([terms indexOfObject:str] == NSNotFound) {
                    [terms addObject:str];
                }
            }
            for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"minivenues"]) {
                NSMutableArray * ar = [NSMutableArray array];
                NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                              @"name" : [d objectForKey:@"name"],
                                              @"zip" : @"",
                                              @"lat" : [[d objectForKey:@"location"] objectForKey:@"lat"],
                                              @"long" : [[d objectForKey:@"location"] objectForKey:@"lng"],
                                              @"source" : @"autocomplete",
                                              @"subsource" : @"foursquare",
                                              @"order" : @3
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
                
                [dict setObject:[NSNumber numberWithInteger:[self pointsForName:[dict objectForKey:@"name"] andAddress:[dict objectForKey:@"address"] andTerms:terms]] forKey:@"relevance"];
                
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
    } else {
        if (self.delegate) {
            [self.delegate autocompleteEntriesFound:@[] forString:self.srchString];
        }
    }
}




@end
