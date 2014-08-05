//
//  SMRouteTypeSelectCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/06/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteTypeSelectCell.h"

@implementation SMRouteTypeSelectCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [cellText setTextColor:[UIColor whiteColor]];
        [cellImage setHighlighted:YES];
        [self setBackgroundColor:[UIColor colorWithRed:29.0f/255.0f green:175.0f/255.0f blue:236.0f/255.0f alpha:1.0f]];
    } else {
        [cellText setTextColor:[UIColor lightGrayColor]];
        [cellImage setHighlighted:NO];
        [self setBackgroundColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f]];
    }
}

- (void)setupCellWithData:(NSDictionary*)data {
    cellText.text= [data objectForKey:@"name"];
    cellImage.image= [UIImage imageNamed:[data objectForKey:@"image"]];
    [cellImage setHighlightedImage:[UIImage imageNamed:[data objectForKey:@"imageHighlighted"]]];
}

+ (CGFloat)getHeight {
    return 59.0f;
}

@end
