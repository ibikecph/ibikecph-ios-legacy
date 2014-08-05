//
//  SMGPSTrackButton.h
//  iBike
//
//  Created by Petra Markovic on 2/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SMGPSTrackButtonStateFollowing,
    SMGPSTrackButtonStateFollowingWithHeading,
    SMGPSTrackButtonStateNotFollowing
} ButtonStateType;

@interface SMGPSTrackButton : UIButton

@property (nonatomic,readonly) ButtonStateType gpsTrackState;
@property (nonatomic, readonly) ButtonStateType prevGpsTrackState;

- (void)newGpsTrackState:(ButtonStateType)gpsTrackState;

@end
