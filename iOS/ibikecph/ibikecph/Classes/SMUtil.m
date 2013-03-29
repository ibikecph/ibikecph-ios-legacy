//
//  SMUtil.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <math.h>
#import "SMUtil.h"
#import "SMAppDelegate.h"
#import "NSString+Relevance.h"



@implementation SMUtil

#define POINTS_EXACT_NAME 20
#define POINTS_EXACT_ADDRESS 10
#define POINTS_PART_NAME 1
#define POINTS_PART_ADDRESS 1

// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float meters) {
    if (meters < 5) {
        return @"";
    } else if (meters <= 94) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(meters/10.0f) * 10, DISTANCE_M_SHORT];
    } else if (meters <= 1049) {
        return [NSString stringWithFormat:@"%.0f %@", roundf(meters/100.0f) * 100, DISTANCE_M_SHORT];
    } else {
        return [NSString stringWithFormat:@"%.1f %@", meters/1000.0f, DISTANCE_KM_SHORT];
    }
    return meters > 1000.0f ? [NSString stringWithFormat:@"%.1f %@", meters/1000.0f, DISTANCE_KM_SHORT] : [NSString stringWithFormat:@"%.0f %@", meters, DISTANCE_M_SHORT];
}

// Format time duration string (choose between seconds and hours)
NSString *formatTime(float seconds) {
    return seconds > 60.0f ? [NSString stringWithFormat:@"%.0f %@", seconds/60.0f, TIME_MINUTES_SHORT] : [NSString stringWithFormat:@"%.0f %@", seconds, TIME_MINUTES_SHORT];
}

// Format time passed between two dates
NSString *formatTimePassed(NSDate *startDate, NSDate *endDate) {
    NSCalendar * cal = [NSCalendar currentCalendar];
    NSDateComponents * comp = [cal components:(NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:startDate toDate:endDate options:0];

    NSString * timestr = @"";
    if (comp.day > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.day, TIME_DAYS_SHORT];
    }
    if (comp.hour > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.hour, TIME_HOURS_SHORT];
    }
    if (comp.minute > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@ ", comp.minute, TIME_MINUTES_SHORT];
    }
    if (comp.second > 0) {
        timestr = [timestr stringByAppendingFormat:@"%d%@", comp.second, TIME_SECONDS_SHORT];
    }
    return timestr;
}

NSString *formatTimeString(NSDate *startDate, NSDate *endDate) {
    NSCalendar * cal = [NSCalendar currentCalendar];
    NSDateComponents * comp = [cal components:(NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:startDate toDate:endDate options:0];
    
    NSMutableArray * arr = [NSMutableArray array];
    
    if (comp.day > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", comp.day]];
    }
    if (comp.hour > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", comp.day]];
    }
    if (comp.minute > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", comp.day]];
    }
    if (comp.second > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", comp.day]];
    }
    return [arr componentsJoinedByString:@":"];
}

NSString *formatTimeLeft(NSInteger seconds) {
    NSMutableArray * arr = [NSMutableArray array];

    NSInteger x = seconds / 86400;
    if (x > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 86400;
    x = seconds / 3600;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 3600;
    x = seconds / 60;
    if (x > 0 || [arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", x]];
    }
    seconds = seconds % 60;
    if ([arr count] > 0) {
        [arr addObject:[NSString stringWithFormat:@"%02d", seconds]];
    } else {
        [arr addObject:@"00"];
        [arr addObject:[NSString stringWithFormat:@"%02d", seconds]];
    }    
    return [arr componentsJoinedByString:@":"];
}

NSString *expectedArrivalTime(NSInteger seconds) {
    NSDate * d = [NSDate dateWithTimeInterval:seconds sinceDate:[NSDate date]];
    NSDateFormatter * df = [NSDateFormatter new];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:d];
}

// Calculate how many calories are burned given speed and time spent cycling
float caloriesBurned(float avgSpeed, float timeSpent){
    float calBurned = 0.0f;

    if (avgSpeed < 10.5) {
        calBurned = timeSpent * 288;
    } else if (avgSpeed < 12.9) {
        calBurned = timeSpent * 324;
    } else if (avgSpeed < 13.7) {
        calBurned = timeSpent * 374;
    } else if (avgSpeed < 16.1) {
        calBurned = timeSpent * 540;
    } else if (avgSpeed < 19.3) {
        calBurned = timeSpent * 639;
    } else if (avgSpeed < 21) {
        calBurned = timeSpent * 702;
    } else if (avgSpeed < 22.5) {
        calBurned = timeSpent * 806;
    } else if (avgSpeed < 24.2) {
        calBurned = timeSpent * 873;
    } else if (avgSpeed < 25.8) {
        calBurned = timeSpent * 945;
    } else if (avgSpeed < 32.2) {
        calBurned = timeSpent * 1121;
    } else if (avgSpeed < 35.4) {
        calBurned = timeSpent * 1359;
    } else if (avgSpeed < 38.7) {
        calBurned = timeSpent * 1746;
    } else if (avgSpeed < 45.1) {
        calBurned = timeSpent * 2822;
    } else  {
        calBurned = timeSpent * 3542;
    }

   return roundf(calBurned);
}

+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext {
    double tmpd = [[NSDate date] timeIntervalSince1970];
    NSString* path = nil;
    // CHECK IF FILE WITH NEW CURRENT DATE EXISTS
    for (;;){
        path = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"] stringByAppendingPathComponent: [NSString stringWithFormat:@"%f.%@", tmpd, ext]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])	//Does file already exist?
        {
            // IF YES INC BY 1 millisecond
            tmpd+=0.000001;
        }else{
            break;
        }
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"routes"] withIntermediateDirectories:YES attributes:@{} error:nil];
    return path;
}


+ (NSArray*)getSearchHistory {
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"searchHistory.plist"]]) {
        NSMutableArray * arr = [NSArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"searchHistory.plist"]];
        NSMutableArray * arr2 = [NSMutableArray array];
        if (arr) {
            for (NSDictionary * d in arr) {
                [arr2 addObject:@{
                 @"name" : [d objectForKey:@"name"],
                 @"address" : [d objectForKey:@"address"],
                 @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                 @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                 @"source" : [d objectForKey:@"source"],
                 @"subsource" : [d objectForKey:@"subsource"],
                 @"lat" : [d objectForKey:@"lat"],
                 @"long" : [d objectForKey:@"long"],
                 @"order" : @1
                 }];
            }
            [arr2 sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                NSDate * d1 = [obj1 objectForKey:@"startDate"];
                NSDate * d2 = [obj2 objectForKey:@"startDate"];
                return [d2 compare:d1];
            }];
            
            [appd setSearchHistory:arr2];
            return arr2;
        }
    }
    [appd setSearchHistory:@[]];
    return @[];
}

+ (BOOL)saveToSearchHistory:(NSDictionary*)dict {
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * arr = [NSMutableArray array];
    for (NSDictionary * srch in appd.searchHistory) {
        if ([[srch objectForKey:@"address"] isEqualToString:[dict objectForKey:@"address"]] == NO) {
            [arr addObject:srch];
        }
    }
    [arr addObject:dict];
    
    [arr sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
        NSDate * d1 = [obj1 objectForKey:@"startDate"];
        NSDate * d2 = [obj2 objectForKey:@"startDate"];
        return [d2 compare:d1];
    }];
    
    NSMutableArray * r = [NSMutableArray array];
    for (NSDictionary * d in arr) {
        [r addObject:@{
         @"name" : [d objectForKey:@"name"],
         @"address" : [d objectForKey:@"address"],
         @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"startDate"]],
         @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"endDate"]],
         @"source" : [d objectForKey:@"source"],
         @"subsource" : [d objectForKey:@"subsource"],
         @"lat" : [d objectForKey:@"lat"],
         @"long" : [d objectForKey:@"long"]
         }];
    }
    [appd setSearchHistory:arr];
    BOOL x = [r writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"searchHistory.plist"] atomically:YES];
    return x;
}

+ (NSMutableArray*)getFavorites {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"]]) {
        NSMutableArray * arr = [NSArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"]];
        NSMutableArray * arr2 = [NSMutableArray array];
        if (arr) {
            for (NSDictionary * d in arr) {
                [arr2 addObject:@{
                 @"name" : [d objectForKey:@"name"],
                 @"address" : [d objectForKey:@"address"],
                 @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                 @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                 @"source" : [d objectForKey:@"source"],
                 @"subsource" : [d objectForKey:@"subsource"],
                 @"lat" : [d objectForKey:@"lat"],
                 @"long" : [d objectForKey:@"long"],
                 @"order" : @0
                 }];
            }
            return arr2;
        }
    }
    return [NSMutableArray array];
}

+ (BOOL)saveFavorites:(NSArray*)fav {
    NSMutableArray * r = [NSMutableArray array];
    for (NSDictionary * d in fav) {
        [r addObject:@{
         @"name" : [d objectForKey:@"name"],
         @"address" : [d objectForKey:@"address"],
         @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"startDate"]],
         @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"endDate"]],
         @"source" : [d objectForKey:@"source"],
         @"subsource" : [d objectForKey:@"subsource"],
         @"lat" : [d objectForKey:@"lat"],
         @"long" : [d objectForKey:@"long"]
         }];
    }
    return [r writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"favorites.plist"] atomically:YES];
}

+ (BOOL)saveToFavorites:(NSDictionary*)dict {
    NSMutableArray * arr = [NSMutableArray array];
    NSMutableArray * a = [self getFavorites];
    for (NSDictionary * srch in a) {
        if ([[srch objectForKey:@"name"] isEqualToString:[dict objectForKey:@"name"]] == NO) {
            [arr addObject:srch];
        }
    }
    [arr addObject:dict];
    
    
    
    return [SMUtil saveFavorites:arr];
}

+ (NSInteger)pointsForName:(NSString*)name andAddress:(NSString*)address andTerms:(NSString*)srchString {
    NSMutableArray * terms = [NSMutableArray array];
    srchString = [srchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString * str in [srchString componentsSeparatedByString:@" "]) {
        if ([terms indexOfObject:str] == NSNotFound) {
            [terms addObject:str];
        }
    }
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

@end
