//
//  SMEnterRouteCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEnterRouteCell.h"

@implementation SMEnterRouteCell



+ (CGFloat)getHeight {
    return 40.0f;
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self.backImage setHighlighted:highlighted];
    if (highlighted) {
        [self.iconImage setHighlighted:YES];
    } else {
        [self.iconImage setHighlighted:NO];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [self.iconImage setHighlighted:YES];
    } else {
        [self.iconImage setHighlighted:NO];
    }
}

- (void)prepareForReuse {
    [self.iconImage setHighlightedImage:nil];
    [self.iconImage setImage:nil];
}


@end
