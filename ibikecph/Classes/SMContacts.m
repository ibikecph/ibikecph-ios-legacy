//
//  SMContacts.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMContacts.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@implementation SMContacts

@synthesize delegate;

- (id)initWithDelegate:(id<SMContactsDelegate>) dlg {
    self = [super init];
    if (self) {
        self.delegate = dlg;
    }
    return self;
}


-(BOOL)isABAddressBookCreateWithOptionsAvailable {
    return &ABAddressBookCreateWithOptions != NULL;
}

-(void)loadContacts {
    ABAddressBookRef addressBook;
    if ([self isABAddressBookCreateWithOptionsAvailable]) {
        CFErrorRef error = nil;
        addressBook = ABAddressBookCreateWithOptions(NULL,&error);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // callback can occur in background, address book must be accessed on thread it was created on
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    if (self.delegate) {
                        [self.delegate addressBookHelperError:self];
                    }
                } else if (!granted) {
                    if (self.delegate) {
                        [self.delegate addressBookHelperDeniedAcess:self];
                    }
                } else {
                    // access granted
                    AddressBookUpdated(addressBook, nil, self);
                    CFRelease(addressBook);
                }
            });
        });
    } else {
        // iOS 4/5
        addressBook = ABAddressBookCreate();
        AddressBookUpdated(addressBook, NULL, self);
        CFRelease(addressBook);
    }
}

void AddressBookUpdated(ABAddressBookRef addressBook, CFDictionaryRef info, SMContacts* helper) {
    
    CFArrayRef allPeopleRef = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    NSMutableArray * people = [NSMutableArray array];
    
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef thisPerson = CFArrayGetValueAtIndex(allPeopleRef,i);
        
        NSString * contactFirstLast = nil;
        
        if (ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty)) {
            contactFirstLast = [NSString stringWithFormat:@"%@", ABRecordCopyValue(thisPerson, kABPersonFirstNameProperty)];
        }
        
        if (ABRecordCopyValue(thisPerson,kABPersonLastNameProperty)) {
            if (contactFirstLast) {
                contactFirstLast = [NSString stringWithFormat:@"%@ %@", contactFirstLast, ABRecordCopyValue(thisPerson, kABPersonLastNameProperty)];
            } else {
                contactFirstLast = [NSString stringWithFormat:@"%@", ABRecordCopyValue(thisPerson, kABPersonLastNameProperty)];
            }
        }
        
        if (ABRecordCopyValue(thisPerson,kABPersonOrganizationProperty)) {
            if (contactFirstLast) {
                contactFirstLast = [NSString stringWithFormat:@"%@ %@", contactFirstLast, ABRecordCopyValue(thisPerson, kABPersonOrganizationProperty)];
            } else {
                contactFirstLast = [NSString stringWithFormat:@"%@", ABRecordCopyValue(thisPerson, kABPersonOrganizationProperty)];
            }
        }
        
        if (contactFirstLast == nil) {
            contactFirstLast = @"";
        }
        
        
        NSString *address = nil;
        
        ABMultiValueRef st = ABRecordCopyValue(thisPerson, kABPersonAddressProperty);
        NSInteger n = ABMultiValueGetCount(st);
        if (n > 0) {
            CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(st, 0);
            address = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
            if (CFDictionaryGetValue(dict, kABPersonAddressCityKey)) {
                address = [NSString stringWithFormat:@"%@, %@", address, CFDictionaryGetValue(dict, kABPersonAddressCityKey)];
            }
            if (CFDictionaryGetValue(dict, kABPersonAddressCountryKey)) {
                address = [NSString stringWithFormat:@"%@, %@", address, CFDictionaryGetValue(dict, kABPersonAddressCountryKey)];
            }
        }
        
        CFRelease(st);
        
        
        if (contactFirstLast && address) {
            NSMutableDictionary * cnt = [@{
                                         @"name" : contactFirstLast,
                                         @"source" : @"contacts",
                                         @"address" : [address stringByReplacingOccurrencesOfString:@"\n" withString:@", "]
                                         } mutableCopy];

            CFDataRef imageData = ABPersonCopyImageData(thisPerson);
            UIImage *image = [UIImage imageWithData:(__bridge NSData *)imageData];
//            CFRelease(imageData);
            
            if (image) {
                [cnt setValue:image forKey:@"image"];
            }
            
            [people addObject:cnt];
        }
        
        
        
    }

    CFRelease(allPeopleRef);
    
    if (helper.delegate) {
        [[helper delegate] addressBookHelper:helper finishedLoading:people];        
    }
};

@end
