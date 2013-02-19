//
//  SMEnterEmailControllerViewController.h
//  iBike
//
//  Created by Ivan Pavlovic on 05/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMEnterEmailControllerViewController : UIViewController <UITextFieldDelegate> {
    
    __weak IBOutlet UITextField *emailField;
    __weak IBOutlet UIScrollView *scrlView;
}

@end
