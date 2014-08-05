//
//  SMReportErrorController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 05/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMReportErrorController.h"
#import "SMRadioCheckedCell.h"
#import "SMRadioUncheckedCell.h"
#import "DAKeyboardControl.h"

@interface SMReportErrorController ()
@property (nonatomic, strong) NSString * reportedSegment;
@property (nonatomic, strong) NSArray * possibleErrors;
@property (nonatomic, strong) NSString * reportText;

@property (nonatomic, strong) SMAPIRequest * apr;
@end

@implementation SMReportErrorController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
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
    reportSentView = nil;
    reportEmail = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, tblView.contentSize.height + tblView.frame.origin.y + 50.0f)];
    [fadeView setAlpha:0.0f];
    [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
    pickerOpen = NO;
    self.reportedSegment = @"";
    self.possibleErrors = @[translateString(@"report_wrong_address"), translateString(@"report_road_closed"), translateString(@"report_one_way"), translateString(@"report_illegal_turn"), translateString(@"report_wrong_instruction"), translateString(@"report_other")];
    currentSelection = -1;
    
//    UITableView * tableView = tblView;
    UIScrollView * scr = scrlView;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        CGRect frame = scr.frame;
        frame.size.height = keyboardFrameInView.origin.y;
        scr.frame = frame;
    }];
    
    [tblView reloadData];
    [self arrangeObjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    if (![SMAnalytics trackEventWithCategory:@"Report" withAction:@"Start" withLabel:@"" withValue:0]) {
        debugLog(@"error in trackEvent");
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)inputKeyboardWillHide:(NSNotification *)notification {
    [scrlView setContentOffset:CGPointZero];
    CGRect frame = scrlView.frame;
    frame.size.height = self.view.frame.size.height - 64.0f - scrlView.frame.origin.y;
    [scrlView setFrame:frame];
    [scrlView setContentSize:CGSizeMake(scrlView.frame.size.width, tblView.contentSize.height + tblView.frame.origin.y + 50.0f)];
}

- (IBAction)sendReport:(id)sender {
//    [self sendEmail];
    [self sendAPIReport:nil];
}


- (IBAction)sendAPIReport:(id)sender {
    if (currentSelection < 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"report_error_problem_not_selected") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    if ((self.reportedSegment == nil) || ([self.reportedSegment isEqualToString:@""])) {
        self.reportedSegment = @"";
    }
    
    NSString *str = @"";

    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_from")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n%@\n\n", self.source, self.sourceLoc]];
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_to")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n%@\n\n", self.destination, self.destinationLoc]];
    
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_reason")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", [self.possibleErrors objectAtIndex:currentSelection]]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.reportText]];
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_instruction")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n\n", self.reportedSegment]];
    
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_tbt_instructions")]];
    for (NSString * s in self.routeDirections) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", s]];
    }
    
    
    NSDictionary * d = @{@"issue" : @{
                         @"auth_token" : ([self.appDelegate.appSettings objectForKey:@"auth_token"] == nil)?@"":[self.appDelegate.appSettings objectForKey:@"auth_token"],
                         @"route_segment" : self.reportedSegment,
                         @"error_type": [self.possibleErrors objectAtIndex:currentSelection],
                         @"comment": str,
                         @"notify_user": @0
                         }};
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"login"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_SEND_FEEDBACK withParams:d];
}

- (void)sendEmail {
    if (currentSelection < 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"report_error_problem_not_selected") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
        return;
    }
    
    if ((self.reportedSegment == nil) || ([self.reportedSegment isEqualToString:@""])) {
//        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"report_error_step_not_selected") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
//        [av show];
//        return;
        self.reportedSegment = @"";
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
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n%@\n\n", self.source, self.sourceLoc]];

    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n", translateString(@"report_to")]];
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%@\n%@\n\n", self.destination, self.destinationLoc]];
    
    
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
    [pckrView reloadAllComponents];
    [fadeView setAlpha:1.0f];
    [fadeView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
    CGRect frame = fadeView.frame;
    frame.origin.y = 288.0f;
    [fadeView setFrame:frame];
    
    [self hideKeyboard:nil];
    
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
        [self dismissModalViewControllerAnimated:YES];
        [UIView animateWithDuration:0.4f animations:^{
            [reportSentView setAlpha:1.0f];
        }];
        
//        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:translateString(@"report_sent") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
//        [av show];
//        [self dismissModalViewControllerAnimated:YES];
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
        [cell.radioTextBox setText:self.reportText];
        [cell.radioTextBox setDelegate:self];
        
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
        numberToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               [[UIBarButtonItem alloc]initWithTitle:translateString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard:)],
                               nil];
        [numberToolbar sizeToFit];
        cell.radioTextBox.inputAccessoryView = numberToolbar;
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
    if (currentSelection != indexPath.row) {
        currentSelection = indexPath.row;
        [tableView reloadData];
        [self arrangeObjects];
//        self.reportText = @"";
        
        [((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:indexPath]).radioTextBox becomeFirstResponder];
        CGRect frame = ((SMRadioCheckedCell*)[tblView cellForRowAtIndexPath:indexPath]).frame;
        [scrlView setContentOffset:CGPointMake(0.0f, MAX(frame.origin.y + tblView.frame.origin.y + 210.0f - scrlView.frame.size.height, 0.0f)/*frame.origin.y + tblView.frame.origin.y*/) animated:YES];
//        [tableView setContentOffset:CGPointMake(0.0f, MAX(frame.origin.y + tblView.frame.origin.y + 310.0f - scrlView.frame.size.height, 0.0f)/*frame.origin.y + tblView.frame.origin.y*/) animated:YES];
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
    
//    frame = bottomView.frame;
//    frame.origin.y = tblView.frame.origin.y + tblView.frame.size.height + 10.0f;
//    [bottomView setFrame:frame];
//    [scrlView setContentSize:CGSizeMake(320.0f, bottomView.frame.origin.y + bottomView.frame.size.height + 5.0f)];
    
    [scrlView setContentSize:CGSizeMake(320.0f, tblView.contentSize.height + tblView.frame.origin.y + 50.0f)];
    
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
    [self inputKeyboardWillHide:nil];
}

#pragma mark - api request

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[error description] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if (![SMAnalytics trackEventWithCategory:@"Report" withAction:@"Completed" withLabel:@"" withValue:0]) {
            debugLog(@"error in trackEvent");
        }

        [UIView animateWithDuration:0.4f animations:^{
            [reportSentView setAlpha:1.0f];
        }];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
        [av show];
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

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
