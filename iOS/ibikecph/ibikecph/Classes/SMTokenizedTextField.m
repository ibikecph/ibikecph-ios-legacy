//
//  SMTokenizedTextField.m
//  iBike
//
//  Created by Ivan Pavlovic on 06/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTokenizedTextField.h"

@interface SMTokenizedTextField()
@property (nonatomic, strong) UITextField * txtField;
@property (nonatomic, strong) UIScrollView * scrlView;
@end

@implementation SMTokenButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.buttonIndex = -1;
        self.shouldBeDeleted = NO;
        [self setBackgroundImage:[[UIImage imageNamed:@"tokenNormal"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:12.0f] forState:UIControlStateNormal];
        [self setBackgroundImage:[[UIImage imageNamed:@"tokenHighlighted"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:12.0f] forState:UIControlStateHighlighted];
        [self setBackgroundImage:[[UIImage imageNamed:@"tokenHighlighted"] stretchableImageWithLeftCapWidth:13.0f topCapHeight:12.0f] forState:UIControlStateSelected];
        [self setBackgroundColor:[UIColor clearColor]];
        
        [self setContentEdgeInsets:UIEdgeInsetsMake(0.0f, 13.0f, 0.0f, 13.0f)];

    }
    return self;
}

- (void)setTitle:(NSString*)text {
    self.token = text;
    [self setTitle:text forState:UIControlStateNormal];
}

@end


@implementation SMTokenizedTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialSetup];
    }
    return self;
}

#pragma mark - setup

- (void)initialSetup {
    self.scrlView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    [self.scrlView setContentSize:self.frame.size];
    [self.scrlView setShowsHorizontalScrollIndicator:NO];
    [self.scrlView setShowsVerticalScrollIndicator:NO];
    [self.scrlView setBounces:NO];
    [self.scrlView setBackgroundColor:[UIColor clearColor]];
    [self.scrlView setDelegate:self];
    [self addSubview:self.scrlView];
    
    self.txtField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    [self.txtField setBackgroundColor:[UIColor clearColor]];
    [self.txtField setDelegate:self];
    [self.txtField setFont:[UIFont systemFontOfSize:14.0f]];
    [self.txtField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.txtField setBackgroundColor:[UIColor clearColor]];
    [self.txtField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [self.scrlView addSubview:self.txtField];
    
    [self.txtField setReturnKeyType:UIReturnKeyDone];
    
    self.tokens = [NSMutableArray array];
    
}

#pragma mark - UITextField methods

- (BOOL)becomeFirstResponder {
    return [self.txtField becomeFirstResponder];
}

- (NSString*)text {
    if ([self.tokens count] > 0) {
        NSMutableArray * arr = [NSMutableArray array];
        for (SMTokenButton * btn in self.tokens) {
            [arr addObject: btn.token];
        }
        return [arr componentsJoinedByString:@" "];
    } else {
        return self.txtField.text;
    }
    return @"";
}

- (void)setText:(NSString*)text {
    [self deleteTokens];
    [self.txtField setText:text];
}

- (void)setTextColor:(UIColor*)color {
    [self.txtField setTextColor:color];
}

- (UIReturnKeyType)returnKeyType {
    return self.txtField.returnKeyType;
}

- (void) setReturnKeyType:(UIReturnKeyType)returnKeyType { 
    [self.txtField setReturnKeyType:returnKeyType];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [self.delegate textFieldShouldBeginEditing:(UITextField*)self];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [self.delegate textFieldShouldReturn:(UITextField*)self];
    }
     return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textField:(UITextField*)self shouldChangeCharactersInRange:range replacementString:string];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        return [self.delegate textFieldShouldClear:(UITextField*)self];
    }
    return YES;
}


#pragma mark - tokenizing

- (void)resizeScrollView {
    CGFloat startX = 0.0f;
    for (UIButton * b in self.tokens) {
        startX += b.frame.size.width + 10.0f;
    }
    
    if (self.shouldHideTextField == NO || [self.tokens count] == 0) {
        CGRect frame = self.txtField.frame;
        frame.origin.x = startX;
        [self.txtField setFrame:frame];
        startX += frame.size.width;
    }
    
    [self.scrlView setContentSize:CGSizeMake(startX, self.scrlView.frame.size.height)];
}

- (BOOL)addToken:(NSString*)tokenText {
    SMTokenButton * btn = [[SMTokenButton alloc] initWithFrame:CGRectMake(0.0f, roundf((self.frame.size.height - 25.0f) / 2.0f), MIN([tokenText sizeWithFont:self.txtField.font].width + 35.0f, self.frame.size.width - 15.0f), 25.0f)];
    [btn.titleLabel setFont:self.txtField.font];
    [btn setTitle:tokenText];
    [btn addTarget:self action:@selector(deleteToken:) forControlEvents:UIControlEventTouchUpInside];
        
    CGFloat startX = 0.0f;
    for (UIButton * b in self.tokens) {
        startX += b.frame.size.width + 10.0f;
    }
    
    [self.tokens addObject:btn];
    [btn setButtonIndex:[self.tokens count] - 1];
    
    CGRect frame = btn.frame;
    frame.origin.x = startX;
    [btn setFrame:frame];
    [self.scrlView addSubview:btn];

    [self resizeScrollView];
    
    [self.scrlView setContentOffset:CGPointMake(startX, 0.0f)];

    if (self.shouldHideTextField) {
        [self.txtField setHidden:YES];
    }

    
    [self.txtField setText:@""];
    [self.txtField resignFirstResponder];
    
    
    return YES;
}

- (IBAction)deleteToken:(id)sender {
    SMTokenButton * btn = (SMTokenButton*)sender;
    
    [self.tokens removeObjectAtIndex:btn.buttonIndex];
    [btn removeFromSuperview];
    for (int i = 0; i < [self.tokens count]; i++) {
        SMTokenButton * btn = [self.tokens objectAtIndex:i];
        [btn setButtonIndex:i];
    }
    if ([self.tokens count] == 0) {
        [self.txtField setHidden:NO];
        [self.txtField becomeFirstResponder];
    }
    [self resizeScrollView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        [self.delegate textField:(UITextField*)self shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    }
}

- (void)setToken:(NSString*)text {
    [self deleteTokens];
    [self addToken:text];
}

- (void)deleteTokens {
    for (int i = 0; i < [self.tokens count]; i++) {
        SMTokenButton * btn = [self.tokens objectAtIndex:i];
        [btn removeFromSuperview];
    }
    [self.tokens removeAllObjects];
    [self.txtField setHidden:NO];
    [self.txtField becomeFirstResponder];

    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        [self.delegate textField:(UITextField*)self shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
    }
}

@end
