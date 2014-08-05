//
//  UIView+LocateSubview.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/09/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "UIView+LocateSubview.h"

@implementation UIView (LocateSubview)

- (UIView*)subviewWithClassName:(NSString*) className {
	if ([[[self class] description] isEqualToString:className]) {
		return self;
    }
	
	for(UIView* subview in self.subviews) {
		UIView* huntedSubview = [subview subviewWithClassName:className];
		if (huntedSubview != nil) {
			return huntedSubview;
        }
	}
	return nil;
}


@end
