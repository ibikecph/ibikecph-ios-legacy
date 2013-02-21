//
//  SMContactsHeader.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMContactsHeader.h"

@interface SMContactsHeader ()

@end

@implementation SMContactsHeader

+ (CGFloat)getHeight {
    return 45.0f;
}

- (IBAction)buttonPressed:(id)sender {
    if (self.delegate) {
        [self.delegate buttonPressed:sender];
    }
}

@end
