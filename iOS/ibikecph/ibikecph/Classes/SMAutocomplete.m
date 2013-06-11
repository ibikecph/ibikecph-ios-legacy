//
//  SMAutocomplete.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAutocomplete.h"
#import "SMLocationManager.h"
#import "NSString+Relevance.h"
#import "SMUtil.h"

typedef enum {
    autocompleteOiorest,
    autocompleteFoursquare,
    autocompleteKortforsyningen
} AutocompleteType;

@interface SMAutocomplete() {
    AutocompleteType completeType;
}
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
//    [self getFoursquareAutocomplete];
//    [self getOiorestAutocomplete];
    [self getKortforsyningenAutocomplete];
}

- (void)getOiorestAutocomplete {
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://geo.oiorest.dk/adresser.json?q=%@&maxantal=50", [self.srchString urlEncode]]]];
    debugLog(@"%@", req);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (data) {
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
                     @"relevance" : [NSNumber numberWithInteger:[SMUtil pointsForName:[NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]] andAddress:[NSString stringWithFormat:@"%@ %@, %@ %@, Danmark", [[d objectForKey:@"vejnavn"] objectForKey:@"navn"], [d objectForKey:@"husnr"], [[d objectForKey:@"postnummer"] objectForKey:@"nr"], [[d objectForKey:@"kommune"] objectForKey:@"navn"]] andTerms:self.srchString]],
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
        }
    }];
}

- (void)getFoursquareAutocomplete {
    completeType = autocompleteFoursquare;
    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/suggestcompletion?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
//        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%f,%f&client_id=%@&client_secret=%@&query=%@&v=%@&radius=%@", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude, FOURSQUARE_ID, FOURSQUARE_SECRET, [[self.srchString removeAccents] urlEncode], @"20130301", FOURSQUARE_SEARCH_RADIUS]]];
        debugLog(@"%@", req);
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
            if (data) {
                NSDictionary * res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                NSMutableArray * arr = [NSMutableArray array];
                
                for (NSDictionary* d in [[res objectForKey:@"response"] objectForKey:@"minivenues"]) {
                    if ([[d objectForKey:@"location"] objectForKey:@"lat"] && [[d objectForKey:@"location"] objectForKey:@"lng"]
                        && (([[[d objectForKey:@"location"] objectForKey:@"lat"] doubleValue] != 0) || ([[[d objectForKey:@"location"] objectForKey:@"lng"] doubleValue] != 0))) {
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
                            if ([[[[d objectForKey:@"location"] objectForKey:@"address"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                                [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"address"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                            }
                        } else {
                            [dict setValue:@"" forKey:@"street"];
                        }
                        if ([[d objectForKey:@"location"] objectForKey:@"city"]) {
                            [dict setValue:[[d objectForKey:@"location"] objectForKey:@"city"] forKey:@"city"];
                            if ([[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                                [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                            }
                        } else {
                            [dict setValue:@"" forKey:@"city"];
                        }
                        if ([[d objectForKey:@"location"] objectForKey:@"country"]) {
                            [dict setValue:[[d objectForKey:@"location"] objectForKey:@"country"] forKey:@"country"];
                            if ([[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                                [ar addObject:[[[d objectForKey:@"location"] objectForKey:@"country"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                            }
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
                        
                        [dict setObject:[NSNumber numberWithInteger:[SMUtil pointsForName:[dict objectForKey:@"name"] andAddress:[dict objectForKey:@"address"] andTerms:self.srchString]] forKey:@"relevance"];
                        
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
            }
            
        }];
    } else {
        if (self.delegate) {
            [self.delegate autocompleteEntriesFound:@[] forString:self.srchString];
        }
    }
}

- (void)getKortforsyningenAutocomplete{
    NSString* nameKey= @"navn";
    NSString* zipKey= @"kode";
    NSString* distanceKey= @"afstand";
    completeType= autocompleteKortforsyningen;

    if ([SMLocationManager instance].hasValidLocation) {
        NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"http://kortforsyningen.kms.dk/?servicename=RestGeokeys&method=adresse&vejnavn=Ar*&husnr=1&geop=%lf,%lf&georef=EPSG:4326", [SMLocationManager instance].lastValidLocation.coordinate.latitude, [SMLocationManager instance].lastValidLocation.coordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error){

            NSError* jsonError;
                
            if ([data length] > 0 && error == nil){

                
                NSDictionary* json= [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];

                NSLog(@"Received data %@", json);
                NSMutableDictionary * val = [NSMutableDictionary dictionaryWithDictionary: @{@"source" : @"autocomplete",
                                              @"subsource" : @"Kortforsyningen",
                                              @"order" : @4
                                              }];
                NSMutableArray* addressArray= [NSMutableArray new];
                for (NSString* key in json.allKeys) {
                    if ([key isEqualToString:@"features"]) {
                        NSArray* features= [json objectForKey:key]; // array of features (dictionaries)
                        for(NSDictionary* feature in features){
                            NSDictionary* attributes=[feature objectForKey:@"attributes"];
                            NSDictionary* distanceInfo= [attributes objectForKey:distanceKey];
                            NSDictionary* info= [attributes objectForKey:@"vej"];
                            
                            [val setObject:[info objectForKey:nameKey] forKey:@"name"];
                            [val setObject:[info objectForKey:zipKey] forKey:@"zip"];
                            [val setObject:[distanceInfo objectForKey:distanceKey] forKey:@"distance"];
                            [addressArray addObject:val];
                        }
                        
                    }
                }
                
                [addressArray sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2){
                    long first= ((NSNumber*)[obj1 objectForKey:@"distance"]).longValue;
                    long second= ((NSNumber*)[obj2 objectForKey:@"distance"]).longValue;
                    
                    if(first<second)
                        return NSOrderedAscending;
                    else if(first>second)
                        return NSOrderedDescending;
                    else
                        return NSOrderedSame;
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(self.resultsArr) {
                        [self.resultsArr addObjectsFromArray:addressArray];
                        [self.resultsArr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                            return [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
                        }];
                    }
                    if (self.delegate) {
                        [self.delegate autocompleteEntriesFound:self.resultsArr forString:self.srchString];
                    }
                });

            }else if ([data length] == 0 && error == nil)
                NSLog(@"Empty reply");
            else if (error != nil && error.code == NSURLErrorTimedOut)
                NSLog(@"Timed out");
            else if (error != nil){
                NSLog(@"Error %@",jsonError.localizedDescription);
            }

        } ];
    }else{
        
    }
}


@end
