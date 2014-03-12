//
//  ProfileViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-12-27.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileManager.h"
#import "UIAlertView+TextField.h"

@interface ProfileViewController ()
- (void)exitEditMode;
@end

@implementation ProfileViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _selectedIndex = [[ProfileManager sharedProfileManager] currentProfile] + 1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self exitEditMode];
    [[self navigationItem] setTitle:NSLocalizedString(@"Profiles", nil)];
    [[self tableView] setAllowsSelectionDuringEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _selectedIndex = [[ProfileManager sharedProfileManager] currentProfile] + 1;
    [[self tableView] reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (DEVICE_IS_IPAD()) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

#pragma mark - Table view data source

- (void)checkRow:(NSInteger)row
{
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:row inSection:0];
    NSIndexPath *selectedPath = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    UITableViewCell *newCell = [[self tableView] cellForRowAtIndexPath:newPath];
    UITableViewCell *selectedCell = [[self tableView] cellForRowAtIndexPath:selectedPath];
    [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
    _selectedIndex = row;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[ProfileManager sharedProfileManager] profileListCount] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ProfileTableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    }
    [[cell textLabel] setText:[[ProfileManager sharedProfileManager] nameOfProfile:[indexPath row] - 1]];
    if ([indexPath row] == _selectedIndex) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == 0) {
        return NO;
    }
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return NO;
    }
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if ([proposedDestinationIndexPath row] == 0) {
        return [NSIndexPath indexPathForRow:1 inSection:[proposedDestinationIndexPath section]];
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (_selectedIndex != 0) {
        [self checkRow:0];
    }
    [[ProfileManager sharedProfileManager] reorderProfile:[sourceIndexPath row] - 1 toIndex:[destinationIndexPath row] - 1];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (_selectedIndex != 0) {
            [self checkRow:0];
        }
        [[ProfileManager sharedProfileManager] removeProfile:[indexPath row] - 1];
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
}

- (void)enterEditMode
{
    [[self tableView] setEditing:YES animated:YES];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(exitEditMode)];
    [[self navigationItem] setRightBarButtonItem:doneButton];
    [doneButton release];
}

- (void)exitEditMode
{
    [[self tableView] setEditing:NO animated:YES];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(enterEditMode)];
    [[self navigationItem] setRightBarButtonItem:editButton];
    [editButton release];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self tableView] isEditing]) {
        if ([indexPath row] > 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Edit Profile", nil)
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"OK",nil),
                                  nil];
            UITextField *textField = [alert textFieldInitAtFirstIndex];
            [textField setText:[[ProfileManager sharedProfileManager] nameOfProfile:[indexPath row] - 1]];
            [textField setPlaceholder:NSLocalizedString(@"Name", nil)];
            [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [alert setTag:[indexPath row] - 1];
            [alert show];
            [alert release];
        }
    } else if ([indexPath row] != _selectedIndex) {
        [self checkRow:[indexPath row]];
        [[ProfileManager sharedProfileManager] selectProfile:_selectedIndex - 1];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        UITextField *textField = [alertView textFieldAtFirstIndex];
        [[ProfileManager sharedProfileManager] renameProfile:[alertView tag] withName:[textField text]];
        [[self tableView] reloadData];
    }
}

@end
