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
#import "SMUtil.h"
#import "DAKeyboardControl.h"

@interface SMFindAddressController ()
@property (nonatomic, strong) SMAutocomplete * autocomp;
@property (nonatomic, strong) NSArray * autocompleteArr;

@property (nonatomic, strong) NSString * poiToName;
@property (nonatomic, strong) NSString * poiToAddress;
@property (nonatomic, strong) CLLocation * poiToLocation;
@property (nonatomic, strong) NSString * poiFromName;
@property (nonatomic, strong) NSString * poiFromAddress;
@property (nonatomic, strong) CLLocation * poiFromLocation;

@property (nonatomic, weak) SMTokenizedTextField * currentTextField;
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
    self.poiToName = @"";
    self.poiToLocation = nil;
    self.poiFromName = @"";
    self.poiFromLocation = nil;
    
    [routeTo setDelegate:self];
    [routeTo setShouldHideTextField:YES];
    [routeTo setReturnKeyType:UIReturnKeyRoute];
    
    [routeFrom setDelegate:self];
    [routeFrom setShouldHideTextField:YES];
    [routeFrom setReturnKeyType:UIReturnKeyNext];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.locationFrom && ([self.locationFrom isEqualToString:@""] == NO)) {
        [routeFrom setText:self.locationFrom];
    } else {
        [routeFrom setToken:CURRENT_POSITION_STRING];
    }
    if (self.locationTo && ([self.locationTo isEqualToString:@""] == NO)) {
        [routeTo setText:self.locationTo];
    } else {
        [routeTo setText:@""];
    }
    
    if (self.autocompleteArr == nil) {
        self.autocompleteArr = @[];
    }
    
    if (([routeTo.text isEqualToString:@""] == NO) && ([routeFrom.text isEqualToString:@""] == NO)) {
        [btnStart setEnabled:YES];
    } else {
        [btnStart setEnabled:NO];
    }
    [routeTo becomeFirstResponder];
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {}];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self autocompleteEntriesFound:@[] forString:@""];
}

- (void)viewDidUnload {
    tblView = nil;
    routeFrom = nil;
    routeTo = nil;
    fadeView = nil;
    btnStart = nil;
    autocompleteFade = nil;
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
//        if ([currentRow objectForKey:@"icon"]) {
//            [cell.iconImage loadImage:[currentRow objectForKey:@"icon"]];
//        } else {
//            [cell.iconImage setImage:nil];
//        }
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
    NSDictionary * currentRow = [self.autocompleteArr objectAtIndex:indexPath.row];
    if ([currentRow objectForKey:@"subsource"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
        if (self.currentTextField == routeFrom) {
            self.poiFromName = [currentRow objectForKey:@"name"];
            self.poiFromAddress = [currentRow objectForKey:@"address"];
            self.poiFromLocation = [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] floatValue] longitude:[[currentRow objectForKey:@"long"] floatValue]];
            [routeFrom setToken:self.poiFromName];
        } else {
            self.poiToName = [currentRow objectForKey:@"name"];
            self.poiToAddress = [currentRow objectForKey:@"address"];
            self.poiToLocation = [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] floatValue] longitude:[[currentRow objectForKey:@"long"] floatValue]];
            [routeTo setToken:self.poiToName];
        }
        [self refreshStartButton];
    } else {
        self.currentTextField.text = [currentRow objectForKey:@"address"];
        if (([routeTo.text isEqualToString:@""] == NO) && ([routeFrom.text isEqualToString:@""] == NO)) {
            if ([routeFrom.text isEqualToString:CURRENT_POSITION_STRING]) {
                [SMGeocoder geocode:routeTo.text completionHandler:^(NSArray *placemarks, NSError *error) {
                    if ([placemarks count] == 0) {
                        [btnStart setEnabled:NO];
                    } else {
                        [btnStart setEnabled:YES];
                    }
                }];
            } else {
                [SMGeocoder geocode:routeFrom.text completionHandler:^(NSArray *placemarks, NSError *error) {
                    if ([placemarks count] > 0) {
                        [SMGeocoder geocode:routeTo.text completionHandler:^(NSArray *placemarks, NSError *error) {
                            if ([placemarks count] == 0) {
                                [btnStart setEnabled:NO];
                            } else {
                                [btnStart setEnabled:YES];
                            }
                        }];
                    } else {
                        [btnStart setEnabled:NO];
                    }
                }];
            }
        } else {
            [btnStart setEnabled:NO];
        }
        
        if ([routeFrom.text isEqualToString:CURRENT_POSITION_STRING]) {
            [routeFrom setToken:CURRENT_POSITION_STRING];
        }
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

    CLLocation * loc = self.poiFromLocation;
    self.poiFromLocation = self.poiToLocation;
    self.poiToLocation = loc;
    
    NSString * str = self.poiFromName;
    self.poiFromName = self.poiToName;
    self.poiToName = str;

    NSString * strTo = routeFrom.text;
    NSString * strFrom = routeTo.text;
    
    NSMutableArray * tokens = routeFrom.tokens;
    routeFrom.tokens = routeTo.tokens;
    routeTo.tokens = tokens;
    
    if ([routeFrom.tokens count] > 0) {
        SMTokenButton * btn = [routeFrom.tokens objectAtIndex:0];
        [routeFrom setToken:btn.token];
    } else {
        [routeFrom setText:strFrom];
    }
    if ([routeTo.tokens count] > 0) {
        SMTokenButton * btn = [routeTo.tokens objectAtIndex:0];
        [routeTo setToken:btn.token];
    } else {
        [routeTo setText:strTo];
    }
    
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
        if ([routeTo.text isEqualToString:self.poiToName]) {
            if ([routeFrom.text isEqualToString:CURRENT_POSITION_STRING]) {
                if ([SMLocationManager instance].hasValidLocation) {
                    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:[SMLocationManager instance].lastValidLocation.coordinate.latitude longitude:[SMLocationManager instance].lastValidLocation.coordinate.longitude];
                    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:self.poiToLocation.coordinate.latitude longitude:self.poiToLocation.coordinate.longitude];
                    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                    [r setAuxParam:@"nearestPoint"];
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
                if ([routeFrom.text isEqualToString:self.poiFromName]) {
                    CLLocation * cStart = [[CLLocation alloc] initWithLatitude:self.poiFromLocation.coordinate.latitude longitude:self.poiFromLocation.coordinate.longitude];
                    CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:self.poiToLocation.coordinate.latitude longitude:self.poiToLocation.coordinate.longitude];
                    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                    [r setAuxParam:@"nearestPoint"];
                    [r findNearestPointForStart:cStart andEnd:cEnd];

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
                            CLLocation * cEnd = [[CLLocation alloc] initWithLatitude:self.poiToLocation.coordinate.latitude longitude:self.poiToLocation.coordinate.longitude];
                            SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
                            [r setAuxParam:@"nearestPoint"];
                            [r findNearestPointForStart:cStart andEnd:cEnd];
                        } else {
                            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_from_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                            [av show];
                            [UIView animateWithDuration:0.2f animations:^{
                                [fadeView setAlpha:0.0f];
                            }];
                        }
                    }];
                }
            }
        } else {
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
                            [r setAuxParam:@"nearestPoint"];
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
                                [r setAuxParam:@"nearestPoint"];
                                [r findNearestPointForStart:cStart andEnd:cEnd];
                            } else {
                                UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_from_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                                [av show];
                                [UIView animateWithDuration:0.2f animations:^{
                                    [fadeView setAlpha:0.0f];
                                }];
                            }
                        }];
                    }
                } else {
                    UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_to_address_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
                    [av show];
                    [UIView animateWithDuration:0.2f animations:^{
                        [fadeView setAlpha:0.0f];
                    }];
                }
            }];
        }
        
        
            
    }
}

#pragma mark - textfield delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = (SMTokenizedTextField*)textField;
    if ([textField.text isEqualToString:@""]) {
        [self autocompleteEntriesFound:@[] forString:@""];
    } else {
        [self.autocomp getAutocomplete:textField.text];        
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ((SMTokenizedTextField*)textField == routeFrom) {
        [routeFrom resignFirstResponder];
        [routeTo becomeFirstResponder];
    } else if ((SMTokenizedTextField*)textField == routeTo) {
        [routeTo resignFirstResponder];
        [self findRoute:nil];
    }
    return YES;
}

- (void)showFade {
    [UIView animateWithDuration:0.2f animations:^{
        [autocompleteFade setAlpha:1.0f];
    }];
}

- (void)hideFade {
    [UIView animateWithDuration:0.2f animations:^{
        [autocompleteFade setAlpha:0.0f];
    }];
}

- (void)refreshStartButton {
    if (([routeTo.text isEqualToString:@""] == NO) && ([routeFrom.text isEqualToString:@""] == NO)) {
        if ([routeFrom.text isEqualToString:CURRENT_POSITION_STRING] || [routeFrom.text isEqualToString:self.poiFromName]) {
            if ([routeTo.text isEqualToString:self.poiToName]) {
                [btnStart setEnabled:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                });
            } else {
                [SMGeocoder geocode:routeTo.text completionHandler:^(NSArray *placemarks, NSError *error) {
                    if ([placemarks count] == 0) {
                        [btnStart setEnabled:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                        });
                    } else {
                        [btnStart setEnabled:YES];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                        });
                    }
                }];
            }
        } else {
            [SMGeocoder geocode:routeFrom.text completionHandler:^(NSArray *placemarks, NSError *error) {
                if ([placemarks count] > 0) {
                    if ([routeTo.text isEqualToString:self.poiToName]) {
                        [btnStart setEnabled:YES];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                        });
                    } else {
                        [SMGeocoder geocode:routeTo.text completionHandler:^(NSArray *placemarks, NSError *error) {
                            if ([placemarks count] == 0) {
                                [btnStart setEnabled:NO];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                                });
                            } else {
                                [btnStart setEnabled:YES];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                                });
                            }
                        }];
                    }
                } else {
                    [btnStart setEnabled:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
                    });
                }
            }];
        }
    } else {
        [btnStart setEnabled:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
        });
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self performSelector:@selector(showFade) withObject:nil afterDelay:0.01f];
    NSString * s = [textField.text stringByReplacingCharactersInRange:range withString:string];
//    if (textField == routeFrom) {
//        if ([s isEqualToString:CURRENT_POSITION_STRING]) {
//            [textField setTextColor:[UIColor blueColor]];
//        } else {
//            [textField setTextColor:[UIColor blackColor]];
//        }
//        
//        if ([textField.text isEqualToString:CURRENT_POSITION_STRING] && s.length < textField.text.length) {
//            textField.text = @"";
//            s = @"";
//        }
//    }
    
//    if (textField == routeTo) {
//        if ([self.poiToName isEqualToString:@""] == NO) {
//            if ([s isEqualToString:self.poiToName]) {
//                [routeTo setTextColor:[UIColor blueColor]];
//            } else {
//                [routeTo setTextColor:[UIColor blackColor]];
//            }
//            
//            if ([routeTo.text isEqualToString:self.poiToName] && s.length < textField.text.length) {
//                routeTo.text = @"";
//                s = @"";
//                self.poiToName = @"";
//                self.poiToLocation = nil;
//            } 
//        }
//    } else {
//        if ([self.poiFromName isEqualToString:@""] == NO) {
//            if ([s isEqualToString:self.poiFromName]) {
//                [routeFrom setTextColor:[UIColor blueColor]];
//            } else {
//                [routeFrom setTextColor:[UIColor blackColor]];
//            }
//            
//            if ([routeFrom.text isEqualToString:self.poiFromName] && s.length < textField.text.length) {
//                routeFrom.text = @"";
//                s = @"";
//                self.poiFromName = @"";
//                self.poiFromLocation = nil;
//            }
//        }
//    }
    
    if ([s isEqualToString:@""]) {
        [self autocompleteEntriesFound:@[] forString:@""];
    } else {
        [self.autocomp getAutocomplete:s];
    }
    
    [self refreshStartButton];
        
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [btnStart setEnabled:NO];
    textField.text = @"";
    [self autocompleteEntriesFound:@[] forString:@""];
    return YES;
}

#pragma mark - smautocomplete delegate

- (void)autocompleteEntriesFound:(NSArray *)arr forString:(NSString*) str {
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * r = [NSMutableArray array];
//    for (NSDictionary * d in appd.pastRoutes) {
//        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
//            BOOL found = NO;
//            for (NSDictionary * d1 in r) {
//                if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                    found = YES;
//                    break;
//                }
//            }
//            if (found == NO) {
//                [r addObject:d];
//            }
//        }
//    }
//    
//    for (NSDictionary * d in appd.currentContacts) {
//        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
//            BOOL found = NO;
//            for (NSDictionary * d1 in r) {
//                if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                    found = YES;
//                    break;
//                }
//            }
//            if (found == NO) {
//                [r addObject:d];
//            }
//        }
//    }
//    for (NSDictionary * d in appd.currentEvents) {
//        if (([[d objectForKey:@"name"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound) || ([[d objectForKey:@"address"] rangeOfString:str options:NSCaseInsensitiveSearch].location != NSNotFound)){
//            BOOL found = NO;
//            for (NSDictionary * d1 in r) {
//                if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                    found = YES;
//                    break;
//                }
//            }
//            if (found == NO) {
//                [r addObject:d];
//            }
//        }
//    }
    
    for (NSDictionary * d in arr) {
        [r addObject:d];
    }
//
//    if (([r count] == 0) && ([self.currentTextField.text isEqualToString:@""])) {
//        for (NSDictionary * d in appd.pastRoutes) {
//            BOOL found = NO;
//            for (NSDictionary * d1 in r) {
//                if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                    found = YES;
//                    break;
//                }
//            }
//            if (found == NO) {
//                [r addObject:d];
//            }
//        }
//    }
    
    if (([r count] == 0) && ([self.currentTextField.text isEqualToString:@""])) {
        if (self.currentTextField == routeFrom) {
            [r insertObject:@{
             @"name" : CURRENT_POSITION_STRING,
             @"address" : CURRENT_POSITION_STRING,
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"pastRoutes"
             } atIndex:0];
        }
        /**
         * add latest two searches
         */
        for (int i = 0; i < MIN(2, [appd.searchHistory count]); i++) {
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
        /**
         * add saved routes here
         */
        
        /**
         * add the rest of the searches
         */
        
        if ([appd.searchHistory count] > 2) {
            for (int i = 2; i < [appd.searchHistory count]; i++) {
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
        }
        
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
    if ([req.auxParam isEqualToString:@"nearestPoint"]) {
        CLLocation * s = [res objectForKey:@"start"];
        CLLocation * e = [res objectForKey:@"end"];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", routeFrom.text, s.coordinate.latitude, s.coordinate.longitude, routeTo.text, e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }

        [self setStartLocation:s];
        [self setEndLocation:e];
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:self.startLocation.coordinate to:self.endLocation.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        NSString * response = [[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding];
        id jsonRoot = [[[SBJsonParser alloc] init] objectWithString:response];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([[jsonRoot objectForKey:@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"error_route_not_found") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
            [av show];
        } else {
            if ([self.poiToName isEqualToString:@""] == NO) {
                [SMUtil saveToSearchHistory:@{
                 @"name" : self.poiToName,
                 @"address" : self.poiToAddress,
                 @"startDate" : [NSDate date],
                 @"endDate" : [NSDate date],
                 @"source" : @"searchHistory",
                 @"subsource" : @"foursquare",
                 @"lat" : [NSNumber numberWithDouble:self.poiToLocation.coordinate.latitude],
                 @"long" : [NSNumber numberWithDouble:self.poiToLocation.coordinate.longitude]
                 }];
            } else {
                [SMUtil saveToSearchHistory:@{
                 @"name" : [NSString stringWithFormat:@"%@ - %@", routeFrom.text, routeTo.text],
                 @"address" : routeTo.text,
                 @"startDate" : [NSDate date],
                 @"endDate" : [NSDate date],
                 @"source" : @"searchHistory",
                 @"subsource" : @"",
                 @"lat" : @"",
                 @"long" : @""
                 }];
            }
            [self.delegate findRouteFrom:self.startLocation.coordinate to:self.endLocation.coordinate fromAddress:routeFrom.text toAddress:routeTo.text withJSON:jsonRoot];
            [self dismissViewControllerAnimated:YES completion:^{
            }];
            [UIView animateWithDuration:0.2f animations:^{
                [fadeView setAlpha:0.0f];
            }];
        }
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            [fadeView setAlpha:0.0f];
        }];
    }
}

@end
