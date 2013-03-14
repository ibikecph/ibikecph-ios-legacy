//
//  SMSearchController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMSearchController.h"
#import "SMEnterRouteCell.h"
#import <CoreLocation/CoreLocation.h>
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>
#import "SMAppDelegate.h"
#import "SMAutocomplete.h"
#import "DAKeyboardControl.h"

@interface SMSearchController ()
@property (nonatomic, strong) NSArray * searchResults;
@property (nonatomic, strong) NSDictionary * locationData;
@property (nonatomic, strong) SMAutocomplete * autocomp;
@end

@implementation SMSearchController

- (void)viewDidUnload {
    tblView = nil;
    tblFade = nil;
    searchField = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [searchField setText:self.searchText];
    self.autocomp = [[SMAutocomplete alloc] initWithDelegate:self];
    [tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [searchField becomeFirstResponder];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {}];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * currentRow = [self.searchResults objectAtIndex:indexPath.row];
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
    NSDictionary * currentRow = [self.searchResults objectAtIndex:indexPath.row];
    [searchField setText:[currentRow objectForKey:@"name"]];
    
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"oiorest"]) {
        searchField.text = [currentRow objectForKey:@"address"];
        [self checkLocation];
    } else {
        [self setLocationData:@{
         @"name" : [currentRow objectForKey:@"name"],
         @"address" : [currentRow objectForKey:@"address"],
         @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]]
         }];
        if (self.delegate) {
            [self.delegate locationFound:self.locationData];
        }
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMEnterRouteCell getHeight];
}

#pragma mark - custom methods 

- (void)delayedAutocomplete:(NSString*)text {
    [tblFade setAlpha:1.0f];
    [self.autocomp getAutocomplete:text];
}

- (void)showFade {
    [tblFade setAlpha:1.0f];
}

- (void)hideFade {
    [tblFade setAlpha:0.0f];
}

- (void)checkLocation {
    if ([searchField.text isEqualToString:@""] == NO) {
        if ([searchField.text isEqualToString:CURRENT_POSITION_STRING]) {
            
        } else {
            [tblFade setAlpha:1.0f];
            [SMGeocoder geocode:searchField.text completionHandler:^(NSArray *placemarks, NSError *error) {
                if ([placemarks count] > 0) {
                    MKPlacemark *coord = [placemarks objectAtIndex:0];
                    [self dismissModalViewControllerAnimated:YES];
                    if (self.delegate) {
                        [self.delegate locationFound:@{
                         @"name" : searchField.text,
                         @"address" : searchField.text,
                         @"location" : [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]
                         }];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                    });
                }
            }];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
        });
    }
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * s = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([s isEqualToString:@""]) {
        [self autocompleteEntriesFound:@[] forString:@""];
    } else {
        if ([s length] >= 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
            [self performSelector:@selector(delayedAutocomplete:) withObject:s afterDelay:0.5f];
        }
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = @"";
    [self autocompleteEntriesFound:@[] forString:@""];
    self.locationData = nil;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkLocation];
    return YES;
}

#pragma mark - smautocomplete delegate

- (void)autocompleteEntriesFound:(NSArray *)arr forString:(NSString*) str {
    [self hideFade];
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * r = [NSMutableArray array];

    for (NSDictionary * d in arr) {
        [r addObject:d];
    }
    
    [r insertObject:@{
     @"name" : CURRENT_POSITION_STRING,
     @"address" : CURRENT_POSITION_STRING,
     @"startDate" : [NSDate date],
     @"endDate" : [NSDate date],
     @"source" : @"pastRoutes"
     } atIndex:0];
    
    for (int i = 0; i < [appd.searchHistory count]; i++) {
        BOOL found = NO;
        NSDictionary * d = [appd.searchHistory objectAtIndex:i];
        for (NSDictionary * d1 in r) {
            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                found = YES;
                break;
            }
        }
        if (found == NO) {
            [r addObject:d];
        }
    }
    self.searchResults = r;
    [tblView reloadData];
    [tblFade setAlpha:0.0f];
}


@end
