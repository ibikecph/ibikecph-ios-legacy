//
//  SMEmptyFavoritesCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMEmptyFavoritesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UILabel *addFavoritesText;
@property (weak, nonatomic) IBOutlet UIImageView *addFavoritesSymbol;


+ (CGFloat)getHeight;


@end
