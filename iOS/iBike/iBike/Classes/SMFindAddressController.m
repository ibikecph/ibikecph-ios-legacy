//
//  SMFindAddressController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 25/01/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMFindAddressController.h"
#import <MapKit/MapKit.h>
#import "SMLocationManager.h"
#import "SBJson.h"
#import "SMRouteNavigationController.h"
#import "SMAppDelegate.h"

#import "SMAutocompleteCell.h"

#import "SMGeocoder.h"
#import <MapKit/MapKit.h>

@interface SMFindAddressController ()
@property (nonatomic, strong) SMAutocomplete * autocomp;
@property (nonatomic, strong) NSArray * autocompleteArr;
@end

@implementation SMFindAddressController

- (void)viewDidLoad {
    [super viewDidLoad];
	[tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

    self.autocomp = [[SMAutocomplete alloc] initWithDelegate:self];
        
    for (id v in tblView.subviews) {
        if ([v isKindOfClass:[UIScrollView class]]) {
            [v setDelegate: self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.locationFrom && ([self.locationFrom isEqualToString:@""] == NO)) {
        [routeFrom setText:self.locationFrom];
    } else {
        [routeFrom setText:CURRENT_POSITION_STRING];
    }
    if (self.locationTo && ([self.locationTo isEqualToString:@""] == NO)) {
        [routeTo setText:self.locationTo];
    } else {
        [routeTo setText:@""];
    }
    
//    [routeFrom setText:@"Grundtvigsvej 19, 1864 Frederiksberg"];
//    [routeTo setText:@"Vodroffsvej 53C, 1900 Frederiksberg"];
//    [routeTo setText:@" Acaciavej 4, 1867 Frederiksberg"];

    if (self.autocompleteArr == nil) {
        self.autocompleteArr = @[];
    }
    
    if (([routeTo.text isEqualToString:@""] == NO) && ([routeFrom.text isEqualToString:@""] == NO)) {
        [btnStart setEnabled:YES];
    } else {
        [btnStart setEnabled:NO];
    }
    

    [routeTo becomeFirstResponder];
}

- (void)viewDidUnload {
    tblView = nil;
    routeFrom = nil;
    routeTo = nil;
    fadeView = nil;
    btnStart = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.autocompleteArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * currentRow = [self.autocompleteArr objectAtIndex:indexPath.row];
    NSString * identifier = @"autocompleteCell";
    SMAutocompleteCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [cell.addressLabel setText:[currentRow objectForKey:@"address"]];
    [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
    
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"fb"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
        [cell.iconImage setImage:nil];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
        [cell.iconImage setImage:[UIImage imageNamed:@"findRouteBike"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.currentTextField.text = [[self.autocompleteArr objectAtIndex:indexPath.row] objectForKey:@"address"];
    if (routeTo.isFirstResponder || routeFrom.isFirstResponder) {
        [routeTo resignFirstResponder];
        [routeFrom resignFirstResponder];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMAutocompleteCell getHeight];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (routeTo.isFirstResponder || routeFrom.isFirstResponder) {
        [routeTo resignFirstResponder];
        [routeFrom resignFirstResponder];
    }    
}

#pragma mark - actions


- (IBAction)goBack:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)swapFromAndTo:(id)sender {
    NSString * str = routeFrom.text;
    routeFrom.text = routeTo.text;
    routeTo.text = str;
    
    if (self.currentTextField == routeFrom) {
        self.currentTextField = routeTo;
    } else {
        self.currentTextField = routeFrom;
    }
    [self.currentTextField becomeFirstResponder];
}

- (IBAction)findRoute:(id)sender {
    if (([routeTo.text isEqualToString:@""]) || ([routeFrom.text isEqualToString:@""])) {
        return;
    }
    
    if ([routeTo.text isEqualToString:CURRENT_POSITION_STRING]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_invalid_to_address") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:1.0f];
    }];
    if (self.delegate) {
            [SMGeocoder geocode:routeTo.text completionHandler:^(NSArray *placemarks, NSError *error) {
                //Error checking
                if ([placemarks count] > 0) {
                    MKPlacemark *coordTo = [placemarks objectAtIndex:0];
                    if (coordTo == nil) {
                        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_to_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                        [av show];
                        [UIView animateWithDuration:0.2f animations:^{
                            [fadeView setAlpha:0.0f];
                        }];
                        return;
                    }
                    if ([routeFrom.text isEqualToString:CURRENT_POSITION_STRING]) {
                        if ([SMLocationManager instance].hasValidLocation) {
                            CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                            CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:coordTo.coordinate.latitude longitude:coordTo.coordinate.longitude];
                            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                            [r findNearestPointForStart:cStart andEnd:cEnd];
                        } else {
                            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_no_gps_location") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                            [av show];
                            [UIView animateWithDuration:0.2f animations:^{
                                [fadeView setAlpha:0.0f];
                            }];
                            return;
                        }
                    } else {
                        [SMGeocoder geocode:routeFrom.text completionHandler:^(NSArray *placemarks, NSError *error) {
                            if ([placemarks count] > 0) {
                                MKPlacemark *coordFrom = [placemarks objectAtIndex:0];
                                if (coordFrom == nil) {
                                    UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_from_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                                    [av show];
                                    [UIView animateWithDuration:0.2f animations:^{
                                        [fadeView setAlpha:0.0f];
                                    }];
                                    return;
                                }
                                
                                CLLocation * cStart = [[CLLocation alloc] initWithLatitude:coordFrom.coordinate.latitude longitude:coordFrom.coordinate.longitude];
                                CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:coordTo.coordinate.latitude longitude:coordTo.coordinate.longitude];
                                SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                                [r findNearestPointForStart:cStart andEnd:cEnd];
                            } else {
                                [UIView animateWithDuration:0.2f animations:^{
                                    [fadeView setAlpha:0.0f];
                                }];
                            }
                        }];
                    }
                } else {
                    [UIView animateWithDuration:0.2f animations:^{
                        [fadeView setAlpha:0.0f];
                    }];
                }
            }];
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;
    [self.autocomp getAutocomplete:textField.text];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == routeFrom) {
        [routeFrom resignFirstResponder];
        [routeTo becomeFirstResponder];
    } else if (textField == routeTo) {
        [routeTo resignFirstResponder];
        [self findRoute:nil];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * s = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.autocomp getAutocomplete:s];
    
    UITextField * other = nil;
    if (textField == routeFrom) {
        other = routeTo;
    } else {
        other = routeFrom;
    }
    if (([s isEqualToString:@""] == NO) && ([other.text isEqualToString:@""] == NO)) {
        [btnStart setEnabled:YES];
    } else {
        [btnStart setEnabled:NO];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [btnStart setEnabled:NO];
    return YES;
}

#pragma mark - smautocomplete delegate

- (void)autocompleteEntriesFound:(NSArray *)arr forString:(NSString*) str {
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * r = [NSMutableArray array];
    for (NSDictionary * d in appd.pastRoutes) {
        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
            BOOL found = NO;
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
    }
    
    for (NSDictionary * d in appd.currentContacts) {
        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
            BOOL found = NO;
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
    }
    for (NSDictionary * d in appd.currentEvents) {
        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
            BOOL found = NO;
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
    }
    for (NSDictionary * d in arr) {
        [r addObject:@{
         @"name" : @"",
         @"source" : @"autocomplete",         
         @"address" : [NSString stringWithFormat:@"%@, %@ %@", [d objectForKey:@"street"], [d objectForKey:@"zip"], [d objectForKey:@"city"]]
         }];
    }
    self.autocompleteArr = r;
    [tblView reloadData];
}

#pragma mark - custom methods

- (void)loadMatches:(NSArray*)nearby {
     NSMutableArray * r = [NSMutableArray array];
    for (NSDictionary * d in nearby) {
        [r addObject:@{
         @"name" : @"",
         @"source" : @"autocomplete",
         @"address" : [NSString stringWithFormat:@"%@ %@, %@ %@", [d objectForKey:@"street"], [d objectForKey:@"house_number"], [d objectForKey:@"zip"], [d objectForKey:@"city"]]
         }];
    }
    self.autocompleteArr = r;
    [tblView reloadData];
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    CLLocation * s = [res objectForKey:@"start"];
    CLLocation * e = [res objectForKey:@"end"];
    [self.delegate findRouteFrom:s.coordinate to:e.coordinate fromAddress:routeFrom.text toAddress:routeTo.text];
    [self dismissModalViewControllerAnimated:YES];
    [UIView animateWithDuration:0.2f animations:^{
        [fadeView setAlpha:0.0f];
    }];
}

@end
