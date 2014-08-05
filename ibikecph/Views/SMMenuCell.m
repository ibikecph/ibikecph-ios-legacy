//
//  SMMenuCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 15/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMenuCell.h"

@implementation SMMenuCell

+ (CGFloat)getHeight {
    return 45.0f;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [self setBackgroundColor:[UIColor colorWithRed:0.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
        [self.text setTextColor:[UIColor whiteColor]];
        [self.image setHighlighted:YES];
    } else {
        [self setBackgroundColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f]];
        [self.text setTextColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0f]];
        [self.image setHighlighted:NO];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [self setBackgroundColor:[UIColor colorWithRed:0.0f green:174.0f/255.0f blue:239.0f/255.0f alpha:1.0f]];
        [self.text setTextColor:[UIColor whiteColor]];
        [self.image setHighlighted:YES];
    } else {
        [self setBackgroundColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f]];
        [self.text setTextColor:[UIColor colorWithRed:203.0f/255.0f green:203.0f/255.0f blue:203.0f/255.0f alpha:1.0f]];
        [self.image setHighlighted:NO];
    }
}

- (IBAction)editCell:(id)sender {
    if (self.delegate) {
        [self.delegate editFavorite:self];
    }
}



@end
