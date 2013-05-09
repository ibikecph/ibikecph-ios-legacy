//
//  SMCustomButton.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 16/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMCustomButton.h"

@interface SMCustomButton()
@property (nonatomic, assign) float minWidth;
@property (nonatomic, assign) float maxWidth;
@property (nonatomic, assign) float padding;
@property (nonatomic, assign) BOOL shouldResizeToText;
@end

@implementation SMCustomButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self localInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self localInit];
        
        UIImage * img = nil;
        img = [self backgroundImageForState:UIControlStateNormal];
        if (img) {
            [self setBackgroundImage:[img stretchableImageWithLeftCapWidth:round(img.size.width/2)-1 topCapHeight:round(img.size.height/2)-1] forState:UIControlStateNormal];
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

-(void) localInit{
    self.minWidth = self.frame.size.width * 0.2;
    self.maxWidth = self.frame.size.width * 2.0;
    self.padding = self.frame.size.width - self.titleLabel.frame.size.width;
    self.shouldResizeToText = self.tag < 0;
}

-(void) viewTranslated{
    if(self.shouldResizeToText){
        [self resizeToFitTheTextWithMinWidth:self.minWidth andMaxWidth:self.maxWidth];
    }
}

-(void) resizeToFitTheTextWithMinWidth:(float)minWidth andMaxWidth:(float) maxWidth{
    
    self.shouldResizeToText = YES;
    
    if(minWidth < 0.0) {
        //do nothing
    } else {
        self.minWidth = minWidth;
    }
    if(maxWidth < 0.0){
        //do nothing
    } else {
        if(maxWidth < self.minWidth){
            self.shouldResizeToText = NO;
            return;
        }
        self.maxWidth = maxWidth;
    }
    
    self.shouldResizeToText = YES;
    
    CGRect frm = self.frame;
    UILabel * textLabel =self.titleLabel;
    
    NSString * title = textLabel.text;
    CGSize currSize = self.frame.size;
    
    
    CGSize expectedLabelSize = [title sizeWithFont:textLabel.font];
    
    float diff = 0.0f;
    if(expectedLabelSize.width > currSize.width){
        diff = (expectedLabelSize.width + self.padding > self.maxWidth) ? self.maxWidth - currSize.width : expectedLabelSize.width - currSize.width + self.padding;
    } else {
        diff = (expectedLabelSize.width + self.padding < self.minWidth) ? self.minWidth - currSize.width : expectedLabelSize.width - currSize.width + self.padding;
    }
    
    
    frm.origin.x -= diff*0.5f;
    frm.size.width += diff;
    self.frame = frm;

}

@end
