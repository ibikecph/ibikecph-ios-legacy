//
//  SMAddressParser.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMAddressParser : NSObject

+ (NSDictionary*)parseAddress:(NSString*)addressString;

+ (void)parseTest;

@end
