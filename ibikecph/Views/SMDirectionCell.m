//
//  SMDirectionCell.m
//  I Bike CPH
//
//  Created by Petra Markovic on 2/1/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMDirectionCell.h"

#import "SMUtil.h"

@interface SMDirectionCell ()

@end

@implementation SMDirectionCell

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn {
//    [self.lblDescription setText:[turn descriptionString]];
    if ([turn.shortDescriptionString rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
        [self.lblWayname setText:translateString(turn.shortDescriptionString)];
    } else {
        [self.lblWayname setText:turn.shortDescriptionString];
    }

//    CGSize size = [self.lblDescription.text sizeWithFont:[UIFont systemFontOfSize:DIRECTION_FONT_SIZE] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 40.0f) lineBreakMode:NSLineBreakByWordWrapping];
//    CGRect frame = self.lblDescription.frame;
//    frame.size.height = size.height;
//    [self.lblDescription setFrame:frame];

    CGSize size = [self.lblWayname.text sizeWithFont:[UIFont boldSystemFontOfSize:self.lblWayname.font.pointSize] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 80.0f) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = self.lblWayname.frame;
    frame.size.height = size.height;
    frame.origin.y = floorf((self.frame.size.height - size.height) / 2.0f);
    [self.lblWayname setFrame:frame];
    [self.lblDistance setText:formatDistance(turn.lengthInMeters)]; // dynamic distance
    
    [self.imgDirection setImage:[turn smallDirectionIcon]];
}

+ (CGFloat)getHeight {
    return 60.0f;
}

+ (CGFloat)getHeightForDescription:(NSString*) desc andWayname:(NSString*) wayname {
    return 60.0f;
    CGFloat height = 9.0f;
    CGSize size = [desc sizeWithFont:[UIFont systemFontOfSize:DIRECTION_FONT_SIZE] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 40.0f) lineBreakMode:NSLineBreakByWordWrapping];
    height += size.height;
    size = [wayname sizeWithFont:[UIFont boldSystemFontOfSize:WAYPOINT_FONT_SIZE] constrainedToSize:CGSizeMake(INSTRUCTIONS_LABEL_WIDTH, 40.0f) lineBreakMode:NSLineBreakByWordWrapping];
    height += size.height + 2.0f + 9.0f;
    return MAX(60.0f, height);
}


@end
