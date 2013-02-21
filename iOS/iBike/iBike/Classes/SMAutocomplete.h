//
//  SMAutocomplete.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMAutocompleteDelegate <NSObject>
- (void)autocompleteEntriesFound:(NSArray*)arr forString:(NSString*) str;
@end

typedef enum {
    autocompletePlaces,
    autocompleteOiorest,
    autocompleteQuery
} AutocompleteType;

@interface SMAutocomplete : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    AutocompleteType completeType;
}

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg;

- (void)getOiorestAutocomplete:(NSString*)str;
- (void)getGooglePlacesAutocomplete:(NSString*)str;
- (void)getGoogleQueryAutocomplete:(NSString*)str;

@end
