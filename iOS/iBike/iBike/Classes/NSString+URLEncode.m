//
//  NSString+URLEncode.m
//  
//
//  Created by Ivan Pavlovic on 8/22/12.
//  Copyright (c) 2012 Spoiled Milk. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString*) urlEncode {
    NSString * strToEncode = self;
    NSString * encodedString = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                            NULL,
                                            (CFStringRef) strToEncode,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                   kCFStringEncodingUTF8 ));
    return encodedString;
}

@end
