//
//  SMAddFavoriteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMAddFavoriteCell : UITableViewCell { 
    
    __weak IBOutlet UIImageView *cellBG;
}
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *text;


+ (CGFloat)getHeight;


@end
