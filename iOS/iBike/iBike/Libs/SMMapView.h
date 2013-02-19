//
//  SMMapView.h
//  iBike
//
//  Created by Ivan Pavlovic on 19/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "RMMapView.h"

@interface SMMapView : RMMapView

/**
 * Should we trigger update on heading change?
 */
@property BOOL triggerUpdateOnHeadingChange;
/**
 * Should we rotate the map on heading change?
 */
@property BOOL rotateOnHeadingChange;

@end
