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

@interface SMTranslatedViewController : GAITrackedViewController

@property (nonatomic, weak) SMAppDelegate * appDelegate;

@end
