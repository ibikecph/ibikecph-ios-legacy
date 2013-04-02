//
//  SMEnterRouteCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSearchCell.h"

@implementation SMSearchCell


+ (CGFloat)getHeight {
    return 40.0f;
}

- (void)setImageWithData:(NSDictionary*)currentRow {
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"fb"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
        if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            [self.iconImage setImage:[UIImage imageNamed:@"findLocation"]];
        } else {
            [self.iconImage setImage:[UIImage imageNamed:@"findAutocomplete"]];
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favorites"]) {
        if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
            [self.iconImage setImage:[UIImage imageNamed:@"favHome"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
            [self.iconImage setImage:[UIImage imageNamed:@"favWork"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
            [self.iconImage setImage:[UIImage imageNamed:@"favBookmark"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
            [self.iconImage setImage:[UIImage imageNamed:@"findStar"]];
        } else {
            [self.iconImage setImage:nil];
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"searchHistory"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else {
         [self.iconImage setImage:nil];
    }

}

@end
