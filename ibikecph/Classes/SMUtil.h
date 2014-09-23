//
//  SMUtil.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _registrationValidationResult{
    RVR_REGISTRATION_DATA_VALID,
    RVR_EMPTY_FIELDS,
    RVR_INVALID_EMAIL,
    RVR_PASSWORD_TOO_SHORT,
    RVR_PASSWORDS_DOESNT_MATCH
    
} eRegistrationValidationResult;

@protocol ViewTapDelegate <NSObject>
- (void)viewTapped:(id)view;
@end

/**
 * \ingroup libs
 * Various utils
 */

@interface SMUtil : NSObject


//// Format distance string (choose between meters and kilometers)
//NSString *formatDistance(float distance);
//// Format time duration string (choose between seconds and hours)
//NSString *formatTime(float seconds);
//// Format time passed between two dates
//NSString *formatTimePassed(NSDate *startDate, NSDate *endDate);
//// Calculate how many calories are burned given speed and time spent cycling
//float caloriesBurned(float avgSpeed, float timeSpent);
//// Calculate expected arrival time
//NSString *expectedArrivalTime(NSInteger seconds);
//
//NSString *formatTimeLeft(NSInteger seconds);
//
///**
// * creates filename from current timestamp
// */
//+ (NSString*)routeFilenameFromTimestampForExtension:(NSString*) ext;
//
//+ (NSInteger)pointsForName:(NSString*)name andAddress:(NSString*)address andTerms:(NSString*)srchString;

/**
 * check if email is valid
 */
+ (BOOL) isEmailValid:(NSString*) email;
/**
 * registration validation
 */
+ (eRegistrationValidationResult) validateRegistrationName:(NSString*)name Email:(NSString*) email Password:(NSString*) pass AndRepeatedPassword:(NSString*)repPass;

@end
