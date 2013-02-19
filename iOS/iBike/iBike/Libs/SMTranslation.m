//
//  SMTranslation.m
//  iBike
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMTranslation.h"

@interface SMTranslation()
@property (nonatomic, strong) NSMutableDictionary * dictionary;
@end

@implementation SMTranslation

+ (SMTranslation *)instance {
	static SMTranslation *instance;
	if (instance == nil) {
		instance = [[SMTranslation alloc] init];
        [instance loadStringsForLanguage:DEFAULT_LANGUAGE];
	}
	return instance;
}

#pragma mark - localization / string decoding

-(NSString *) stringByStrippingHTML:(NSString*) str {
    NSRange r;
    NSString *s = [str copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

//<Rasko>
-(void) loadStringsForLanguage:(NSString*)language{
    NSMutableDictionary * d = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[@"dictionary_" stringByAppendingString:language] ofType:@"strings"]];
    [self setDictionary:d];
}

-(NSString*)decodeString:(NSString*) txt{
    if(!self.dictionary) return txt;
    NSString * ret = [self.dictionary objectForKey:txt];
    if(!ret) return txt;
    return ret;
}

+(NSString*)decodeString:(NSString*) txt{
    return [[SMTranslation instance] decodeString:txt];
}


@end
