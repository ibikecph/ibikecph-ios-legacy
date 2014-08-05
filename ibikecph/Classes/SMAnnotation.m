//
//  SMAnnotation.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 04/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAnnotation.h"
#import "RMMapView.h"

@implementation SMAnnotation

- (void)showCallout {
    self.calloutShown = YES;
    if (self.calloutView == nil) {
        SMCalloutView * v = [SMCalloutView getFromNib];
        [v setDelegate:self];
        [v.calloutLabel setText:self.title];
        [v.calloutSublabel setText:self.subtitle];
        CGRect frame = v.frame;
        CGPoint point = [self.mapView coordinateToPixel:self.coordinate];
        
        frame.size.width = MAX([v.calloutLabel.text sizeWithFont:[UIFont systemFontOfSize:15.0f]].width, [v.calloutSublabel.text sizeWithFont:[UIFont systemFontOfSize:15.0f]].width) + 70.0f;
        if (frame.size.width > self.mapView.frame.size.width) {
            frame.size.width = self.mapView.frame.size.width;
        }
        
        frame.size.width = MAX(177.0f, frame.size.width);
        
        frame.origin.x = point.x - roundf(frame.size.width/2.0f) + 4.0f;
        frame.origin.y = point.y - 95.0f;
        
        [v setFrame:frame];
        
        CGFloat width = roundf((frame.size.width - 60.0f) / 2.0f);
        
        [v.bgLeft setFrame:CGRectMake(0.0f, 0.0f, width, frame.size.height)];
        [v.bgLeft setImage:[UIImage imageNamed:@"calloutBubbleLeft"]];
        
        width = frame.size.width - 60.0f - width;
        [v.bgRight setFrame:CGRectMake(frame.size.width - width, 0.0f, width, frame.size.height)];
        [v.bgRight setImage:[UIImage imageNamed:@"calloutBubbleRight"]];

        
        [v.bgMiddle setFrame:CGRectMake(v.bgLeft.frame.size.width, 0.0f, 60.0f, frame.size.height)];
        [v.bgMiddle setImage:[UIImage imageNamed:@"calloutBubbleMiddle"]];
        
        
        [self setCalloutView:v];
        [self.mapView addSubview:self.calloutView];
    } else {
        if (self.calloutView.superview == nil) {
            CGRect frame = self.calloutView.frame;
            CGPoint point = [self.mapView coordinateToPixel:self.coordinate];
            frame.origin.x = point.x - roundf(frame.size.width/2.0f) + 4.0f;
            frame.origin.y = point.y - 95.0f;
            [self.calloutView setFrame:frame];
            [self.mapView addSubview:self.calloutView];
        } else {
            CGRect frame = self.calloutView.frame;
            CGPoint point = [self.mapView coordinateToPixel:self.coordinate];
            frame.origin.x = point.x - roundf(frame.size.width/2.0f) + 4.0f;
            frame.origin.y = point.y - 95.0f;
            [self.calloutView setFrame:frame];
        }
    }
}

- (void)hideCallout {
    self.calloutShown = NO;
    if (self.calloutView && self.calloutView.superview) {
        [self.calloutView removeFromSuperview];
    }
}

- (void)buttonClicked {
    if (self.delegate) {
        [self.delegate annotationActivated:self];
    }
}

@end
