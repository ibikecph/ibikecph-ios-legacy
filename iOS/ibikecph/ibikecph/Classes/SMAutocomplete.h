//
//  SMAutocomplete.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 30/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMAutocompleteDelegate <NSObject>
- (void)autocompleteEntriesFound:(NSArray*)arr forString:(NSString*) str;
@end

@interface SMAutocomplete : NSObject

- (id)initWithDelegate:(id<SMAutocompleteDelegate>)dlg;

- (void)getAutocomplete:(NSString*)str;
- (void)getOiorestAutocomplete;
- (void)getFoursquareAutocomplete;
- (void)getKortforsyningenAutocomplete;
@end
