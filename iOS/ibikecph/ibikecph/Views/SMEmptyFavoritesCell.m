//
//  SMEmptyFavoritesCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEmptyFavoritesCell.h"

@implementation SMEmptyFavoritesCell

+ (CGFloat)getHeight {
    return 150.0f;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
        [self setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
    } else {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
        [self setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
        [self setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
    } else {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
        [self setBackgroundColor:[UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:33.0f/255.0f]];
    }
}
@end
