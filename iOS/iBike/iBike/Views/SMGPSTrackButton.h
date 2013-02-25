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
    SMGPSTrackButtonStateNotFollowing_fromfollow = 0x00013000,
    SMGPSTrackButtonStateNotFollowing_fromfollowwithheading = 0x00014000
};

@property (nonatomic,assign) NSInteger gpsTrackState;

@end
