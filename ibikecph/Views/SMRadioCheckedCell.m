//
//  SMRadioCheckedCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRadioCheckedCell.h"

@implementation SMRadioCheckedCell

+ (CGFloat)getHeight {
    return 110.0f;
}

- (void)prepareForReuse {
    [self.radioTextBox setDelegate:nil];
}

@end
