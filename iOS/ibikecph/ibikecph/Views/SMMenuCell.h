//
//  SMMenuCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 15/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMMenuCell : UITableViewCell {
    
    __weak IBOutlet UIImageView *cellBG;
}
@property (weak, nonatomic) IBOutlet UIImageView *contactImage;
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UIImageView *contactDisclosure;

+ (CGFloat)getHeight;


@end
