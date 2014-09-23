//
//  UIView+LocateSubview.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/09/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * \ingroup libs
 * 
 */

@interface UIView (LocateSubview)

/**
 * locate subview with a specified class name
 */
- (UIView*)subviewWithClassName:(NSString*) className;

@end
