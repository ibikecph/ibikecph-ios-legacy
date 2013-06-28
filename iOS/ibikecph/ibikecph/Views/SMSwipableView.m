//
//  SMSwipableView.m
//  iBike
//
//  Created by Ivan Pavlovic on 27/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSwipableView.h"
#import "SMUtil.h"

@implementation SMSwipableView

+ (SMSwipableView*) getFromNib {
    SMSwipableView * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMSwipableView" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMSwipableView class]]) {
            xx = (SMSwipableView *)currentObject;
            break;
        }
    }
    return xx;
}


- (void)renderViewFromInstruction:(SMTurnInstruction *)turn {
//    [self.lblDescription setText:[turn descriptionString]];
    
    if ([turn.shortDescriptionString rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
        [self.lblWayname setText:translateString(turn.shortDescriptionString)];
    } else {
        [self.lblWayname setText:turn.shortDescriptionString];
    }
    
//    CGSize size = [self.lblDescription.text sizeWithFont:[UIFont systemFontOfSize:DIRECTION_FONT_SIZE] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 60.0f) lineBreakMode:NSLineBreakByWordWrapping];
//    CGRect frame = self.lblDescription.frame;
//    frame.origin.y = frame.size.height + frame.origin.y - size.height;
//    frame.size.height = size.height;
//    [self.lblDescription setFrame:frame];
    
    CGSize size = [self.lblWayname.text sizeWithFont:[UIFont boldSystemFontOfSize:self.lblWayname.font.pointSize] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 80.0f) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = self.lblWayname.frame;
    frame.size.height = size.height;
    frame.origin.y = floorf((self.frame.size.height - size.height) / 2.0f) - 10.0f;
    [self.lblWayname setFrame:frame];
    [self.lblDistance setText:formatDistance(turn.lengthInMeters)]; // dynamic distance
    
    [self.imgDirection setImage:[turn largeDirectionIcon]];
}

+ (CGFloat)getHeight {
    return 82.0f;
}


@end
