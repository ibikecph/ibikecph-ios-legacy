//
//  SMTranslation.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMTranslation : NSObject

+ (SMTranslation *)instance;
+(NSString*)decodeString:(NSString*) txt;

+ (void) translateView:(id) view;

@end
