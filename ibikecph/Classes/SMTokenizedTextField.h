//
//  SMTokenizedTextField.h
//  iBike
//
//  Created by Ivan Pavlovic on 06/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMTokenButton : UIButton
@property BOOL shouldBeDeleted;
@property NSInteger buttonIndex;
@property (nonatomic, strong) NSString * token;
@end


@interface SMTokenizedTextField : UIView <UITextFieldDelegate, UIScrollViewDelegate>

/**
 * textfield stuff
 */
@property (nonatomic, weak) id<UITextFieldDelegate>delegate;
@property (nonatomic, strong) NSString * text;
@property BOOL shouldHideTextField;

- (void)setTextColor:(UIColor*)color;
@property UIReturnKeyType returnKeyType;

/**
 * tokens list
 */
@property (nonatomic, strong) NSMutableArray * tokens;

/**
 * add token to the list
 */
- (BOOL)addToken:(NSString*)tokenText;
/**
 * replace all tokens with a given token
 */
- (void)setToken:(NSString*)text;
/**
 * remove all tokens
 */
- (void)deleteTokens;

@end
