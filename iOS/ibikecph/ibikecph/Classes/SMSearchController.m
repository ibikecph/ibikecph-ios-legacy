//
//  SMSearchController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSearchController.h"
#import "SMSearchCell.h"
#import "SMSearchTwoRowCell.h"
#import <CoreLocation/CoreLocation.h>
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>
#import "SMAppDelegate.h"
#import "SMAutocomplete.h"
#import "DAKeyboardControl.h"
#import "TTTAttributedLabel.h"
#import "SMLocationManager.h"
#import "SMUtil.h"
#import "SMRequestOSRM.h"

@interface SMSearchController ()
@property (nonatomic, strong) NSArray * searchResults;
@property (nonatomic, strong) NSDictionary * locationData;
@property (nonatomic, strong) SMAutocomplete * autocomp;
@property (nonatomic, strong) NSArray * favorites;

@property (nonatomic, strong) NSMutableArray * terms;
@property (nonatomic, strong) NSString * srchString;
@property (nonatomic, strong) SMRequestOSRM * req;
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
    self.shouldAllowCurrentPosition = YES;
    [searchField setText:self.searchText];
    self.autocomp = [[SMAutocomplete alloc] initWithDelegate:self];
    [tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [searchField becomeFirstResponder];
    [self setFavorites:[SMUtil getFavorites]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    UITableView * tbl = tblView;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        [tbl setFrame:CGRectMake(0.0f, tbl.frame.origin.y, tbl.frame.size.width, keyboardFrameInView.origin.y - tbl.frame.origin.y)];
        debugLog(@"%@", NSStringFromCGRect(keyboardFrameInView));
    }];
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
    NSString * identifier;

    SMSearchCell * cell;
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
        identifier = @"searchTwoRowsCell";
        SMSearchTwoRowCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.addressLabel setText:[currentRow objectForKey:@"address"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            NSRange boldRange = [[mutableAttributedString string] rangeOfString:searchField.text options:NSCaseInsensitiveSearch];
            UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
            
            CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
            
            if (font) {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                CFRelease(font);
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
            }
            return mutableAttributedString;
        }];
        [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
        [cell setImageWithData:currentRow];
        return cell;
    } else {
        identifier = @"searchCell";
        SMSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.nameLabel setText:[currentRow objectForKey:@"name"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            NSRange boldRange = [[mutableAttributedString string] rangeOfString:searchField.text options:NSCaseInsensitiveSearch];
            UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
            
            CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
            
            if (font) {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                CFRelease(font);
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
            }
            return mutableAttributedString;
        }];
        [cell setImageWithData:currentRow];
        return cell;
    }    
    
//    [cell setImageWithData:currentRow];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary * currentRow = [self.searchResults objectAtIndex:indexPath.row];
    [searchField setText:[currentRow objectForKey:@"name"]];
    
    if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"oiorest"]) {
        searchField.text = [currentRow objectForKey:@"address"];
        [self checkLocation];
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setRequestIdentifier:@"getNearestForPinDrop"];
        [r findNearestPointForLocation:[[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]]];
    } else {
        if ([currentRow objectForKey:@"subsource"]) {
            [self setLocationData:@{
             @"name" : [currentRow objectForKey:@"name"],
             @"address" : [currentRow objectForKey:@"address"],
             @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]],
             @"source" : [currentRow objectForKey:@"source"],
             @"subsource" : [currentRow objectForKey:@"subsource"]
             }];
        } else {
            [self setLocationData:@{
             @"name" : [currentRow objectForKey:@"name"],
             @"address" : [currentRow objectForKey:@"address"],
             @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]],
             @"source" : [currentRow objectForKey:@"source"]
             }];
        }
        if (self.delegate) {
            [self.delegate locationFound:self.locationData];
        }
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMSearchCell getHeight];
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
                         @"location" : [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude],
                         @"source" : @"typedIn"
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
        } else if ([s length] >= 1) {
            NSMutableArray * r = [NSMutableArray array];
            if (self.shouldAllowCurrentPosition) {
                [r insertObject:@{
                 @"name" : CURRENT_POSITION_STRING,
                 @"address" : CURRENT_POSITION_STRING,
                 @"startDate" : [NSDate date],
                 @"endDate" : [NSDate date],
                 @"lat" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.latitude],
                 @"long" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.longitude],
                 @"source" : @"currentPosition",
                 } atIndex:0];
            }
            self.searchResults = r;
            [tblView reloadData];
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
    
    self.terms = [NSMutableArray array];
    self.srchString = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString * str in [self.srchString componentsSeparatedByString:@" "]) {
        if ([self.terms indexOfObject:str] == NSNotFound) {
            [self.terms addObject:str];
        }
    }    
    
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * r = [NSMutableArray array];
    
    
    if ([str isEqualToString:@""]) {
        self.searchResults = r;
        [tblView reloadData];
        [tblFade setAlpha:0.0f];
        return;
    }

    for (NSDictionary * d in arr) {
        [r addObject:d];
    }
    
        
    for (int i = 0; i < [self.favorites count]; i++) {
        BOOL found = NO;
        NSDictionary * d = [self.favorites objectAtIndex:i];
        for (NSDictionary * d1 in r) {
            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                found = YES;
                break;
            }
        }
        if (found == NO && [SMUtil pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
            [r addObject:d];
        }
    }
    
    for (int i = 0; i < [appd.searchHistory count]; i++) {
        BOOL found = NO;
        NSDictionary * d = [appd.searchHistory objectAtIndex:i];
        for (NSDictionary * d1 in r) {
            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                found = YES;
                break;
            }
        }
        if (found == NO && [SMUtil pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
            [r addObject:d];
        }
    }
    
    [r sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
        NSComparisonResult cmp = [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
        if (cmp == NSOrderedSame) {
            cmp = [[obj2 objectForKey:@"relevance"] compare:[obj1 objectForKey:@"relevance"]];
            if (cmp == NSOrderedSame) {
                if ([obj1 objectForKey:@"lat"] && [obj1 objectForKey:@"long"] && [obj2 objectForKey:@"lat"] && [obj2 objectForKey:@"long"] && [SMLocationManager instance].hasValidLocation) {
                    CGFloat dist1 = [[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue]  longitude:[[obj1 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
                    CGFloat dist2 = [[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue]  longitude:[[obj2 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
                    
                    if (dist1 > dist2) {
                        cmp = NSOrderedDescending;
                    } else if (dist1 < dist2) {
                        cmp = NSOrderedAscending;
                    }
                }
            }
        }
        return cmp;
    }];

    if (self.shouldAllowCurrentPosition) {
        [r insertObject:@{
         @"name" : CURRENT_POSITION_STRING,
         @"address" : CURRENT_POSITION_STRING,
         @"startDate" : [NSDate date],
         @"endDate" : [NSDate date],
         @"lat" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.latitude],
         @"long" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.longitude],
         @"source" : @"currentPosition",
         } atIndex:0];        
    }

    
    self.searchResults = r;
    [tblView reloadData];
    [tblFade setAlpha:0.0f];
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.requestIdentifier isEqualToString:@"getNearestForPinDrop"]) {
        NSDictionary * r = res;
        CLLocation * coord;
        if ([r objectForKey:@"mapped_coordinate"] && [[r objectForKey:@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([[r objectForKey:@"mapped_coordinate"] count] > 1)) {
            coord = [[CLLocation alloc] initWithLatitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:0] doubleValue] longitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:1] doubleValue]];
        } else {
            coord = req.coord;
        }
        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]];
    }
}

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
}


#pragma mark - nearby places delegate

- (void) nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
    NSMutableArray * arr = [NSMutableArray array];
    if ([[owner.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
        [arr addObject:[owner.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    if ([[owner.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
        [arr addObject:[owner.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    NSString * s = [arr componentsJoinedByString:@", "];
    [self setLocationData:@{
     @"name" : CURRENT_POSITION_STRING,
     @"address" : ([s isEqualToString:@""]?CURRENT_POSITION_STRING:s),
     @"location" : owner.coord,
     @"source" : @"currentPosition",
     @"subsource" : @""
     }];
    if (self.delegate) {
        [self.delegate locationFound:self.locationData];
    }
    [self dismissModalViewControllerAnimated:YES];
//    [self.destinationPin setNearbyObjects:locations];
//    [self.destinationPin setSubtitle:owner.subtitle];
//    [self.destinationPin setTitle:owner.title];
//    [self.destinationPin setDelegate:self];
//    [self.destinationPin setRoutingCoordinate:owner.coord];
//    [self.destinationPin showCallout];
}


@end
