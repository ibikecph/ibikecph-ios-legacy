//
//  SMNetworkErrorView.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/06/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMNetworkErrorView.h"

@interface SMNetworkErrorView ()

@end

@implementation SMNetworkErrorView

+ (CGSize)getSize {
    return CGSizeMake(120.0f, 120.0f);
}

+ (SMNetworkErrorView*) getFromNib {
    SMNetworkErrorView * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMNetworkErrorView" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMNetworkErrorView class]]) {
            xx = (SMNetworkErrorView *)currentObject;
            xx.warningText.text = translateString(@"network_error_text");
            break;
        }
    }
    return xx;
}

@end
