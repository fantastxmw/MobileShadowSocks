//
//  SettingTableViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "SettingTableViewController.h"

#define DAEMON_IS_RUNNING() (system("test -z \"`launchctl list | grep shadowsocks`\""))
#define SETNUM 6
static NSString *defaultSetting[SETNUM] = {@"127.0.0.1", @"8080", @"123456", @"", @"", @""};
static NSString *prefKeyName[SETNUM] = {@"REMOTE_SERVER", @"REMOTE_PORT", @"SOCKS_PASS", @"USE_RC4", @"AUTO_PROXY", @"EXCEPTION_LIST"};

@implementation SettingTableViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
    prefDidChange = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        cellWidth = 560.0f;
    else
        cellWidth = 180.0f;
    UIBarButtonItem *startButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startProcess)];
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop", nil) style:UIBarButtonItemStyleDone target:self action:@selector(stopProcess)];
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showAbout)];
    if (!DAEMON_IS_RUNNING()) {
        [[self navigationItem] setLeftBarButtonItem:startButton];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    else {
        [[self navigationItem] setLeftBarButtonItem:stopButton];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [[self navigationItem] setRightBarButtonItem:aboutButton];
    [[self navigationItem] setTitle:NSLocalizedString(@"ShadowSocks", nil)];
    [startButton release];
    [stopButton release];
    [aboutButton release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)startProcess
{
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    if (![self writeToPref]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to save settings. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        return;
    }
    if (system("/Applications/MobileShadowSocks.app/sshelper -1"))
        [self showRunCmdError];
    else 
        if (DAEMON_IS_RUNNING()) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop", nil) style:UIBarButtonItemStyleDone target:self action:@selector(stopProcess)];
            [[self navigationItem] setLeftBarButtonItem:stopButton];
            [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
            [stopButton release];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to start ShadowSocks. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
        }
}

- (void)revertProxySettings
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (system("/Applications/MobileShadowSocks.app/sshelper -3"))
        [self showRunCmdError];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    UIBarButtonItem *startButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startProcess)];
    [[self navigationItem] setLeftBarButtonItem:startButton];
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    [startButton release];
    [pool release];
}

- (void)stopProcess
{
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    if (system("/Applications/MobileShadowSocks.app/sshelper -2"))
        [self showRunCmdError];
    else
        if (!DAEMON_IS_RUNNING()) {
            NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(revertProxySettings) object:nil];
            [thread start];
            [thread release];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to stop ShadowSocks. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
        }
}

- (BOOL)writeToPref
{
    NSString *prefPath = @"/Applications/MobileShadowSocks.app/proxy.conf";
    if (prefDidChange || ![[NSFileManager defaultManager] fileExistsAtPath:prefPath]) {
        NSString *settingStr;
        NSMutableString *apiPrefContent = [NSMutableString stringWithString:@""];
        int i;
        for (i = 0; i < 5; i++)
            if (i < 3) {
                settingStr = [[NSUserDefaults standardUserDefaults] stringForKey:prefKeyName[i]];
                if (settingStr == nil)
                    settingStr = defaultSetting[i];
                [apiPrefContent appendFormat:@"%@ = '%@'\n", prefKeyName[i], settingStr];
            }
            else {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:prefKeyName[i]])
                    [apiPrefContent appendFormat:@"%@ = True\n", prefKeyName[i]];
                else
                    [apiPrefContent appendFormat:@"%@ = False\n", prefKeyName[i]];
            }
        settingStr = [[NSUserDefaults standardUserDefaults] stringForKey:prefKeyName[5]];
        [apiPrefContent appendFormat:@"%@ = [", prefKeyName[5]];
        if (settingStr != nil && ![settingStr isEqualToString:@""]) {
            NSArray *array = [settingStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
            for (i = 0; i < [array count] - 1; i++)
                if (![[array objectAtIndex:i] isEqualToString:@""])
                    [apiPrefContent appendFormat:@"'%@', ", [array objectAtIndex:i]];
            if ([array count] && ![[array lastObject] isEqualToString:@""])
                [apiPrefContent appendFormat:@"'%@'", [array lastObject]];
        }
        [apiPrefContent appendString:@"]\n"];
        if (![apiPrefContent writeToFile:prefPath atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:prefPath]) {
                if (system("/Applications/MobileShadowSocks.app/sshelper -4"))
                    [self showRunCmdError];
                else {
                    return [apiPrefContent writeToFile:prefPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    prefDidChange = NO;
                }
            }
            return NO;
        }
        prefDidChange = NO;
    }
    return YES;
}

- (void)showRunCmdError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operation failed. Missing necessary files or command utilities.\nPlease check your files and runtime dependency and try again later.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)showAbout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:@"Version 0.1.5\nTwitter: @linusyang\nhttp://linusyang.com/\n\nShadowSocks is created by @clowwindy" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return SETNUM;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Proxy Settings", nil);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@\n© 2013 Linus Yang", NSLocalizedString(@"Localization by Linus Yang", @"Localization Information")];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell-%d", [indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        if ([indexPath row] != 3 && [indexPath row] != 4) {
            NSString *currentSetting = [[NSUserDefaults standardUserDefaults] stringForKey:prefKeyName[[indexPath row]]];
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, cellWidth, 24)];
            [textField setTextColor:[UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:1.0]];
            [textField setText:currentSetting ? currentSetting : @""];
            [textField setPlaceholder:[indexPath row] == 5 ? NSLocalizedString(@"Split with comma", nil) : defaultSetting[[indexPath row]]];
            if ([indexPath row] == 1)
                [textField setKeyboardType:UIKeyboardTypePhonePad];
            if ([indexPath row] == 2)
                [textField setSecureTextEntry:YES];
            [textField setAdjustsFontSizeToFitWidth:YES];
            [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setDelegate:self];
            [textField setTag:[indexPath row]];
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [cell setAccessoryView:textField];
            [textField release];
        }
        else {
            BOOL useCrypto = [[NSUserDefaults standardUserDefaults] boolForKey:prefKeyName[[indexPath row]]];
            UISwitch *cryptSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [cryptSwitch setOn:useCrypto animated:NO];
            [cryptSwitch setTag:[indexPath row]];
            [cryptSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            [cell setAccessoryView:cryptSwitch];
            [cryptSwitch release];
        }
    }
    switch ([indexPath row])
    {
        case 0:
            [[cell textLabel] setText:NSLocalizedString(@"Server", nil)];
            break;
        case 1:
            [[cell textLabel] setText:NSLocalizedString(@"Port", nil)];
            break;
        case 2:
            [[cell textLabel] setText:NSLocalizedString(@"Password", nil)];
            break;
        case 3:
            [[cell textLabel] setText:NSLocalizedString(@"RC4 Crypto", nil)];
            break;
        case 4:
            [[cell textLabel] setText:NSLocalizedString(@"Auto Proxy", nil)];
            break;
        case 5:
            [[cell textLabel] setText:NSLocalizedString(@"Exception", nil)];
            break;
        default:
            break;
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (void)switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    prefDidChange = YES;
    [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:prefKeyName[[switchControl tag]]];
}

#pragma mark - Text field delegate
- (void)hideKeyboard {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]])
            [cell.accessoryView resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    prefDidChange = YES;
    NSString *nowSetting = [textField text];
    if (nowSetting == nil || [nowSetting isEqualToString:@""])
        nowSetting = defaultSetting[[textField tag]];
    [[NSUserDefaults standardUserDefaults] setObject:[textField text] forKey:prefKeyName[[textField tag]]];
}

@end
