//
//  SMEnterRouteController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEnterRouteController.h"
#import "SMAppDelegate.h"
#import "SMUtil.h"
#import "SMLocationManager.h"
#import "SMEnterRouteCell.h"
#import "SMAutocompleteHeader.h"
#import "SMViewMoreCell.h"
#import "SMFavoritesController.h"
#import "SMFavoritesUtil.h"
#import "SMSearchHistory.h"

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
    NSMutableArray * saved = [SMFavoritesUtil getFavorites];
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

    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"" withValue:0]) {
        debugLog(@"error in trackEvent");
    }

}

- (void)viewDidUnload {
    fromLabel = nil;
    toLabel = nil;
    tblView = nil;
    fadeView = nil;
    locationArrow = nil;
    swapButton = nil;
    startButton = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - button actions

- (IBAction)swapFields:(id)sender {
    if (self.fromData == nil  || ([self.fromData objectForKey:@"source"] && [[self.fromData objectForKey:@"source"] isEqualToString:@"currentPosition"])) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"current_position_cant_be_destination") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSString * txt = fromLabel.text;
    fromLabel.text = toLabel.text;
    toLabel.text = txt;
    NSDictionary * data = [self.fromData copy];
    self.fromData = self.toData;
    self.toData = data;
    
    if (self.fromData == nil  || ([self.fromData objectForKey:@"source"] && [[self.fromData objectForKey:@"source"] isEqualToString:@"currentPosition"])) {
        [swapButton setEnabled:NO];
    } else {
        [swapButton setEnabled:YES];
    }
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
    
    if ([[self.fromData objectForKey:@"name"] isEqualToString:CURRENT_POSITION_STRING] == NO) {
        if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"From" withLabel:[self.fromData objectForKey:@"name"] withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    
//    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
//    [r setAuxParam:@"nearestPoint"];
//    [r findNearestPointForStart:[self.fromData objectForKey:@"location"] andEnd:[self.toData objectForKey:@"location"]];
    
    CLLocation * s = [self.fromData objectForKey:@"location"];
    CLLocation * e = [self.toData objectForKey:@"location"];
    
    NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", fromLabel.text, s.coordinate.latitude, s.coordinate.longitude, toLabel.text, e.coordinate.latitude, e.coordinate.longitude];
    debugLog(@"%@", st);
    if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
        debugLog(@"error in trackPageview");
    }
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r getRouteFrom:s.coordinate to:e.coordinate via:nil];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"searchSegue"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        switch (delegateField) {
            case fieldFrom:
                [destViewController setShouldAllowCurrentPosition:YES];
                if (self.fromData && [[self.fromData objectForKey:@"source"] isEqualToString:@"currentPosition"] == NO) {
                    [destViewController setSearchText:fromLabel.text];
                    destViewController.locationData = self.fromData;
                } else {
                    [destViewController setSearchText:@""];
                }
                
                break;
            case fieldTo:
                [destViewController setShouldAllowCurrentPosition:NO];
                destViewController.locationData = self.toData;
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
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
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
            NSDictionary * d = @{
                                 @"name" : [self.toData objectForKey:@"name"],
                                 @"address" : [self.toData objectForKey:@"address"],
                                 @"startDate" : [NSDate date],
                                 @"endDate" : [NSDate date],
                                 @"source" : @"searchHistory",
                                 @"subsource" : @"",
                                 @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.latitude],
                                 @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.toData objectForKey:@"location"]).coordinate.longitude],
                                 @"order" : @1
                                 };
            [SMSearchHistory saveToSearchHistory:d];
            
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                SMSearchHistory * sh = [SMSearchHistory instance];
                [sh setDelegate:self.appDelegate];
                [sh addSearchToServer:d];
            }
            
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

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
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
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteContacts"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
            if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"findLocation"]];
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findLocation"]];
            } else {
                [cell.iconImage setImage:[UIImage imageNamed:@"findAutocomplete"]];
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findAutocomplete"]];
            }
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"searchHistory"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favorites"]) {
            if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
                [cell.iconImage setImage:[UIImage imageNamed:@"favHomeGrey"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
                [cell.iconImage setImage:[UIImage imageNamed:@"favWorkGrey"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
                [cell.iconImage setImage:[UIImage imageNamed:@"favSchoolGrey"]];
            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
                [cell.iconImage setImage:[UIImage imageNamed:@"favStarGreySmall"]];
            } else {
                [cell.iconImage setImage:nil];
                [cell.iconImage setHighlightedImage:nil];
            }
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
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
    [tblView reloadData];
}

- (NSString*)textFromData:(NSDictionary*)data {
    NSMutableArray * arr = [NSMutableArray array];
    [arr addObject:[data objectForKey:@"name"]];
    if ([data objectForKey:@"address"] && [[data objectForKey:@"name"] isEqualToString:[data objectForKey:@"address"]] == NO) {
        NSString * s = [[data objectForKey:@"address"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([s isEqualToString:@""] == NO) {
            [arr addObject:s];
        }
    }
    return [arr componentsJoinedByString:@", "];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isCountButton:indexPath]) {
        [self openCloseSection:indexPath.section];
    } else {
        if (indexPath.section == 0) {
            if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"Favorites" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        } else {
            if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"Recent" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
        NSDictionary * currentRow = [[self.groupedList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        [toLabel setText:[self textFromData:currentRow]];
        [self setToData:@{
         @"name" : [currentRow objectForKey:@"name"],
         @"address" : [currentRow objectForKey:@"address"],
         @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]]
         }];
        
        if ((self.toData && self.fromData) || ([toLabel.text isEqualToString:@""] == NO && [fromLabel.text isEqualToString:@""] == NO)) {
            [startButton setEnabled:YES];
        } else {
            [startButton setEnabled:NO];
        }
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
            [toLabel setText:[self textFromData:locationDict]];
            break;
        case fieldFrom:
            [self setFromData:locationDict];
            
            if (self.fromData == nil  || ([self.fromData objectForKey:@"source"] && [[self.fromData objectForKey:@"source"] isEqualToString:@"currentPosition"])) {
                [swapButton setEnabled:NO];
            } else {
                [swapButton setEnabled:YES];
            }
            
            [fromLabel setText:[self textFromData:locationDict]];
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
    
    if ((self.toData && self.fromData) || ([toLabel.text isEqualToString:@""] == NO && [fromLabel.text isEqualToString:@""] == NO)) {
        [startButton setEnabled:YES];
    } else {
        [startButton setEnabled:NO];
    }
}


@end
