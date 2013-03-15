//
//  SMMenuCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 15/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMMenuCell.h"

@implementation SMMenuCell

+ (CGFloat)getHeight {
    return 45.0f;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [cellBG setImage:[UIImage imageNamed:@"contactsCellBGHighlight"]];
    } else {
        [cellBG setImage:[UIImage imageNamed:@"contactsCellBG"]];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [cellBG setImage:[UIImage imageNamed:@"contactsCellBGHighlight"]];
    } else {
        [cellBG setImage:[UIImage imageNamed:@"contactsCellBG"]];
    }
}



@end
