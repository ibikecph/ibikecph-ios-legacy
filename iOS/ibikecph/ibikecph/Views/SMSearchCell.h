//
//  SMEnterRouteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface SMEnterRouteCell : UITableViewCell

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *nameLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconImage;

+ (CGFloat)getHeight;

@end
