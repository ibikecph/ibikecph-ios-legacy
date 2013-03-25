//
//  SMContactsCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMContactsCell.h"

@interface SMContactsCell ()

@end

@implementation SMContactsCell

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
