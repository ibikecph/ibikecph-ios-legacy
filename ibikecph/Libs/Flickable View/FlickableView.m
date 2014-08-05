//
//  FlickableView.m
//  FlickableView
//
//  Created by Ivan Pavlovic on 05/05/2013.
//  Copyright (c) 2013. Ivan Pavlovic. All rights reserved.
//

#import "FlickableView.h"

typedef enum {
    fvHorizontal,
    fvVertical,
    fvNone
} FlickableViewType;

#define DEFAULT_THRESHOLD 40.0f;
#define FLICK_SPEED 0.2f

@interface FlickableView() {
    FlickableViewType swipeDirection;
    BOOL blockTouch;
    CGPoint startTouch;
}


@end

@implementation FlickableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        swipeDirection = fvNone;
        blockTouch = NO;
        self.threshold = DEFAULT_THRESHOLD;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        swipeDirection = fvNone;
        blockTouch = NO;
        self.threshold = DEFAULT_THRESHOLD;
    }
    return self;
}

#pragma mark - view setup

- (void)setupForHorizontalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end {
    self.startPos = start;
    self.endPos = end;
    swipeDirection = fvHorizontal;
    
    CGRect frame = self.frame;
    frame.origin.x = self.startPos;
    [self setFrame:frame];
    
    [self setGestureRecognizers:@[]];
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [pan setDelegate:self];
    [pan setCancelsTouchesInView:YES];
    [self addGestureRecognizer:pan];
}

- (void)setupForVerticalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end {
    self.startPos = start;
    self.endPos = end;
    swipeDirection = fvVertical;
    
    CGRect frame = self.frame;
    frame.origin.y = self.startPos;
    [self setFrame:frame];

    [self setGestureRecognizers:@[]];
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [pan setDelegate:self];
    [pan setCancelsTouchesInView:YES];
    [self addGestureRecognizer:pan];
}

- (void)setupForHorizontalSwipeWithStart:(CGFloat)start andEnd:(CGFloat)end andStart:(CGFloat)pos andPullView:(UIView*)pullView {
    self.startPos = start;
    self.endPos = end;
    swipeDirection = fvHorizontal;
    
    CGRect frame = self.frame;
    frame.origin.x = pos;
    [self setFrame:frame];
    
    [pullView setGestureRecognizers:@[]];
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [pan setDelegate:self];
    [pullView addGestureRecognizer:pan];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [pullView addGestureRecognizer:tap];

    [pan requireGestureRecognizerToFail:tap];
}

- (void)addPullView:(UIView*)pullView {
    [pullView setGestureRecognizers:@[]];
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [pan setDelegate:self];
    [pullView addGestureRecognizer:pan];
}



#pragma mark - gesture recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (IBAction)onTap:(UITapGestureRecognizer*)tap {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.frame;
        if (swipeDirection == fvHorizontal) {
            if (frame.origin.x == self.startPos) {
                frame.origin.x = self.endPos;
            } else if (frame.origin.x == self.endPos) {
                frame.origin.x = self.startPos;
            }
        } else {
            if (frame.origin.y == self.startPos) {
                frame.origin.y = self.endPos;
            } else if (frame.origin.y == self.endPos) {
                frame.origin.y = self.startPos;
            }        
        }
        [self setFrame:frame];
    }];
}

- (IBAction)onPan:(UIPanGestureRecognizer*)pan {
    if (blockTouch) {
        return;
    }
    CGPoint point = [pan locationInView:self.superview];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        startTouch = [pan locationInView:self];
        if (swipeDirection == fvHorizontal) {
            self.originalPos = self.frame.origin.x;
        } else {
            self.originalPos = self.frame.origin.y;
        }
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        
        point.x -= startTouch.x;
        point.y -= startTouch.y;
        if (swipeDirection == fvHorizontal) {
            if (point.x >= self.startPos && point.x <= self.endPos) {
                CGRect frame = self.frame;
                frame.origin.x = point.x;
                [self setFrame:frame];
            }
        } else {
            if (point.y >= self.startPos && point.y <= self.endPos) {
                CGRect frame = self.frame;
                frame.origin.y = point.y;
                [self setFrame:frame];
            }
        }
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        point.x -= startTouch.x;
        point.y -= startTouch.y;
        if (swipeDirection == fvHorizontal) {
            if ([pan velocityInView:self.superview].x > 1000) {
                blockTouch = YES;
                [UIView animateWithDuration:MIN(0.2f,ABS((self.endPos-point.x)/[pan velocityInView:self.superview].x)) animations:^{
                    CGRect frame = self.frame;
                    frame.origin.x = self.endPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.endPos;
                }];
            } else if ([pan velocityInView:self.superview].x < -1000) {
                blockTouch = YES;
                [UIView animateWithDuration:MIN(0.2f,ABS((self.endPos-point.x)/[pan velocityInView:self.superview].x)) animations:^{
                    CGRect frame = self.frame;
                    frame.origin.x = self.startPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.startPos;
                }];
            } else if (self.originalPos == self.startPos && (point.x - self.originalPos) >= self.threshold) {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.x = self.endPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.endPos;
                }];
            } else if (self.originalPos == self.endPos && (self.originalPos - point.x) >= self.threshold) {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.x = self.startPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.startPos;
                }];
            } else {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.x = self.originalPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                }];
            }
        } else {
            if ([pan velocityInView:self.superview].y > 1000) {
                blockTouch = YES;
                [UIView animateWithDuration:MIN(0.2f,ABS((self.endPos-point.x)/[pan velocityInView:self.superview].y)) animations:^{
                    CGRect frame = self.frame;
                    frame.origin.y = self.endPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.endPos;
                }];
            } else if ([pan velocityInView:self.superview].y < -1000) {
                blockTouch = YES;
                [UIView animateWithDuration:MIN(0.2f,ABS((self.endPos-point.x)/[pan velocityInView:self.superview].y))  animations:^{
                    CGRect frame = self.frame;
                    frame.origin.y = self.startPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.startPos;
                }];
            } else if (self.originalPos == self.startPos && (point.y - self.originalPos) >= self.threshold) {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.y = self.endPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.endPos;
                }];
            } else if (self.originalPos == self.endPos && (self.originalPos - point.y) >= self.threshold) {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.y = self.startPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                    self.originalPos = self.startPos;
                }];
            } else {
                blockTouch = YES;
                [UIView animateWithDuration:FLICK_SPEED animations:^{
                    CGRect frame = self.frame;
                    frame.origin.y = self.originalPos;
                    [self setFrame:frame];
                } completion:^(BOOL finished) {
                    blockTouch = NO;
                }];
            }
        }
    }
    
}

@end
