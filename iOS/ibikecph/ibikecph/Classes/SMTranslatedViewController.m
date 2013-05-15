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
    self.trackedViewName = NSStringFromClass([self class]);
}

@end
