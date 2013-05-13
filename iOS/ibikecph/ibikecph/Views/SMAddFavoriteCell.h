//
//  SMAddFavoriteCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMUtil.h"


@interface SMAddFavoriteCell : UIView <UIGestureRecognizerDelegate>{
    __weak IBOutlet UIImageView *cellBG;
}
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UIImageView *addFavoritesSymbol;

@property (nonatomic, weak) id<ViewTapDelegate>delegate;

+ (CGFloat)getHeight;
+ (SMAddFavoriteCell*) getFromNib;

@end
