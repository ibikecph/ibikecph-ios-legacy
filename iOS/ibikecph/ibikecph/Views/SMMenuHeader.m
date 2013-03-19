//
//  SMMenuHeader.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 19/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMMenuHeader.h"

@implementation SMMenuHeader

+ (CGFloat)getHeight {
    return 45.0f;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [cellBG setImage:[UIImage imageNamed:@"favListRow"]];
    } else {
        [cellBG setImage:[UIImage imageNamed:@"favListRow"]];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [cellBG setImage:[UIImage imageNamed:@"favListRow"]];
    } else {
        [cellBG setImage:[UIImage imageNamed:@"favListRow"]];
    }
}

- (IBAction)singleTap:(id)sender {
    if (self.delegate) {
        [self.delegate headerTapped:self];
    }
}

- (IBAction)tapButton:(id)sender {
    if (self.delegate) {
        [self.delegate buttonTapped:self];
    }
}

@end
