//
//  SMCustomButton.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 16/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMCustomButton.h"

@implementation SMCustomButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIImage * img = nil;
        img = [self backgroundImageForState:UIControlStateNormal];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateNormal];
        }
        img = [self backgroundImageForState:UIControlStateHighlighted];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateHighlighted];
        }
        img = [self backgroundImageForState:UIControlStateDisabled];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateDisabled];
        }
        img = [self backgroundImageForState:UIControlStateSelected];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateSelected];
        }
    }
    return self;
}

@end
