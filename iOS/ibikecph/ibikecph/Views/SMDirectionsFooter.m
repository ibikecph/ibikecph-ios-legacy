//
//  SMDirectionsFooter.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 02/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMDirectionsFooter.h"

@interface SMDirectionsFooter ()

@end

@implementation SMDirectionsFooter

+ (CGFloat)getHeight {
    return 80.0f;
}

+ (SMDirectionsFooter*) getFromNib {
    SMDirectionsFooter * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMDirectionsFooter" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMDirectionsFooter class]]) {
            xx = (SMDirectionsFooter *)currentObject;
            break;
        }
    }
    return xx;
}

- (IBAction)viewTapped:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewTapped:)]) {
        [self.delegate viewTapped:self];
    }
}


@end
