//
//  SMDirectionCell.h
//  I Bike CPH
//
//  Created by Petra Markovic on 2/1/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SMTurnInstruction.h"

@interface SMDirectionCell : UITableViewCell {

}
@property (weak, nonatomic) IBOutlet UILabel *lblDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imgDirection;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;
@property (weak, nonatomic) IBOutlet UILabel *lblWayname;

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn;

+ (CGFloat)getHeight;
+ (CGFloat)getHeightForDescription:(NSString*) desc andWayname:(NSString*) wayname;

@end
