//
//  SMGPSTrackButton.m
//  iBike
//
//  Created by Petra Markovic on 2/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMGPSTrackButton.h"

static void *kGPSTrackButtonStateObservingContext = &kGPSTrackButtonStateObservingContext;

@implementation SMGPSTrackButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _gpsTrackState = SMGPSTrackButtonStateFollowingWithHeading;
        [self drawNewImage];
    }
    return self;
}

- (void)drawNewImage {
    switch (_gpsTrackState) {
//        case SMGPSTrackButtonStateFollowingWithHeading:
        case SMGPSTrackButtonStateFollowing:
            [self setImage:[UIImage imageNamed:@"icon_locate_me"] forState:UIControlStateNormal];
            break;
        case SMGPSTrackButtonStateFollowingWithHeading:
            [self setImage:[UIImage imageNamed:@"icon_locate_heading"] forState:UIControlStateNormal];
            break;
        case SMGPSTrackButtonStateNotFollowing:
            [self setImage:[UIImage imageNamed:@"icon_locate_no_tracking"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)newGpsTrackState:(ButtonStateType)gpsTrackState {
    if (_gpsTrackState != gpsTrackState) {
        debugLog(@"new GPS tracking button state: %@", gpsTrackState == SMGPSTrackButtonStateFollowing ? @"SMGPSTrackButtonStateFollowing" : (gpsTrackState == SMGPSTrackButtonStateFollowingWithHeading ? @"SMGPSTrackButtonStateFollowingWithHeading" : @"SMGPSTrackButtonStateNotFollowing"));
        _prevGpsTrackState = self.gpsTrackState;
        _gpsTrackState = gpsTrackState;
        [self drawNewImage];
    }
}

@end
