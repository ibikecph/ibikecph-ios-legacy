//
//  SMAddressParser.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAddressParser.h"

@implementation SMAddressParser

+ (BOOL)testNumber:(NSString*)string {
    NSRegularExpression * regex3 = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSRegularExpression * regex4 = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+[a-zA-Z]" options:NSRegularExpressionCaseInsensitive error:NULL];
    if (([string length] <= 3 && [regex3 numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])] > 0) || ([string length] == 4 && [regex4 numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])] > 0)) {
        return YES;
    }
    return NO;
}

+ (BOOL)testZip:(NSString*)string {
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+" options:NSRegularExpressionCaseInsensitive error:NULL];
    if ([string length] == 4 && [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])] > 0) {
        return YES;
    }
    return NO;
}

+ (NSDictionary*)parseStreetAndNumber:(NSString*)streetAndNumber {
    NSMutableArray * arr = [NSMutableArray arrayWithArray:[streetAndNumber componentsSeparatedByString:@" "]];
    if ([arr count] == 0) {
        return @{};
    }
    if ([arr count]> 1) {
        NSString * number = [arr lastObject];
        if ([self testNumber:number]) {
            [arr removeObject:number];
            return @{@"street" : [arr componentsJoinedByString:@" "],
                     @"number" : number
                     };
        }
    }
    return @{@"street" : streetAndNumber};
}

+ (NSDictionary*)parseZipAndCity:(NSString*)zipAndCity {
    NSMutableArray * arr = [NSMutableArray arrayWithArray:[zipAndCity componentsSeparatedByString:@" "]];
    if ([arr count] == 0) {
        return @{};
    }
    NSString * zip = nil;
    for (NSString * s in arr) {
        if ([self testZip:s]) {
            zip = s;
            break;
        }
    }
    
    if (zip) {
        if ([zip isEqualToString:[arr objectAtIndex:0]] || [zip isEqualToString:[arr lastObject]]) {
            [arr removeObject:zip];
            NSString * city = [arr componentsJoinedByString:@" "];
            if ([[city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
                return @{@"zip" : zip};
            } else {
                return @{@"zip" : zip, @"city" : city};
            }
        }
    }
    return @{@"city" : zipAndCity};
}


+ (NSDictionary*)parseAddress:(NSString*)addressString {
    NSMutableArray * arr = [NSMutableArray arrayWithArray:[addressString componentsSeparatedByString:@","]];
    /**
     * clean the strings by trimming them
     */
    if ([arr count] > 0) {
        for (int i = 0; i < [arr count]; i++) {
            [arr replaceObjectAtIndex:i withObject:[[arr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }
    /**
     * we first check if there is a "," that divides street address from the zip and city part
     */
    if ([arr count] > 1) {
        NSString * streetAndNumber = [[arr objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSDictionary* streetAddress = [self parseStreetAndNumber:streetAndNumber];
        
        if ([arr count] > 1) {
            [arr removeObjectAtIndex:0];
            for (int i = 0; i < [arr count]; i++) {
                [arr replaceObjectAtIndex:i withObject:[[arr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
            NSString * zipAndCity = [arr componentsJoinedByString:@" "];
            NSDictionary * zipCity = [self parseZipAndCity:zipAndCity];
            
            NSMutableDictionary * d = [NSMutableDictionary dictionaryWithDictionary:streetAddress];
            [d addEntriesFromDictionary:zipCity];
            return d;
        }
        
        return streetAddress;
    } else {
        NSMutableDictionary * addr = [NSMutableDictionary dictionary];
        /**
         * there are no commas; we must check the string manually
         * we start by separating them by " "
         */
        arr = [NSMutableArray arrayWithArray:[addressString componentsSeparatedByString:@" "]];
        /**
         * clean the strings by trimming them
         */
        if ([arr count] > 0) {
            for (int i = 0; i < [arr count]; i++) {
                [arr replaceObjectAtIndex:i withObject:[[arr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
        }
        NSString * number = nil;
        /**
         * first we try to find the house number because we know the street name is before it and zip and city are after it
         * giving us a nice way to divide the string
         */
        for (NSString * s in arr) {
            if ([self testNumber:s]) {
                number = s;
                break;
            }
        }
        if (number) {
            [addr setObject:number forKey:@"number"];
            NSUInteger ind = [arr indexOfObject:number];
            if (ind > 0) {
                NSMutableArray * a = [NSMutableArray array];
                for (int i = 0; i < ind; i++) {
                    [a addObject:[arr objectAtIndex:i]];
                }
                NSString * street = [a componentsJoinedByString:@" "];
                if ([[street stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [addr setObject:street forKey:@"street"];
                }
            }
            [arr removeObjectsInRange:NSMakeRange(0, ind + 1)];
            if ([arr count] > 0) {
                NSDictionary * d = [self parseZipAndCity:[arr componentsJoinedByString:@" "]];
                [addr addEntriesFromDictionary:d];
            }
        } else {
            /**
             * we couldn't find a house number; let's try with zip code
             * we must assume that the city name will follow the zip code;
             */
            NSString * zip = nil;
            for (NSString * s in arr) {
                if ([self testZip:s]) {
                    zip = s;
                    break;
                }
            }
            
            if (zip) {
               [addr setObject:zip forKey:@"zip"];
                NSUInteger ind = [arr indexOfObject:zip];
                if (ind > 0) {
                    NSMutableArray * a = [NSMutableArray array];
                    for (int i = 0; i < ind; i++) {
                        [a addObject:[arr objectAtIndex:i]];
                    }
                    NSString * street = [a componentsJoinedByString:@" "];
                    if ([[street stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                        [addr setObject:street forKey:@"street"];
                    }
                }
                [arr removeObjectsInRange:NSMakeRange(0, ind + 1)];
                NSString * city = [arr componentsJoinedByString:@" "];
                if ([[city stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
                    [addr setObject:city forKey:@"city"];
                }
            } else {
                /**
                 * there is no zip code or house number
                 * we assume that the user has just given us the street name
                 */
                return @{@"street" : addressString};
            }
        }
        return addr;
    }
    
    
    return @{};
}

+ (void)parseTest {
    NSArray * streets = @[
                          @"elledevej",
                          @"elledevej, kalundborg",
                          @"elledevej kalundborg",
                          @"elledevej, 4400",
                          @"elledevej 4400",
                          @"elledevej, 4400 kalundborg",
                          @"elledevej, kalundborg 4400",
                          @"elledevej 4400 kalundborg",
                          @"elledevej kalundborg 4400",
                          @"elledevej 999C",
                          @"elledevej 999C, kalundborg",
                          @"elledevej 999C kallundborg",
                          @"elledevej 999C, 4400",
                          @"elledevej 999C 4400",
                          @"elledevej 999C, 4400 kalundborg",
                          @"elledevej 999C, kalundborg 4400",
                          @"elledevej 999C 4400 kalundborg",
                          @"elledevej 999C kalundborg 4400",
                          @"Sonnerup Gade 35, 4060",
                          @"Sonnerup Gade 35, Kirke Sonnerup",
                          @"Sonnerup Gade 35, 4060 Kirke Sonnerup",
                          @"Sonnerup Gade 35 4060 Kirke Sonnerup",
                          @"Sonnerup Gade 35, Kirke Sonnerup",
                          @"Sonnerup Gade 35, Kirke Sonnerup 4060",
                          @"4400 kalundborg",
                          @"sonnerup gade 35, 4600, kalundborg, sjælland",
                          @"sonnerup gade, 44",
                          @"sonnerup gade, 44, 4400",
                          @"sonnerup gade 44, 4400, kalundborg",
                          @"sonnerup gade 44, kalundborg, 4400",
                          @"sonnerup gade, 44, kalundborg, 4400"
                          ];
    
    for (NSString * s in streets) {
        NSDictionary * d = [self parseAddress:s];
        NSLog(@"\nInput: %@\nResult: %@\n\n", s, d);
    }
}

@end
