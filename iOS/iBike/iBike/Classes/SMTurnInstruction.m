//
//  SMTurnInstructions.m
//  iBike
//
//  Created by Petra Markovic on 1/28/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMTurnInstruction.h"
#import "SBJson.h"

@implementation SMTurnInstruction

NSString *iconsSmall[] = {
    @"no icon",
    @"direction_small_continue",
    @"direction_small_turn_slight_right",
    @"direction_small_turn_right",
    @"direction_small_turn_sharp_right",
    @"direction_small_u_turn",
    @"direction_small_turn_sharp_left",
    @"direction_small_turn_left",
    @"direction_small_turn_slight_left",
    @"no_icon",
    @"direction_small_continue",
    @"direction_small_enter_roundabout",
    @"direction_small_leave_roundabout",
    @"direction_small_continue_in_roundabout",
    @"direction_small_start_at_end_of_street",
    @"direction_small_pin_b",
    @"direction_small_start_pushing_bike_one_way",
    @"direction_small_stop_pushing_bike_one_way",
    @"direction_small_pin_b",
};

NSString *iconsLarge[] = {
    @"no icon",
    @"direction_large_continue",
    @"direction_large_turn_slight_right",
    @"direction_large_turn_right",
    @"direction_large_turn_sharp_right",
    @"direction_large_u_turn",
    @"direction_large_turn_sharp_left",
    @"direction_large_turn_left",
    @"direction_large_turn_slight_left",
    @"no_icon",
    @"direction_large_continue",
    @"direction_large_enter_roundabout",
    @"direction_large_leave_roundabout",
    @"direction_large_continue_in_roundabout",
    @"direction_large_start_at_end_of_street",
    @"direction_large_pin_b",
    @"direction_large_start_pushing_bike_one_way",
    @"direction_large_stop_pushing_bike_one_way",
    @"direction_large_pin_b",
};


- (CLLocation *)getLocation {
    return self.loc;
//    if (waypoints && self.waypointsIndex >= 0 && self.waypointsIndex < waypoints.count)
//        return [waypoints objectAtIndex:self.waypointsIndex];
//    return nil;
}

// Returns full direction names for abbreviations N NE E SE S SW W NW
NSString *directionString(NSString *abbreviation) {
    return translateString([@"direction_" stringByAppendingString:abbreviation]);
}

// Returns only string representation of the driving direction
- (NSString *)descriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];
    NSString *desc = [NSString stringWithFormat:translateString(key), translateString([@"direction_number_" stringByAppendingString:self.ordinalDirection])];
    return desc;
}

// Returns only string representation of the driving direction including wayname
- (NSString *)fullDescriptionString {
    NSString *key = [@"direction_" stringByAppendingFormat:@"%d", self.drivingDirection];

    if (self.drivingDirection != 0 && self.drivingDirection != 15 && self.drivingDirection != 100)
        return [NSString stringWithFormat:@"%@ %@", translateString(key), self.wayName];

    return [NSString stringWithFormat:@"%@", translateString(key)];
}

- (UIImage *)smallDirectionIcon {
    return [UIImage imageNamed:iconsSmall[self.drivingDirection]];
}

- (UIImage *)largeDirectionIcon {
    return [UIImage imageNamed:iconsLarge[self.drivingDirection]];
}

// Full textual representation of the object, used mainly for debugging
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ [SMTurnInstruction: %d, %d, %@, %@, %f, (%f, %f)]",
            [self descriptionString],
            self.lengthInMeters,
            self.timeInSeconds,
            self.lengthWithUnit,
            self.directionAbrevation,
            self.azimuth,
            [self getLocation].coordinate.latitude, [self getLocation].coordinate.longitude];
}


@end
