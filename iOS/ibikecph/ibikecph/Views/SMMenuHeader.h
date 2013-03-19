//
//  SMMenuHeader.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 19/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMMenuHeader;

@protocol SMMenuHeaderDelegate <NSObject>

- (void)headerTapped:(SMMenuHeader*)header;
- (void)buttonTapped:(SMMenuHeader*)header;

@end

@interface SMMenuHeader : UITableViewCell <UIGestureRecognizerDelegate> {
    
    __weak IBOutlet UIImageView *cellBG;
}

@property NSInteger type;

@property (nonatomic, weak) id<SMMenuHeaderDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *text;

+ (CGFloat)getHeight;


@end
