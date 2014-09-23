//
//  FlickableView.h
//  FlickableView
//
//  Created by Ivan Pavlovic on 05/05/2013.
//  Copyright (c) 2013. Ivan Pavlovic. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * \ingroup libs
 * Flickable view
 *
 * handles pull gesture used to swipe the main screen away revealing a menu under it
 */

@interface FlickableView : UIView <UIGestureRecognizerDelegate>

@property CGFloat startPos;
@property CGFloat endPos;
@property CGFloat threshold;
@property CGFloat originalPos;


- (void)setupForHorizontalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end;
- (void)setupForVerticalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end;

- (void)setupForHorizontalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end andStart:(CGFloat)pos andPullView:(UIView*)pullView;
- (void)addPullView:(UIView*)pullView ;

@end
