//
//  SMContacts.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMContacts;

@protocol SMContactsDelegate <NSObject>

- (void)addressBookHelperError:(SMContacts*) obj;
- (void)addressBookHelperDeniedAcess:(SMContacts*) obj;
- (void)addressBookHelper:(SMContacts*)helper finishedLoading:(NSArray*)contacts;
@end

/**
 * \ingroup libs
 * Contact list import
 */

@interface SMContacts : NSObject

@property (nonatomic, weak) id<SMContactsDelegate> delegate;

- (void)loadContacts;

- (id)initWithDelegate:(id<SMContactsDelegate>) dlg;

@end
