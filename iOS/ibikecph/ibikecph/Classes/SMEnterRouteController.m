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
#import "SMLocationManager.h"
#import "SMEnterRouteCell.h"
#import "SMAutocompleteHeader.h"
#import "SMViewMoreCell.h"

typedef enum {
    fieldTo,
    fieldFrom
} CurrentField;

@interface SMEnterRouteController () {
    CurrentField delegateField;
    BOOL favoritesOpen;
    BOOL historyOpen;
}
@property (nonatomic, strong) NSArray * groupedList;
@property (nonatomic, strong) NSDictionary * fromData;
@property (nonatomic, strong) NSDictionary * toData;
@end

@implementation SMEnterRouteController

#define MAX_FAVORITES 3
#define MAX_HISTORY 10

- (void)viewDidLoad {
    [super viewDidLoad];
    
    favoritesOpen = NO;
    historyOpen = NO;
    
	[tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [fromLabel setText:CURRENT_POSITION_STRING];
    [locationArrow setHidden:NO];
    CGRect frame = fromLabel.frame;
    frame.origin.x = locationArrow.frame.origin.x + 20.0f;
    frame.size.width = 269.0f - frame.origin.x;
    [fromLabel setFrame:frame];
    [fromLabel setTextColor:[UIColor colorWithRed:39.0f/255.0f green:111.0f/255.0f blue:183.0f/255.0f alpha:1.0f]];
    
    
    
    [toLabel setText:@""];
    
    self.fromData = nil;

    self.toData = nil;

    
    for (id v in tblView.subviews) {
        if ([v isKindOfClass:[UIScrollView class]]) {
            [v setDelegate: self];
        }
    }
    
    
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * saved = [SMUtil getFavorites];
    /**
     * add saved routes here
     */
    
    
    /**
     * add latest 10 searches
     */
    NSMutableArray * last = [NSMutableArray array];
    for (int i = 0; i < MIN(10, [appd.searchHistory count]); i++) {
        BOOL found = NO;
        NSDictionary * d = [appd.searchHistory objectAtIndex:i];
        for (NSDictionary * d1 in last) {
            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                found = YES;
                break;
            }
        }
        if (found == NO) {
            [last addObject:d];
        }
    }
    
    [self setGroupedList:@[saved, last]];
    [tblView reloadData];

}

- (void)viewDidUnload {
    fromLabel = nil;
    toLabel = nil;
    tblView = nil;
    fadeView = nil;
    locationArrow = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [super viewWillDisappear:animated];
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
    NSDictionary * data = [self.fromData copy];
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
    
    if ([[self.toData objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_invalid_to_address") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    if (self.fromData == nil) {
        if ([SMLocationManager instance].hasValidLocation == NO) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            return;            
        } else {
            self.fromData = [NSMutableDictionary dictionaryWithDictionary:@{@"name" : CURRENT_POSITION_STRING,
                             @"address" : @"",
                             @"location" : [SMLocationManager instance].lastValidLocation
                             }];
        }
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"nearestPoint"];
    [r findNearestPointForStart:[self.fromData objectForKey:@"location"] andEnd:[self.toData objectForKey:@"location"]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"searchSegue"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        switch (delegateField) {
            case fieldFrom:
                [destViewController setSearchText:fromLabel.text];
                break;
            case fieldTo:
                [destViewController setSearchText:toLabel.text];
                break;
            default:
                break;
        }
       
    }
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
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
            
            
        } else {
            [SMUtil saveToSearchHistory:@{
             @"name" : [self.toData objectForKey:@"name"],
             @"address" : [self.toData objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"searchHistory",
             @"subsource" : @"",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.longitude],
             @"order" : @1
             }];
            
            [self.delegate findRouteFrom:((CLLocation*)[self.fromData objectForKey:@"location"]).coordinate to:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate fromAddress:fromLabel.text toAddress:toLabel.text withJSON:jsonRoot];
            [self dismissViewControllerAnimated:YES completion:^{
            }];
            
        }
        [UIView animateWithDuration:0.2f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    }
}

#pragma mark - tap gesture

- (IBAction)labelTapped:(UITapGestureRecognizer*)recognizer {
    delegateField = fieldFrom;
    [self performSegueWithIdentifier:@"searchSegue" sender:nil];
}

- (IBAction)toTapped:(id)sender {
    delegateField = fieldTo;
    [self performSegueWithIdentifier:@"searchSegue" sender:nil];
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groupedList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [[self.groupedList objectAtIndex:section] count];
    if (section == 0) {
        if (count > MAX_FAVORITES) {
            if (favoritesOpen) {
                return count + 1;
            } else {
                return MAX_FAVORITES + 1;
            }
        } else {
            return count;
        }
    } else if (section == 1) {
        if (count > MAX_HISTORY) {
            if (historyOpen) {
                return count + 1;
            } else {
                return MAX_HISTORY + 1;
            }
        } else {
            return count;
        }        
    }
    return count;
}

- (BOOL)isCountButton:(NSIndexPath*)indexPath {
    NSInteger count = [[self.groupedList objectAtIndex:indexPath.section] count];
    if (indexPath.section == 0) {
        if (count > MAX_FAVORITES) {
            if (favoritesOpen) {
                if (indexPath.row == count) {
                    return YES;
                }
            } else {
                if (indexPath.row == MAX_FAVORITES) {
                    return YES;
                }
            }
        }
    } else if (indexPath.section == 1) {
        if (count > MAX_HISTORY) {
            if (historyOpen) {
                if (indexPath.row == count) {
                    return YES;
                }
            } else {
                if (indexPath.row == MAX_HISTORY) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self isCountButton:indexPath]) {
        SMViewMoreCell * cell = [tableView dequeueReusableCellWithIdentifier:@"viewMoreCell"];
        if (indexPath.section == 0) {
            if (favoritesOpen) {
                [cell.buttonLabel setText:translateString(@"show_less")];
            } else {
                [cell.buttonLabel setText:translateString(@"show_more")];
            }
        } else {
            if (historyOpen) {
                [cell.buttonLabel setText:translateString(@"show_less")];
            } else {
                [cell.buttonLabel setText:translateString(@"show_more")];
            }            
        }
        return cell;
    } else {
        NSString * identifier = @"autocompleteMiddleCell";
        if (indexPath.row == 0) {
            if ([[self.groupedList objectAtIndex:indexPath.section] count] == 1) {
                identifier = @"autocompleteSingleCell";
            } else {
                identifier = @"autocompleteTopCell";
            }
        } else {
            if (indexPath.section == 0) {
                if (indexPath.row == [[self.groupedList objectAtIndex:indexPath.section] count]-1 && indexPath.row < MAX_FAVORITES) {
                    identifier = @"autocompleteBottomCell";
                }
            } else {
                if (indexPath.row == [[self.groupedList objectAtIndex:indexPath.section] count]-1 && indexPath.row < MAX_HISTORY) {
                    identifier = @"autocompleteBottomCell";
                }
            }
    
        }
            
        NSDictionary * currentRow = [[self.groupedList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
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
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favorites"]) {
            if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"favHome"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"favWork"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"favBookmark"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"favStar"]];
            } else {
                [cell.iconImage setImage:nil];
            }
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
        }
        return cell;
    }
}

- (void)openCloseSection:(NSInteger)section {
    if (section == 0) {
        favoritesOpen = !favoritesOpen;
    } else if (section == 1) {
        historyOpen = !historyOpen;
    }
    [tblView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isCountButton:indexPath]) {
        [self openCloseSection:indexPath.section];
    } else {
        NSDictionary * currentRow = [[self.groupedList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [toLabel setText:[currentRow objectForKey:@"name"]];
        [self setToData:@{
         @"name" : [currentRow objectForKey:@"name"],
         @"address" : [currentRow objectForKey:@"address"],
         @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]]
         }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCountButton:indexPath]) {
        return 47.0f;
    } else {
        return 45.0f;
    }
    return [SMEnterRouteCell getHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [SMAutocompleteHeader getHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SMAutocompleteHeader * cell = [tableView dequeueReusableCellWithIdentifier:@"autocompleteHeader"];
    switch (section) {
        case 0:
            [cell.headerTitle setText:translateString(@"favorites")];
            break;
        case 1:
            [cell.headerTitle setText:translateString(@"recent_results")];
            break;            
        default:
            break;
    }
    return cell;
}

#pragma mark - search delegate 

- (void)locationFound:(NSDictionary *)locationDict {
    switch (delegateField) {
        case fieldTo:
            [self setToData:locationDict];
            [toLabel setText:[self.toData objectForKey:@"name"]];
            break;
        case fieldFrom:
            [self setFromData:locationDict];
            [fromLabel setText:[self.fromData objectForKey:@"name"]];
            if ([[locationDict objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
                [locationArrow setHidden:NO];
                CGRect frame = fromLabel.frame;
                frame.origin.x = locationArrow.frame.origin.x + 20.0f;
                frame.size.width = 269.0f - frame.origin.x;
                [fromLabel setFrame:frame];
                [fromLabel setTextColor:[UIColor colorWithRed:39.0f/255.0f green:111.0f/255.0f blue:183.0f/255.0f alpha:1.0f]];
            } else {
                [locationArrow setHidden:YES];
                CGRect frame = fromLabel.frame;
                frame.origin.x = locationArrow.frame.origin.x;
                frame.size.width = 269.0f - frame.origin.x;
                [fromLabel setFrame:frame];
                [fromLabel setTextColor:[UIColor blackColor]];
            }
            break;
        default:
            break;
    }
}


@end
