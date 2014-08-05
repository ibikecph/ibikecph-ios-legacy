//
//  SMPatternedButton.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 16/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMPatternedButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation SMPatternedButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIImage * img = nil;
        img = [self backgroundImageForState:UIControlStateNormal];
        CGSize newSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,newSize.width,newSize.height)];
        [v setOpaque:NO];
        [v setBackgroundColor:[UIColor clearColor]];
        if ([UIScreen mainScreen].scale > 1.0f) {
            [v setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern_btn@2x.png"]]];
        } else {
            [v setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern_btn.png"]]];
        }
        UIGraphicsBeginImageContextWithOptions(v.bounds.size, v.opaque, 0.0);
        [v.layer setOpaque:NO];
        [v.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (img) {
            UIImage * bottomImage = [img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1];
            UIGraphicsBeginImageContext( newSize );
            [bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            [image drawInRect:CGRectMake(2,2,newSize.width-4,newSize.height-4) blendMode:kCGBlendModeMultiply alpha:1.0];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self setBackgroundImage:newImage forState:UIControlStateNormal];
        }
        img = [self backgroundImageForState:UIControlStateHighlighted];
        if (img) {
            UIImage * bottomImage = [img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1];
            UIGraphicsBeginImageContext( newSize );
            [bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            [image drawInRect:CGRectMake(2,2,newSize.width-4,newSize.height-4) blendMode:kCGBlendModeMultiply alpha:1.0];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setBackgroundImage:newImage forState:UIControlStateHighlighted];
        }
        img = [self backgroundImageForState:UIControlStateDisabled];
        if (img) {
            UIImage * bottomImage = [img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1];
            UIGraphicsBeginImageContext( newSize );
            [bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            [image drawInRect:CGRectMake(2,2,newSize.width-4,newSize.height-4) blendMode:kCGBlendModeMultiply alpha:1.0];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setBackgroundImage:newImage forState:UIControlStateDisabled];
        }
        img = [self backgroundImageForState:UIControlStateSelected];
        if (img) {
            UIImage * bottomImage = [img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1];
            UIGraphicsBeginImageContext( newSize );
            [bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            [image drawInRect:CGRectMake(2,2,newSize.width-4,newSize.height-4) blendMode:kCGBlendModeMultiply alpha:1.0];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self setBackgroundImage:newImage forState:UIControlStateSelected];
        }
    }
    return self;
}


@end
