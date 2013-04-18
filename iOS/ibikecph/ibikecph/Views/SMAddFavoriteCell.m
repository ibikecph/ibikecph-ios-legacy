//
//  SMAddFavoriteCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAddFavoriteCell.h"

@implementation SMAddFavoriteCell

+ (CGFloat)getHeight {
    return 46.0f;
}

+ (SMAddFavoriteCell*) getFromNib {
    SMAddFavoriteCell * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMAddFavoriteCell" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMAddFavoriteCell class]]) {
            xx = (SMAddFavoriteCell *)currentObject;
            break;
        }
    }
    return xx;
}

- (IBAction)viewTapped:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewTapped:)]) {
        [self.delegate viewTapped:self];
    }
}


@end
