//
//  SMTokenizedTextField.m
//  iBike
//
//  Created by Ivan Pavlovic on 06/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMTokenizedTextField.h"

@interface SMTokenizedTextField()
@property (nonatomic, strong) UITextField * txtField;
@property (nonatomic, strong) UIScrollView * scrlView;
@property (nonatomic, strong) NSMutableArray * tokens;
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
    [self.scrlView addSubview:self.txtField];
    
    self.tokens = [NSMutableArray array];
    
}

#pragma mark - UITextField methods

- (NSString*)text {
    return self.txtField.text;
}

- (void)setText:(NSString*)text {
    [self.txtField setText:text];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [self.delegate textFieldShouldBeginEditing:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [self.delegate textFieldShouldReturn:textField];
    }
     return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        return [self.delegate textFieldShouldClear:textField];
    }
    return YES;
}


#pragma mark - tokenizing

- (BOOL)addToken:(NSString*)tokenText {
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0.0f, 0.0f, [tokenText sizeWithFont:[UIFont systemFontOfSize:17.0f]].width + 15.0f, 25.0f)];
    [btn setTitle:tokenText forState:UIControlStateNormal];
    
    CGFloat startX = 0.0f;
    for (UIButton * b in self.tokens) {
        startX += b.frame.size.width + 10.0f;
    }
    
    CGRect frame = btn.frame;
    frame.origin.x = startX;
    [btn setFrame:frame];
    
    [self.scrlView addSubview:btn];
    
    return YES;
}

@end
