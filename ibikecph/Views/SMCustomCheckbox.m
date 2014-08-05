//
//  SMCustomCheckbox.m
//  
//
//  Created by Ivan Pavlovic on 4/27/12.
//  Copyright (c) 2012 City of Copenhagen. All rights reserved.
//

#import "SMCustomCheckbox.h"

@implementation SMCustomCheckbox

@synthesize on;

- (id) init {
    self = [super init];
    if (self) {
        [self setOn:NO];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateNormal];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateHighlighted];
        [self setImage:[[UIImage imageNamed:@"checkboxChecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateSelected];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateDisabled];
        [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setOn:NO];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateNormal];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateHighlighted];
        [self setImage:[[UIImage imageNamed:@"checkboxChecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateSelected];
        [self setImage:[[UIImage imageNamed:@"checkboxUnchecked"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:13.0f] forState:UIControlStateDisabled];
        [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
    }
    return self;
}

- (IBAction)buttonPressed:(id)sender {
    self.selected = !self.selected;
    [self setOn:self.selected];
}


@end
