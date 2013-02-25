//
//  SMGPSTrackButton.m
//  iBike
//
//  Created by Petra Markovic on 2/25/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMGPSTrackButton.h"

static void *kGPSTrackButtonStateObservingContext = &kGPSTrackButtonStateObservingContext;

@implementation SMGPSTrackButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.gpsTrackState = SMGPSTrackButtonStateFollowWithHeading;
    }
    return self;
}

- (void)awakeFromNib {
    [self setImage:[UIImage imageNamed:@"icon_locate_me_active"] forState:SMGPSTrackButtonStateFollowWithHeading];
    [self setImage:[UIImage imageNamed:@"icon_locate_me_active"] forState:SMGPSTrackButtonStateFollow];
    [self setImage:[UIImage imageNamed:@"icon_locate_me"] forState:SMGPSTrackButtonStateDoNotFollow];

    NSAssert(SMGPSTrackButtonStateFollowWithHeading & UIControlStateApplication, @"Custom state not within UIControlStateApplication");
    NSAssert(SMGPSTrackButtonStateFollow & UIControlStateApplication, @"Custom state not within UIControlStateApplication");
    NSAssert(SMGPSTrackButtonStateDoNotFollow & UIControlStateApplication, @"Custom state not within UIControlStateApplication");

    [self addObserver:self forKeyPath:@"gpsTrackState" options:NSKeyValueObservingOptionOld context:kGPSTrackButtonStateObservingContext];
}

- (UIControlState)state {
    NSInteger returnState = [super state];
    return (returnState | self.gpsTrackState);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kGPSTrackButtonStateObservingContext) {
        NSInteger oldState = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        if (oldState != self.gpsTrackState) {
            [self layoutSubviews];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
