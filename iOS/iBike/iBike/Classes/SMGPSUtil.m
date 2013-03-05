//
//  SMGPSUtil.m
//  iBike
//
//  Created by Ivan Pavlovic on 05/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMGPSUtil.h"
#import <math.h>

static const double DEG_TO_RAD = 0.017453292519943295769236907684886;
static const double EARTH_RADIUS_IN_METERS = 6372797.560856;

@implementation SMGPSUtil

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

// Calculates distance between point C and arc AB in radians
// dA - distance between point C and point A in radians
// dB - distance between point C and point B in radians
// dAB - length of arc AB in radians
double distanceFromPointOnArc(double dA, double dB, double dAB) {
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
    
    return x;
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

// Calculates distance between location C and path AB in meters.
CLLocationCoordinate2D closestCoordinate(CLLocationCoordinate2D C, CLLocationCoordinate2D A, CLLocationCoordinate2D B) {
    double dA = arcInRadians(C, A);
    double dB = arcInRadians(C, B);
    double dAB = arcInRadians(A, B);
    
    if (dA == 0) return A;
    if (dB == 0) return B;
    if (dAB == 0) return A;
    
    double x = distanceFromPointOnArc(dA, dB, dAB);
    
    if (x < 0) {
        return C;
    }
    
    return CLLocationCoordinate2DMake(A.latitude + (B.latitude - A.latitude) * x / dAB, A.longitude + (B.longitude - A.longitude) * x / dAB);
}

BOOL sameCoordinates(CLLocation *loc1, CLLocation *loc2) {
    return loc1.coordinate.latitude == loc2.coordinate.latitude && loc1.coordinate.longitude == loc2.coordinate.longitude;
}

double DegreesToRadians(double degrees) {return degrees * M_PI / 180;};
double RadiansToDegrees(double radians) {return radians * 180/M_PI;};


+(double) bearingBetweenStartLocation:(CLLocation *)startLocation andEndLocation:(CLLocation *)endLocation{
    
    double lat1 = DegreesToRadians(startLocation.coordinate.latitude);
    double lon1 = DegreesToRadians(startLocation.coordinate.longitude);
    
    double lat2 = DegreesToRadians(endLocation.coordinate.latitude);
    double lon2 = DegreesToRadians(endLocation.coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radiansBearing = atan2(y, x);
    
    return RadiansToDegrees(radiansBearing);
}



@end
