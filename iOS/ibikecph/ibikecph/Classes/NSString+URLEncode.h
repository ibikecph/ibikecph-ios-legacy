//
//  NSString+URLEncode.h
//  
//
//  Created by Ivan Pavlovic on 8/22/12.
//  Copyright (c) 2012 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 * \ingroup libs
 * \ingroup sm
 * URL encode a string
 */
@interface NSString (URLEncode)

- (NSString*) urlEncode;
- (NSString*)removeAccents;

@end
