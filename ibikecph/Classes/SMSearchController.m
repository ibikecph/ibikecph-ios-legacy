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
#import "SMRouteUtils.h"
#import "SMRequestOSRM.h"
#import "SMFavoritesUtil.h"
#import "SMAPIQueue.h"
#import "SMAddressParser.h"

@interface SMSearchController ()
@property (nonatomic, strong) NSArray * searchResults;
@property (nonatomic, strong) NSMutableArray * tempSearch;
@property (nonatomic, strong) SMAutocomplete * autocomp;
@property (nonatomic, strong) NSArray * favorites;

@property (nonatomic, strong) NSMutableArray * terms;
@property (nonatomic, strong) NSString * srchString;
//@property (nonatomic, strong) SMRequestOSRM * req;

@property (nonatomic, strong) SMAPIQueue * queue;
@end

@implementation SMSearchController

- (id)init {
    self = [super init];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (void)viewDidUnload {
    tblView = nil;
    tblFade = nil;
    searchField = nil;
    
    [self.queue stopAllRequests];
    self.queue = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [searchField setText:self.searchText];
    self.autocomp = [[SMAutocomplete alloc] initWithDelegate:self];
    [tblView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [searchField becomeFirstResponder];
    [self setFavorites:[SMFavoritesUtil getFavorites]];
    
    self.queue = [[SMAPIQueue alloc] initWithMaxOperations:3];
    self.queue.delegate = self;
    
    [self setReturnKey];
    
}

- (void)setReturnKey {
    if (self.locationData) {
        [searchField setReturnKeyType:UIReturnKeyGo];
        [searchField resignFirstResponder];
        [searchField becomeFirstResponder];
    } else {
        [searchField setReturnKeyType:UIReturnKeyDone];
        [searchField resignFirstResponder];
        [searchField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    UITableView * tbl = tblView;
    UIView * fade = tblFade;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        [tbl setFrame:CGRectMake(0.0f, tbl.frame.origin.y, tbl.frame.size.width, keyboardFrameInView.origin.y - tbl.frame.origin.y)];
        [fade setFrame:tbl.frame];
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

- (NSArray*)getSearchTerms {
    

    NSDictionary * d = [SMAddressParser parseAddress:searchField.text];
    NSMutableArray * arr = [NSMutableArray array];
    for (NSString * key in [d allKeys]) {
        [arr addObject:[d objectForKey:key]];
    }
    NSString * search = [arr componentsJoinedByString:@" "];
    NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [set addCharactersInString:@","];
    search = [search stringByTrimmingCharactersInSet:set];
    
    NSRegularExpression * exp = [NSRegularExpression regularExpressionWithPattern:@"[,\\s]+" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSMutableString * separatedSearch = [NSMutableString stringWithString:search];
    [exp replaceMatchesInString:separatedSearch options:0 range:NSMakeRange(0, [search length]) withTemplate:@" "];
    return [separatedSearch componentsSeparatedByString:@" "];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * currentRow = [self.searchResults objectAtIndex:indexPath.row];
    NSString * identifier;


    NSArray * words = [self getSearchTerms];
    
    
    SMSearchCell * cell;
    if ([currentRow objectForKey:@"line1"]) {
        if ([currentRow objectForKey:@"line2"] && [[currentRow objectForKey:@"line2"] isEqualToString:@""] == NO) {
            identifier = @"searchTwoRowsCell";
            SMSearchTwoRowCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            [cell.addressLabel setText:[currentRow objectForKey:@"line2"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    
                    if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                        UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.addressLabel.font.pointSize];
                        
                        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                        
                        if (font) {
                            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                            CFRelease(font);
                            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                        }
                        
                    }
                }
                
                return mutableAttributedString;
            }];
            
            [cell.nameLabel setText:[currentRow objectForKey:@"line1"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    
                    cell.nameLabel.textColor = [UIColor lightGrayColor];
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                }
                return mutableAttributedString;
            }];
            [cell setImageWithData:currentRow];
            return cell;
        } else {
            identifier = @"searchCell";
            SMSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            
            [cell.nameLabel setText:[currentRow objectForKey:@"line1"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                }
                return mutableAttributedString;
            }];
            [cell setImageWithData:currentRow];
            return cell;
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
        identifier = @"searchCell";
        SMSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
        [cell setImageWithData:currentRow];
        return cell;
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"] || [[currentRow objectForKey:@"subsource"] isEqualToString:@"places"]) && [[currentRow objectForKey:@"address"] isEqualToString:@""] == NO) {
        identifier = @"searchTwoRowsCell";
        SMSearchTwoRowCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.addressLabel setText:[currentRow objectForKey:@"address"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.addressLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                    
                }
            }
            
            return mutableAttributedString;
        }];
        
        [cell.nameLabel setText:[currentRow objectForKey:@"name"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                cell.nameLabel.textColor = [UIColor lightGrayColor];
                UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                
                if (font) {
                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                    CFRelease(font);
                    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                }
            }
            return mutableAttributedString;
        }];
        [cell setImageWithData:currentRow];
        return cell;
    } else if ([currentRow objectForKey:@"address"] && [[currentRow objectForKey:@"address"] isEqualToString:@""] == NO){
        NSDictionary * d = [SMAddressParser parseAddress:[currentRow objectForKey:@"address"]];
        NSMutableArray * arr = [NSMutableArray array];
        if ([d objectForKey:@"street"]) {
            [arr addObject:[[d objectForKey:@"street"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        if ([d objectForKey:@"number"]) {
            [arr addObject:[[d objectForKey:@"number"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        NSString * line1 = [arr componentsJoinedByString:@" "];
        
        arr = [NSMutableArray array];
        if ([d objectForKey:@"zip"]) {
            [arr addObject:[[d objectForKey:@"zip"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        if ([d objectForKey:@"city"]) {
            [arr addObject:[[d objectForKey:@"city"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        NSString * line2 = [arr componentsJoinedByString:@" "];        
        if (line2 && [line2 isEqualToString:@""] == NO) {
            identifier = @"searchTwoRowsCell";
            SMSearchTwoRowCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            [cell.addressLabel setText:line2 afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    
                    if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                        UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.addressLabel.font.pointSize];
                        
                        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                        
                        if (font) {
                            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                            CFRelease(font);
                            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                        }
                        
                    }
                }
                
                return mutableAttributedString;
            }];
            
            [cell.nameLabel setText:line1 afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    
                    cell.nameLabel.textColor = [UIColor lightGrayColor];
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                }
                return mutableAttributedString;
            }];
            [cell setImageWithData:currentRow];
            return cell;
        } else {
            identifier = @"searchCell";
            SMSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            
            [cell.nameLabel setText:line1 afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                }
                return mutableAttributedString;
            }];
            [cell setImageWithData:currentRow];
            return cell;
        }
    } else {
        identifier = @"searchCell";
        SMSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if ([[currentRow objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
            [cell.nameLabel setText:[currentRow objectForKey:@"name"]];
        } else {
            [cell.nameLabel setText:[currentRow objectForKey:@"name"] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                for (NSString * srch in words) {
                    NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                }
                return mutableAttributedString;
            }];
        }
        [cell setImageWithData:currentRow];
        return cell;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary * currentRow = [self.searchResults objectAtIndex:indexPath.row];
    [searchField setText:[currentRow objectForKey:@"name"]];
    
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
    [self setReturnKey];

    if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"oiorest"]) {
        searchField.text = [currentRow objectForKey:@"address"];
        NSString * street = [currentRow objectForKey:@"street"];
        if(street.length > 0) {
            [self stopAll];
            [self delayedAutocomplete:searchField.text];
            [self setCaretForSearchFieldOnPosition:[NSNumber numberWithInt:street.length+1]];
        } else {
            [self checkLocation];
        }
    } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
        if ([SMLocationManager instance].hasValidLocation) {
            CLLocation * loc = [SMLocationManager instance].lastValidLocation;
            if (loc) {
                [self setLocationData:@{
                                        @"name" : CURRENT_POSITION_STRING,
                                        @"address" : CURRENT_POSITION_STRING,
                                        @"location" : loc,
                                        @"source" : @"currentPosition",
                                        @"subsource" : @""
                                        }];
                if (self.delegate) {
                    [self.delegate locationFound:self.locationData];
                }
                [self goBack:nil];
            }
        }
    } else {
        if (self.delegate) {
            [self.delegate locationFound:self.locationData];
        }
        [self goBack:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMSearchCell getHeight];
}

#pragma mark - custom methods 

- (void)stopAll {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
    self.searchResults = @[];
    self.tempSearch = [NSMutableArray array];
    [self.queue stopAllRequests];
}

- (void)delayedAutocomplete:(NSString*)text {
    [tblFade setAlpha:1.0f];
    [tblView reloadData];
    [self.queue addTasks:[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)showFade {
    [tblFade setAlpha:1.0f];
}

- (void)hideFade {
    [UIView animateWithDuration:0.2f delay:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        tblFade.alpha = 0.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)checkLocation {
    if ([searchField.text isEqualToString:@""] == NO) {
        if ([searchField.text isEqualToString:CURRENT_POSITION_STRING]) {
            
        } else {
            [tblFade setAlpha:1.0f];
            if (self.locationData && [self.locationData objectForKey:@"location"]) {
                if (self.delegate) {
                    [self.delegate locationFound:self.locationData];
                    [self goBack:nil];
                }
                [self hideFade];
            } else {
                [self hideFade];
                if (self.searchResults && self.searchResults.count > 0) {
                    NSDictionary * currentRow = [self.searchResults objectAtIndex:0];
                    if ([[currentRow objectForKey:@"source"] isEqualToString:@"currentPosition"]) {
                        currentRow = nil;
                         if (self.searchResults && self.searchResults.count > 1) {
                             currentRow = [self.searchResults objectAtIndex:1];
                         }
                    }
                    if (currentRow) {
                        [searchField setText:[currentRow objectForKey:@"name"]];
                        
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
                            [self goBack:nil];
                        }
                    }

                }
                
                
//                [SMGeocoder geocode:searchField.text completionHandler:^(NSArray *placemarks, NSError *error) {
//                    if ([placemarks count] > 0) {
//                        MKPlacemark *coord = [placemarks objectAtIndex:0];
//                        [self goBack:nil];
//                        if (self.delegate) {
//                            [self.delegate locationFound:@{
//                                                           @"name" : searchField.text,
//                                                           @"address" : searchField.text,
//                                                           @"location" : [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude],
//                                                           @"source" : @"typedIn"
//                                                           }];
//                        }
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
//                        });
//                    } else {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
//                        });
//                    }
//                }];
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
        });
    }
}



- (void) setCaretForSearchFieldOnPosition:(NSNumber*) pos{
    //If pos is > 0 that means that this is a first call.
    //First call will be used to set cursor to begining and call recursively this method again with delay to set real position
    int num = [pos intValue];
    if(num > 0){
        UITextPosition * from = [searchField positionFromPosition:[searchField beginningOfDocument] offset:0];
        UITextPosition * to =[searchField positionFromPosition:[searchField beginningOfDocument] offset:0];
        [searchField setSelectedTextRange:[searchField textRangeFromPosition:from toPosition:to]];
        NSNumber * newPos = [NSNumber numberWithInt:-num];
        [self performSelector:@selector(setCaretForSearchFieldOnPosition:) withObject:newPos afterDelay:0.3];
    } else {
        num = -num;
        UITextPosition * from = [searchField positionFromPosition:[searchField beginningOfDocument] offset:num];
        UITextPosition * to =[searchField positionFromPosition:[searchField beginningOfDocument] offset:num];
        [searchField setSelectedTextRange:[searchField textRangeFromPosition:from toPosition:to]];
    }
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.queue stopAllRequests];
    self.queue.delegate = nil;
    self.queue = nil;
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * s = [[textField.text stringByReplacingCharactersInRange:range withString:string] capitalizedString];
    if ([[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] == NO) {
        self.locationData = nil;
//        [self setReturnKey];
    }
    [self stopAll];
    if ([s length] >= 2) {
        [self delayedAutocomplete:s];
//        [self performSelector:@selector(delayedAutocomplete:) withObject:s afterDelay:0.5f];
    } else if ([s length] == 1) {
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
        tblFade.alpha = 0.0f;
    } else {
        self.searchResults = @[];
        [tblView reloadData];
        tblFade.alpha = 0.0f;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.locationData = nil;
    [self setReturnKey];
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
    @synchronized(self.searchResults) {
        
        SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
        NSMutableArray * r = [NSMutableArray array];
        
        if ([str isEqualToString:@""]) {
            self.searchResults = r;
            [tblView reloadData];
            [tblFade setAlpha:0.0f];
            return;
        }
        
//        if ([[str lowercaseString] isEqualToString:[searchField.text lowercaseString]] == NO) {
//            return;
//        }
        
        self.terms = [NSMutableArray array];
        self.srchString = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for (NSString * str in [self.srchString componentsSeparatedByString:@" "]) {
            if ([self.terms indexOfObject:str] == NSNotFound) {
                [self.terms addObject:str];
            }
        }
        
        for (NSDictionary * d in arr) {
            BOOL found = NO;
            for (NSDictionary * d1 in r) {
                if ([[d1 objectForKey:@"name"] isEqualToString:[d objectForKey:@"name"]] && [[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO) {
                [r addObject:d];                
            }
        }
        
        
        for (int i = 0; i < [self.favorites count]; i++) {
            BOOL found = NO;
            NSDictionary * d = [self.favorites objectAtIndex:i];
            for (NSDictionary * d1 in r) {
                if ([[d1 objectForKey:@"name"] isEqualToString:[d objectForKey:@"name"]] && [[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO && [SMRouteUtils pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
                [r addObject:d];
            }
        }
        
        for (int i = 0; i < [appd.searchHistory count]; i++) {
            BOOL found = NO;
            NSDictionary * d = [appd.searchHistory objectAtIndex:i];
            for (NSDictionary * d1 in r) {
                if ([[d1 objectForKey:@"name"] isEqualToString:[d objectForKey:@"name"]] && [[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO && [SMRouteUtils pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
                debugLog(@"Object: %@\nString: %@\npoints: %d\n", d, str, [SMRouteUtils pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str]);
                [r addObject:d];
            }
        }
        
        [r sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
//            NSComparisonResult cmp = [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
//            if (cmp == NSOrderedSame) {
//                cmp = [[obj2 objectForKey:@"relevance"] compare:[obj1 objectForKey:@"relevance"]];
//                if (cmp == NSOrderedSame) {
                
                    double dist1 = 0.0f;
                    double dist2 = 0.0f;
                    if ([obj1 objectForKey:@"distance"]) {
                        dist1 = [[obj1 objectForKey:@"distance"] doubleValue];
                    } else if ([obj1 objectForKey:@"lat"] && [obj1 objectForKey:@"long"]) {
                        dist1 = [[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue]  longitude:[[obj1 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
                    }
                    
                    if ([obj2 objectForKey:@"distance"]) {
                        dist2 = [[obj2 objectForKey:@"distance"] doubleValue];
                    } else if ([obj2 objectForKey:@"lat"] && [obj2 objectForKey:@"long"]) {
                        dist2 = [[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue]  longitude:[[obj2 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
                    }
                    
                    if (dist1 > dist2) {
                        return NSOrderedDescending;
                    } else if (dist1 < dist2) {
                        return NSOrderedAscending;
                    } else {
                        return [[obj2 objectForKey:@"relevance"] compare:[obj1 objectForKey:@"relevance"]];
                    }
//                }
//            }
//            return NSOrderedSame;
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
}

#pragma mark - api operation delegate

-(void)queuedRequest:(SMAPIOperation *)object failedWithError:(NSError *)error {
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];
//    @synchronized(self.queue) {
//        if ([self.queue.queue operationCount] == 0) {
            [self hideFade];
//        }
//    }
}

- (void)queuedRequest:(SMAPIOperation *)object finishedWithResult:(id)result {
    [self.tempSearch addObjectsFromArray:result];
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];
//    @synchronized(self.queue) {
//        if ([self.queue.queue operationCount] == 0) {
            [self hideFade];
//        }
//    }
}


@end
