//
//  SMReportErrorController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 05/02/2013.
//  Copyright (c) 2013 Spoiled Milk. All rights reserved.
//

#import "SMReportErrorController.h"
#import "SMRadioCheckedCell.h"
#import "SMRadioUncheckedCell.h"
#import "DAKeyboardControl.h"

@interface SMReportErrorController ()
@property (nonatomic, strong) NSString * reportedSegment;
@property (nonatomic, strong) NSArray * possibleErrors;
@property (nonatomic, strong) NSString * reportText;
@end

@implementation SMReportErrorController

- (void)viewDidLoad {
    [super viewDidLoad];
	[scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, 500.0f)];
    [fadeView setAlpha:0.0f];
    [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
    pickerOpen = NO;
    self.reportedSegment = @"";
    self.possibleErrors = @[translateString(@"report_wrong_address"), translateString(@"report_one_way"), translateString(@"report_road_closed"), translateString(@"report_illegal_turn"), translateString(@"report_other")];
    currentSelection = -1;
    
    UITableView * tableView = tblView;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        CGRect tableViewFrame = tableView.frame;
        tableViewFrame.size.height = keyboardFrameInView.origin.y;
        tableView.frame = tableViewFrame;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    btnSelectRouteSegment = nil;
    switchContactMe = nil;
    scrlView = nil;
    fadeView = nil;
    pckrView = nil;
    tblView = nil;
    bottomView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [tblView reloadData];
    [self arrangeObjects];
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sendReport:(id)sender {
    [self sendEmail];
}

- (IBAction)showHidePicker:(id)sender {
    if (pickerOpen) {
        [self hidePicker];
    } else {
        [self showPicker];
    }
}

- (IBAction)pickerCancel:(id)sender {
    [self hidePicker];
}

- (IBAction)pickerDone:(id)sender {
    [self hidePicker];
    if (([pckrView selectedRowInComponent:0] >= 0) && ([pckrView selectedRowInComponent:0] < [self.routeDirections count])) {
        self.reportedSegment = [self.routeDirections objectAtIndex:[pckrView selectedRowInComponent:0]];
        [btnSelectRouteSegment setTitle:self.reportedSegment forState:UIControlStateNormal];
    }
}

#pragma mark - picker delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.routeDirections count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.routeDirections objectAtIndex:row];
}

#pragma mark - custom methods

- (void)sendEmail {
    if (currentSelection < 0) {
        return;
    }
    
    if ((self.reportedSegment == nil) || ([self.reportedSegment isEqualToString:@""])) {
        return;
    }
    
    MFMailComposeViewController * mvc = [[MFMailComposeViewController alloc] init];
    [mvc setSubject:translateString(@"report_subject")];
    [mvc setToRecipients:MAIL_RECIPIENTS];
    [mvc setMailComposeDelegate:self];
    NSString *str = @"";
    if (switchContactMe.on) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", translateString(@"report_contact_me")]];
    }

    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_from")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.source]];

    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_to")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.destination]];
    
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_reason")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", [self.possibleErrors objectAtIndex:currentSelection]]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.reportText]];
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_instruction")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.reportedSegment]];

    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_tbt_instructions")]];
    for (NSString * s in self.routeDirections) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", s]];
    }
    
    [mvc setMessageBody:str isHTML:NO];

    [self presentModalViewController:mvc animated:YES];
}

- (void)showPicker {
    [fadeView setAlpha:1.0f];
    [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
    CGRect frame = fadeView.frame;
    frame.origin.y = 288.0f;
    [fadeView setFrame:frame];
    
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = fadeView.frame;
        frame.origin.y = 0.0f;
        [fadeView setFrame:frame];
    } completion:^(BOOL finished) {
        pickerOpen = YES;
        [UIView animateWithDuration:0.4f animations:^{
            [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.7f]];
        }];
    }];
}

- (void)hidePicker {
    CGRect frame = fadeView.frame;
    frame.origin.y = 0.0f;
    [fadeView setFrame:frame];
    [UIView animateWithDuration:0.4f animations:^{
        [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4f animations:^{
            CGRect frame = fadeView.frame;
            frame.origin.y = 288.0f;
            [fadeView setFrame:frame];
        } completion:^(BOOL finished) {
            pickerOpen = NO;
            [fadeView setAlpha:0.0f];
        }];
    }];
}

#pragma mark - mail send delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if (result == MFMailComposeResultSent) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"report_sent") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        [self dismissModalViewControllerAnimated:YES];
//        [self goBack:nil];
    } else {
        [controller dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.possibleErrors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == currentSelection) {
        NSString * identifier = @"reportRadioChecked";
        SMRadioCheckedCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.radioTitle setText:[self.possibleErrors objectAtIndex:indexPath.row]];
        [cell.radioTextBox setText:@""];
        [cell.radioTextBox setDelegate:self];
        
//        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
//        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
//        numberToolbar.items = [NSArray arrayWithObjects:
//                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
//                               [[UIBarButtonItem alloc]initWithTitle:translateString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard:)],
//                               nil];
//        [numberToolbar sizeToFit];
//        cell.radioTextBox.inputAccessoryView = numberToolbar;
        return cell;
    } else {
        NSString * identifier = @"reportRadioUnchecked";
        SMRadioUncheckedCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.radioTitle setText:[self.possibleErrors objectAtIndex:indexPath.row]];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (currentSelection >= 0) {
        [((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentSelection inSection:0]]).radioTextBox resignFirstResponder];
        return;
    }
    if (currentSelection != indexPath.row) {
        currentSelection = indexPath.row;
        [tableView reloadData];
        [self arrangeObjects];
        self.reportText = @"";
        
        [((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:indexPath]).radioTextBox becomeFirstResponder];
        CGRect frame = ((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:indexPath]).frame;
        [scrlView setContentOffset:CGPointMake(0.0f, frame.origin.y + tblView.frame.origin.y) animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == currentSelection) {
        return [SMRadioCheckedCell getHeight];
    } else {
        return [SMRadioUncheckedCell getHeight];
    }
}

- (void)arrangeObjects {
    CGRect frame = tblView.frame;
    frame.size.height = tblView.contentSize.height;
    [tblView setFrame:frame];
    
    frame = bottomView.frame;
    frame.origin.y = tblView.frame.origin.y + tblView.frame.size.height + 10.0f;
    [bottomView setFrame:frame];
    
    [scrlView setContentSize:CGSizeMake(320.0f, bottomView.frame.origin.y + bottomView.frame.size.height + 5.0f)];
    
}

#pragma mark - textview delegate 

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * s = [textView.text stringByReplacingCharactersInRange:range withString:text];
    self.reportText = s;
    return YES;
}

- (IBAction)hideKeyboard:(id)sender {
    if (currentSelection >= 0) {
        [((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentSelection inSection:0]]).radioTextBox resignFirstResponder];
    }
}

@end
