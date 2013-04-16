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
        if (img) {
            CGSize newSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
            UIImage * bottomImage = [img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1];
            
            UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,newSize.width,newSize.height)];
            [v setOpaque:NO];
            [v setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern_btn.png"]]];
            UIGraphicsBeginImageContextWithOptions(v.bounds.size, v.opaque, 0.0);
            [v.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            UIGraphicsBeginImageContext( newSize );
            // Use existing opacity as is
            [bottomImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            // Apply supplied opacity
            [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height) blendMode:kCGBlendModePlusDarker alpha:0.6];
            
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            [self setBackgroundImage:newImage forState:UIControlStateNormal];
        }
        img = [self backgroundImageForState:UIControlStateHighlighted];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateHighlighted];
        }
        img = [self backgroundImageForState:UIControlStateDisabled];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateDisabled];
        }
        img = [self backgroundImageForState:UIControlStateSelected];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateSelected];
        }
    }
    return self;
}


@end
