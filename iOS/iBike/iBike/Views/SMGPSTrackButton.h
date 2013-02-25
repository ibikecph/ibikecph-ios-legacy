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
    SMGPSTrackButtonStateFollow = 0x00010000,
    SMGPSTrackButtonStateFollowWithHeading = 0x00020000,
    SMGPSTrackButtonStateDoNotFollow = 0x00030000
};

@property (nonatomic,assign) NSInteger gpsTrackState;

@end
