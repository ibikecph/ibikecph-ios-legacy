//
//  SMTranslatedViewController.h
//  iBike
//
//  Created by Ivan Pavlovic on 25/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMAppDelegate.h"
#import "GAITrackedViewController.h"

/**
 * \ingroup libs
 * Base class for all the views
 *
 * Handles translation
 */
@interface SMTranslatedViewController : GAITrackedViewController

@property (nonatomic, weak) SMAppDelegate * appDelegate;


- (void)moveView;

@end
