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
    autocompleteQuery,
    autocompleteFoursquare
} AutocompleteType;

@interface SMAutocomplete : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    AutocompleteType completeType;
}

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg;

- (void)getAutocomplete:(NSString*)str;
- (void)getOiorestAutocomplete;
- (void)getGooglePlacesAutocomplete;
- (void)getGoogleQueryAutocomplete;
- (void)getFoursquareAutocomplete;

@end
