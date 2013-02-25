//
//  SMGPSTrackButton.h
//  iBike
//
//  Created by Petra Markovic on 2/25/13.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMGPSTrackButton : UIButton

enum {
    SMGPSTrackButtonStateFollowing = 0x00011000,
    SMGPSTrackButtonStateFollowingWithHeading = 0x00012000,
    SMGPSTrackButtonStateNotFollowing = 0x00013000,
};

@property (nonatomic,assign,readonly) NSInteger prevGpsTrackState;
@property (nonatomic,assign,readonly) NSInteger gpsTrackState;

- (void)newGpsTrackState:(NSInteger)gpsTrackState;

@end
