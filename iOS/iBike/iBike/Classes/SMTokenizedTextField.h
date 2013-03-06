//
//  SMTokenizedTextField.h
//  iBike
//
//  Created by Ivan Pavlovic on 06/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMTokenizedTextField : UIView <UITextFieldDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) id<UITextFieldDelegate>delegate;

@end
