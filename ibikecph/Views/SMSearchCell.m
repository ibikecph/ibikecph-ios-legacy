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
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteContacts"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
        if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findLocation"]];
            [self.iconImage setImage:[UIImage imageNamed:@"findLocation"]];
        } else {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findAutocomplete"]];
            [self.iconImage setImage:[UIImage imageNamed:@"findAutocomplete"]];
        }
    }else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favorites"]) {
        if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
            [self.iconImage setImage:[UIImage imageNamed:@"favHomeGrey"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
            [self.iconImage setImage:[UIImage imageNamed:@"favWorkGrey"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
            [self.iconImage setImage:[UIImage imageNamed:@"favSchoolGrey"]];
        } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
            [self.iconImage setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
            [self.iconImage setImage:[UIImage imageNamed:@"favStarGreySmall"]];
        } else {
            [self.iconImage setHighlightedImage:nil];
            [self.iconImage setImage:nil];
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"searchHistory"]) {
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
        [self.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
        [self.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
    } else {
        [self.iconImage setHighlightedImage:nil];
        [self.iconImage setImage:nil];
    }

}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        //        [self setBackgroundColor:[UIColor colorWithRed:0.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
        //        [self.text setTextColor:[UIColor whiteColor]];
        [self.iconImage setHighlighted:YES];
    } else {
        //        [self setBackgroundColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f]];
        //        [self.text setTextColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0f]];
        [self.iconImage setHighlighted:NO];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        //        [self setBackgroundColor:[UIColor colorWithRed:0.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
        //        [self.text setTextColor:[UIColor whiteColor]];
        [self.iconImage setHighlighted:YES];
    } else {
        //        [self setBackgroundColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f]];
        //        [self.text setTextColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0f]];
        [self.iconImage setHighlighted:NO];
    }
}

@end
