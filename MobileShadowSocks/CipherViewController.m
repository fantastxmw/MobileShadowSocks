//
//  CipherViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-5-26.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "CipherViewController.h"
#import "ProfileManager.h"

#define kCipherDefault @"table"

@implementation CipherViewController

+ (NSArray *)cipherArray
{
    static NSArray *cipherArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cipherArray = [[NSArray alloc] initWithArray:@[kCipherDefault,
                                                      @"rc4",
                                                      @"rc4-md5",
                                                      @"aes-128-cfb",
                                                      @"aes-192-cfb",
                                                      @"aes-256-cfb",
                                                      @"bf-cfb",
                                                      @"camellia-128-cfb",
                                                      @"camellia-192-cfb",
                                                      @"camellia-256-cfb",
                                                      @"cast5-cfb",
                                                      @"des-cfb",
                                                      @"rc2-cfb"]];
    });
    return cipherArray;
}

+ (NSArray *)cipherNameArray
{
    static NSArray *cipherNameArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cipherNameArray = [[NSArray alloc] initWithArray:@[NSLocalizedString(@"Table (Default)", nil),
                                                           NSLocalizedString(@"RC4", nil),
                                                           NSLocalizedString(@"RC4 (MD5)", nil),
                                                           NSLocalizedString(@"AES 128-bit", nil),
                                                           NSLocalizedString(@"AES 192-bit", nil),
                                                           NSLocalizedString(@"AES 256-bit (Recommended)", nil),
                                                           NSLocalizedString(@"Blowfish", nil),
                                                           NSLocalizedString(@"Camellia 128-bit", nil),
                                                           NSLocalizedString(@"Camellia 192-bit", nil),
                                                           NSLocalizedString(@"Camellia 256-bit", nil),
                                                           NSLocalizedString(@"CAST5", nil),
                                                           NSLocalizedString(@"DES", nil),
                                                           NSLocalizedString(@"RC2", nil)]];
    });
    return cipherNameArray;
}

+ (BOOL)cipherIsValid:(NSString *)cipher
{
    return [[self cipherArray] containsObject:cipher];
}

+ (NSString *)defaultCipher
{
    return kCipherDefault;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationItem] setTitle:NSLocalizedString(@"Cipher", nil)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *currentSetting = [[ProfileManager sharedProfileManager] readObject:kProfileCrypto];
    NSUInteger index = [[CipherViewController cipherArray] indexOfObject:currentSetting ? currentSetting : kCipherDefault];
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
    return [[CipherViewController cipherArray] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"Table (default cipher) and RC4 are NOT SECURE. Please use stronger encryption like AES or Blowfish.", @"nil");
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
    [[cell textLabel] setText:[[CipherViewController cipherNameArray] objectAtIndex:[indexPath row]]];
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
        [[ProfileManager sharedProfileManager] saveObject:[[CipherViewController cipherArray] objectAtIndex:_selectedCipher]
                                                   forKey:kProfileCrypto];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
