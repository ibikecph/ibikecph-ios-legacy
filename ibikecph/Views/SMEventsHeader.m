//
//  SMEventsHeader.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEventsHeader.h"

@interface SMEventsHeader ()

@end

@implementation SMEventsHeader

+ (CGFloat)getHeight {
    return 29.0f;
}

- (void)setupHeaderWithData:(NSDictionary*)data {
    NSCalendar * cal = [NSCalendar currentCalendar];
    NSDateComponents * comp = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date]];
    comp.hour = 0;
    comp.minute = 0;
    comp.second = 0;
    NSDate * today = [cal dateFromComponents:comp];
    
    comp = [[NSDateComponents alloc] init];
    comp.day = 1;
    NSDate * tomorrow = [cal dateByAddingComponents:comp toDate:today options:nil];
    
    if ([today isEqualToDate:[data objectForKey:@"dayDate"]]) {
        [self.dateLabel setText:[NSString stringWithFormat:@" - %@", [data objectForKey:@"text"]]];
        [self.dayLabel setText:translateString(@"today")];
    } else if ([tomorrow isEqualToDate:[data objectForKey:@"dayDate"]]) {
        [self.dateLabel setText:[NSString stringWithFormat:@" - %@", [data objectForKey:@"text"]]];
        [self.dayLabel setText:translateString(@"tomorrow")];
        
    } else {
        [self.dateLabel setText:[data objectForKey:@"text"]];
        [self.dayLabel setText:@""];
    }

    CGSize size = [self.dayLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:17.0f]];
    CGRect frame = self.dayLabel.frame;
    frame.size = size;
    [self.dayLabel setFrame:frame];

    size = [self.dateLabel.text sizeWithFont:[UIFont systemFontOfSize:17.0f]];
    frame = self.dateLabel.frame;
    frame.origin.x = self.dayLabel.frame.origin.x + self.dayLabel.frame.size.width;
    frame.size = size;
    [self.dateLabel setFrame:frame];
    
    frame = self.containerView.frame;
    frame.size.width = self.dateLabel.frame.size.width + self.dayLabel.frame.size.width;
    frame.origin.x = roundf((self.frame.size.width - frame.size.width) / 2.0f);
    [self.containerView setFrame:frame];
    
    [self.containerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
    
}


@end
