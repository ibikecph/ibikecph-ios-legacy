//
//  SMCalloutView.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 04/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMCalloutView.h"

@interface SMCalloutView ()

@end

@implementation SMCalloutView

+ (SMCalloutView*) getFromNib {
    SMCalloutView * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMCalloutView" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMCalloutView class]]) {
            xx = (SMCalloutView *)currentObject;
            break;
        }
    }
    return xx;
}

+ (CGFloat)getHeight {
    return 30.0f;
}

-(IBAction)buttonClicked:(id)sender {
    if (self.delegate) {
        [self.delegate buttonClicked];
    }
}

@end
