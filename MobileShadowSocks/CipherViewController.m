//
//  CipherViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-5-26.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "CipherViewController.h"

@implementation CipherViewController

+ (BOOL)cipherIsValid:(NSString *)cipher
{
    NSArray *cipherArray = @[@"table",
                             @"rc4",
                             @"aes-128-cfb",
                             @"aes-192-cfb",
                             @"aes-256-cfb",
                             @"bf-cfb",
                             @"camellia-128-cfb",
                             @"camellia-192-cfb",
                             @"camellia-256-cfb",
                             @"cast5-cfb",
                             @"des-cfb",
                             @"idea-cfb",
                             @"rc2-cfb",
                             @"seed-cfb"];
    return [cipherArray containsObject:cipher];
}

+ (NSString *)defaultCipher
{
    return @"table";
}

- (id)initWithStyle:(UITableViewStyle)style withParentView:(SettingTableViewController *)parentView
{
    self = [super initWithStyle:style];
    if (self) {
        _parentView = parentView;
        _cipherNumber = 14;
        _cipherKeyArray = [[NSArray alloc] initWithObjects:
                           @"table",
                           @"rc4",
                           @"aes-128-cfb",
                           @"aes-192-cfb",
                           @"aes-256-cfb",
                           @"bf-cfb",
                           @"camellia-128-cfb",
                           @"camellia-192-cfb",
                           @"camellia-256-cfb",
                           @"cast5-cfb",
                           @"des-cfb",
                           @"idea-cfb",
                           @"rc2-cfb",
                           @"seed-cfb",
                           nil];
        _cipherNameArray = [[NSArray alloc] initWithObjects:
                            NSLocalizedString(@"Table (Default)", nil),
                            NSLocalizedString(@"RC4", nil),
                            NSLocalizedString(@"AES (128-bit, CFB mode)", nil),
                            NSLocalizedString(@"AES (192-bit, CFB mode)", nil),
                            NSLocalizedString(@"AES (256-bit, CFB mode)", nil),
                            NSLocalizedString(@"Blowfish (CFB mode)", nil),
                            NSLocalizedString(@"Camellia (128-bit, CFB mode)", nil),
                            NSLocalizedString(@"Camellia (192-bit, CFB mode)", nil),
                            NSLocalizedString(@"Camellia (256-bit, CFB mode)", nil),
                            NSLocalizedString(@"CAST5 (CFB mode)", nil),
                            NSLocalizedString(@"DES (CFB mode)", nil),
                            NSLocalizedString(@"IDEA (CFB mode)", nil),
                            NSLocalizedString(@"RC2 (CFB mode)", nil),
                            NSLocalizedString(@"SEED (CFB mode)", nil),
                            nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationItem] setTitle:NSLocalizedString(@"Cipher", nil)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *currentSetting = [_parentView readObject:@"CRYPTO_METHOD"];
    NSUInteger index = [_cipherKeyArray indexOfObject:currentSetting ? currentSetting : @"table"];
    _selectedCipher = (index == NSNotFound) ? 0 : index;
    [[self tableView] reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_selectedCipher inSection:0];
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

- (void)dealloc
{
    [_cipherNameArray release];
    [_cipherKeyArray release];
    [super dealloc];
}

#pragma mark - Table view data source

- (void)checkRow:(NSInteger)row
{
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:row inSection:0];
    NSIndexPath *selectedPath = [NSIndexPath indexPathForRow:_selectedCipher inSection:0];
    UITableViewCell *newCell = [[self tableView] cellForRowAtIndexPath:newPath];
    UITableViewCell *selectedCell = [[self tableView] cellForRowAtIndexPath:selectedPath];
    [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
    _selectedCipher = row;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cipherNumber;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"\"Table\" is the default cipher. Other ciphers need ShadowSocks 1.2 or above on the server.", @"nil");
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CipherTableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    }
    [[cell textLabel] setText:[_cipherNameArray objectAtIndex:[indexPath row]]];
    if ([indexPath row] == _selectedCipher) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] != _selectedCipher) {
        [self checkRow:[indexPath row]];
        [_parentView saveObject:[_cipherKeyArray objectAtIndex:_selectedCipher] forKey:@"CRYPTO_METHOD"];
        [_parentView setPrefChanged];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
