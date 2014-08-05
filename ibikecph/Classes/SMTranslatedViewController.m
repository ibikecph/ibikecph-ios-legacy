//
//  SMTranslatedViewController.m
//  iBike
//
//  Created by Ivan Pavlovic on 25/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"

@interface SMTranslatedViewController ()

@end

@implementation SMTranslatedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SMTranslation translateView:self.view];
    self.appDelegate = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    self.screenName = NSStringFromClass([self class]);
}

- (void)moveView {
//    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
//        [self.view setClipsToBounds:YES];
//        CGRect frame = self.view.bounds;
//        frame.origin.y = -20.0f;
//        frame.size.height -= 40.0f;
//        self.view.bounds = frame;
//    }
}

@end
