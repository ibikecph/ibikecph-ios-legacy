//
//  SMTranslation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslation.h"

@interface UIView(SMViewForTranslation)
-(void) viewTranslated;
@end

@implementation UIView(SMViewForTranslation)
-(void) viewTranslated{}
@end

@interface SMTranslation()
@property (nonatomic, strong) NSMutableDictionary * dictionary;
@end

@implementation SMTranslation

+ (SMTranslation *)instance {
	static SMTranslation *instance;
	if (instance == nil) {
		instance = [[SMTranslation alloc] init];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        if (![defaults stringForKey:@"appLanguage"]) {
//            /**
//             * init default settings
//             */
//            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//            NSArray* languages = [defaults objectForKey:@"AppleLanguages"];
//            NSDictionary *appDefaults;
//            if ([[languages objectAtIndex:0] isEqualToString:@"da"] || [[languages objectAtIndex:0] isEqualToString:@"dan"]) {
//                appDefaults = [NSDictionary dictionaryWithObject:@"dk" forKey:@"appLanguage"];
//            } else {
//                appDefaults = [NSDictionary dictionaryWithObject:@"en" forKey:@"appLanguage"];
//            }
//            [defaults registerDefaults:appDefaults];
//            [defaults synchronize];
//        }
        NSString * language = [defaults stringForKey:@"appLanguage"];
        
        [instance loadStringsForLanguage:language];
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

+ (void) translateView:(id) view {
    if ([view isKindOfClass:[UILabel class]]) {
        NSString * response = [self decodeString:((UILabel*)view).text];
        [(UILabel*)view setText:response];
    } else if ([view isKindOfClass:[UITextView class]]) {
        NSString * response = [self decodeString:((UITextView*)view).text];
        [(UITextView*)view setText:response];
    } else if ([view isKindOfClass:[UISearchBar class]]) {
        NSString * response = [self decodeString:((UISearchBar*)view).placeholder];
        [(UISearchBar*)view setPlaceholder:response];
    } else if ([view isKindOfClass:[UITextField class]]) {
        NSString * response = [self decodeString:((UITextField*)view).placeholder];
        [(UITextField*)view setPlaceholder:response];
        response = [self decodeString:((UITextField*)view).text];
        [(UITextField*)view setText:response];
    } else if ([view isKindOfClass:[UIButton class]]) {
        NSString * response = [self decodeString:((UIButton*)view).titleLabel.text];
        [((UIButton*)view) setTitle:response forState:UIControlStateNormal];
        [((UIButton*)view) setTitle:response forState:UIControlStateHighlighted];
    } else if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl * c = (UISegmentedControl*)view;
        for (int i = 0; i < c.numberOfSegments; i++) {
            [c setTitle:[self decodeString:[c titleForSegmentAtIndex:i]] forSegmentAtIndex:i];
        }
    }
    
    if([view respondsToSelector:@selector(viewTranslated)]){
        [view viewTranslated];
    }
    
    if (((UIView*)view).subviews) {
        for (id v in ((UIView*)view).subviews) {
            [SMTranslation translateView:v];
        }
    }
}


@end
