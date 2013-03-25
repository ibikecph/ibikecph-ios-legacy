//
//  SMEventsCalendarCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 29/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//


@interface SMEventsCalendarCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellBG;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

+ (CGFloat)getHeight;

@end
