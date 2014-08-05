//
//  SMMenuCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 15/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMMenuCell;

@protocol SMMenuCellDelegate <NSObject>
- (void)editFavorite:(SMMenuCell*)cell;
@end

@interface SMMenuCell : UITableViewCell {
    
    __weak IBOutlet UIImageView *cellBG;
}
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;

@property (nonatomic, weak) id<SMMenuCellDelegate>delegate;

+ (CGFloat)getHeight;


@end
