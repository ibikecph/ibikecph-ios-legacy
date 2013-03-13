//
//  SMEnterRouteController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMEnterRouteController.h"
#import "SMAppDelegate.h"
#import "SMUtil.h"
#import "SBJson.h"
#import "SMLocationManager.h"
#import "SMEnterRouteCell.h"

@interface SMEnterRouteController ()
@property (nonatomic, strong) NSArray * groupedList;
@property (nonatomic, strong) NSMutableDictionary * fromData;
@property (nonatomic, strong) NSMutableDictionary * toData;
@end

@implementation SMEnterRouteController

- (void)viewDidLoad {
    [super viewDidLoad];
	[tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [fromLabel setText:CURRENT_POSITION_STRING];
    [toLabel setText:@""];
    
    self.fromData = nil;

    self.toData = nil;

    
    for (id v in tblView.subviews) {
        if ([v isKindOfClass:[UIScrollView class]]) {
            [v setDelegate: self];
        }
    }
}

- (void)viewDidUnload {
    fromLabel = nil;
    toLabel = nil;
    tblView = nil;
    fadeView = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - button actions

- (IBAction)swapFields:(id)sender {
    NSString * txt = fromLabel.text;
    fromLabel.text = toLabel.text;
    toLabel.text = txt;
    NSMutableDictionary * data = [self.fromData copy];
    self.fromData = self.toData;
    self.toData = data;
}

- (IBAction)goBack:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)findRoute:(id)sender {
    if (([toLabel.text isEqualToString:@""]) || ([fromLabel.text isEqualToString:@""])) {
        return;
    }
    
    if ([toLabel.text isEqualToString:CURRENT_POSITION_STRING]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_invalid_to_address") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    if ([fromLabel.text isEqualToString:CURRENT_POSITION_STRING]) {
        self.fromData = [NSMutableDictionary dictionaryWithDictionary:@{@"name" : CURRENT_POSITION_STRING,
                         @"address" : @"",
                         @"location" : [SMLocationManager instance].lastValidLocation
                         }];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"nearestPoint"];
    [r findNearestPointForStart:[self.fromData objectForKey:@"location"] andEnd:[self.toData objectForKey:@"location"]];
}


#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.auxParam isEqualToString:@"nearestPoint"]) {
        CLLocation * s = [res objectForKey:@"start"];
        CLLocation * e = [res objectForKey:@"end"];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", fromLabel.text, s.coordinate.latitude, s.coordinate.longitude, toLabel.text, e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:s.coordinate to:e.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        id jsonRoot = [[[SBJsonParser alloc] init] objectWithString:response];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            [UIView animateWithDuration:0.2f animations:^{
                [fadeView setAlpha:0.0f];
            }];
            [SMUtil saveToSearchHistory:@{
             @"name" : [self.toData objectForKey:@"name"],
             @"address" : [self.toData objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"searchHistory",
             @"subsource" : @"foursquare",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.longitude]
             }];
        }
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    }
}

#pragma mark - tap gesture

- (IBAction)labelTapped:(UITapGestureRecognizer*)recognizer {
    if (recognizer.view == fromLabel) {
        /**
         * FROM label tapped
         */
        debugLog(@"from");
    } else {
        /**
         * TO label tapped
         */
        debugLog(@"to");
    }
    
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groupedList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * currentRow = [self.groupedList objectAtIndex:indexPath.row];
    NSString * identifier = @"autocompleteCell";
    SMEnterRouteCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
    
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"fb"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
       if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteFoursquare"]];
        } else {
            [cell.iconImage setImage:nil];
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"searchHistory"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMEnterRouteCell getHeight];
}


@end
