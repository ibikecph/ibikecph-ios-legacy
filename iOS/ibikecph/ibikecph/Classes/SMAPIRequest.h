//
//  SMAPIRequest.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 03/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMAPIRequest;

@protocol SMAPIRequestDelegate <NSObject>

- (void)request:(SMAPIRequest*)req completedWithResult:(NSDictionary*)result;
- (void)request:(SMAPIRequest*)req failedWithError:(NSError*)error;
- (void)serverNotReachable;
@end

@interface SMAPIRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, weak) id<SMAPIRequestDelegate> delegate;
@property (nonatomic, strong) NSString * requestIdentifier;
@property BOOL manualRemove;

- (id) initWithDelegeate:(id<SMAPIRequestDelegate>) dlg;
- (void)executeRequest:(NSDictionary*)request withParams:(NSDictionary*)params;
- (void)showTransparentWaitingIndicatorInView:(UIView*) view;
- (void)hideWaitingView;

@end
