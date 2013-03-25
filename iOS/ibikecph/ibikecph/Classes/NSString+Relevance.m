//
//  NSString+Relevance.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 19/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "NSString+Relevance.h"

@implementation NSString (Relevance)

- (NSInteger)numberOfOccurenciesOfString:(NSString*)str {
    NSInteger total = 0;
    
    NSRange rng = [self rangeOfString:str options:NSCaseInsensitiveSearch];
    
    while (rng.location != NSNotFound && rng.location < self.length) {
        total += 1;
        if ((rng.location + rng.length + 1) >= self.length) {
            return total;
        }
        rng = [self rangeOfString:str options:NSCaseInsensitiveSearch range:NSMakeRange(rng.location + rng.length + 1, self.length - rng.location - rng.length - 1)];
    }
    return total;
}

@end
