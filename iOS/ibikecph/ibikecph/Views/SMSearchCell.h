//
//  SMEnterRouteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface SMSearchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *nameLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconImage;

+ (CGFloat)getHeight;
- (void)setImageWithData:(NSDictionary*)currentRow;

@end
