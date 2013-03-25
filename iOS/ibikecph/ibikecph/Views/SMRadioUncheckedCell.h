//
//  SMRadioUncheckedCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 07/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMRadioUncheckedCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *radioTitle;

+ (CGFloat)getHeight;

@end
