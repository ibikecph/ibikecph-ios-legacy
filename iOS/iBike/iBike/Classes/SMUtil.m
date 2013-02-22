//
//  SMUtil.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <math.h>
#import <CoreLocation/CoreLocation.h>
#import "SMUtil.h"

static const double DEG_TO_RAD = 0.017453292519943295769236907684886;
static const double EARTH_RADIUS_IN_METERS = 6372797.560856;


@implementation SMUtil

// Calculates distance between point C and arc AB in radians
// dA - distance between point C and point A in radians
// dB - distance between point C and point B in radians
// dAB - length of arc AB in radians
double distanceFromArc(double dA, double dB, double dAB) {
    // In spherical trinagle ABC
    // a is length of arc BC, that is dB
    // b is length of arc AC, that is dA
    // c is length of arc AB, that is dAB
    // We rename parameters so following formulas are more clear:
    double a = dB;
    double b = dA;
    double c = dAB;

    // First, we calculate angles alpha and beta in spherical triangle ABC
    // and based on them we decide how to calculate the distance:
    if (sin(b) * sin(c) == 0.0 || sin(c) * sin(a) == 0.0) {
        // TODO figure out what to do with this case, and if it is possible to happen in our cases.
        // It probably means that one of distance is n*pi, which gives around 20000km for n = 1,
        // unlikely for Denmark, so we should be fine.
        return -1.0;
    }

    double alpha = acos((cos(a) - cos(b) * cos(c)) / (sin(b) * sin(c)));
    double beta  = acos((cos(b) - cos(c) * cos(a)) / (sin(c) * sin(a)));

    // It is possible that both sinuses are too small so we can get nan when dividing with them
    if (isnan(alpha) || isnan(beta)) {
//        double cosa = cos(a);
//        double cosbc = cos(b) * cos(c);
//        double minus1 = cosa - cosbc;
//        double sinbc = sin(b) * sin(c);
//        double div1 = minus1 / sinbc;
//
//        double cosb = cos(b);
//        double cosca = cos(a) * cos(c);
//        double minus2 = cosb - cosca;
//        double sinca = sin(a) * sin(c);
//        double div2 = minus2 / sinca;

        return -1.0;
    }

    // If alpha or beta are zero or pi, it means that C is on the same circle as arc AB,
    // we just need to figure out if it is between AB:
    if (alpha == 0.0 || beta == 0.0) {
        return (dA + dB > dAB) ? MIN(dA, dB) : 0.0;
    }

    // If alpha is obtuse and beta is acute angle, then
    // distance is equal to dA:
    if (alpha > M_PI_2 && beta < M_PI_2)
        return dA;

    // Analogously, if beta is obtuse and alpha is acute angle, then
    // distance is equal to dB:
    if (beta > M_PI_2 && alpha < M_PI_2)
        return dB;

    // If both alpha and beta are acute or both obtuse or one of them (or both) are right,
    // distance is the height of the spherical triangle ABC:

    // Again, unlikely, since it would render at least pi/2*EARTH_RADIUS_IN_METERS, which is too much.
    if (cos(a) == 0.0)
        return -1;

    double x = atan(-1.0/tan(c) + (cos(b) / (cos(a) * sin(c))));
    // Similar to previous edge cases...
    if (cos(x) == 0.0)
        return -1.0;

    return acos(cos(a) / cos(x));
}

// Distance of arc AB in radians
double arcInRadians(CLLocationCoordinate2D A, CLLocationCoordinate2D B) {
    double latitudeArc  = (A.latitude - B.latitude) * DEG_TO_RAD;
    double longitudeArc = (A.longitude - B.longitude) * DEG_TO_RAD;
    double latitudeH = sin(latitudeArc * 0.5);
    latitudeH *= latitudeH;
    double lontitudeH = sin(longitudeArc * 0.5);
    lontitudeH *= lontitudeH;
    double tmp = cos(A.latitude * DEG_TO_RAD) * cos(B.latitude * DEG_TO_RAD);
    return 2.0 * asin(sqrt(latitudeH + tmp * lontitudeH));
}

//double distanceInMeters(CLLocationCoordinate2D A, CLLocationCoordinate2D B) {
//    return EARTH_RADIUS_IN_METERS * arcInRadians(A, B);
//}

// Calculates distance between location C and path AB in meters.
double distanceFromLineInMeters(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B) {
    double dA = arcInRadians(C, A);
    double dB = arcInRadians(C, B);
    double dAB = arcInRadians(A, B);

    if (dA == 0) return 0;
    if (dB == 0) return 0;
    if (dAB == 0) return dA;

    return EARTH_RADIUS_IN_METERS * distanceFromArc(dA, dB, dAB);
}

// Format distance string (choose between meters and kilometers)
NSString *formatDistance(float meters) {
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

BOOL sameCoordinates(CLLocation *loc1, CLLocation *loc2) {
    return loc1.coordinate.latitude == loc2.coordinate.latitude && loc1.coordinate.longitude == loc2.coordinate.longitude;
}

@end
