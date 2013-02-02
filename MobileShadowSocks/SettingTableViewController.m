//
//  SettingTableViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "SettingTableViewController.h"

#define DAEMON_IS_RUNNING() (system("test -z \"`launchctl list | grep shadowsocks`\"") ? YES : NO)
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
    _prefDidChange = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        _cellWidth = 560.0f;
    else
        _cellWidth = 180.0f;
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(startProcess)];
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showAbout)];
    [[self navigationItem] setLeftBarButtonItem:leftButton];
    [[self navigationItem] setRightBarButtonItem:aboutButton];
    [[self navigationItem] setTitle:NSLocalizedString(@"ShadowSocks", nil)];
    [leftButton release];
    [aboutButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setRunningStatus:DAEMON_IS_RUNNING()];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setRunningStatus:(BOOL)isRunning
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:isRunning];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:(isRunning ? 1 : 0)];
    [self setViewEnabled:!isRunning];
    if ([[self navigationItem] leftBarButtonItem]) {
        [[[self navigationItem] leftBarButtonItem] setTitle:(isRunning ? NSLocalizedString(@"Stop", nil) : NSLocalizedString(@"Start", nil))];
        [[[self navigationItem] leftBarButtonItem] setStyle:(isRunning ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered)];
        [[[self navigationItem] leftBarButtonItem] setAction:(isRunning ? @selector(stopProcess) : @selector(startProcess))];
    }
}

- (void)startProcess
{
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    [self hideKeyboard];
    if (![self writeToPref]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to save settings. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    else if (system("/Applications/MobileShadowSocks.app/sshelper -1"))
        [self showRunCmdError];
    else if (DAEMON_IS_RUNNING())
        [self setRunningStatus:YES];
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to start ShadowSocks. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
}

- (void)revertProxySettings
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (system("/Applications/MobileShadowSocks.app/sshelper -3"))
        [self performSelectorOnMainThread:@selector(showRunCmdError) withObject:nil waitUntilDone:NO];
    [self setRunningStatus:NO];
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    [pool release];
}

- (void)stopProcess
{
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    [self hideKeyboard];
    if (system("/Applications/MobileShadowSocks.app/sshelper -2")) {
        [self showRunCmdError];
        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    }
    else if (!DAEMON_IS_RUNNING()) {
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(revertProxySettings) object:nil];
        [thread start];
        [thread release];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Failed to stop ShadowSocks. Please try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
    }
}

- (BOOL)writeToPref
{
    NSString *prefPath = @"/Applications/MobileShadowSocks.app/proxy.conf";
    if (_prefDidChange || ![[NSFileManager defaultManager] fileExistsAtPath:prefPath]) {
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
        _prefDidChange = ![apiPrefContent writeToFile:prefPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        if (_prefDidChange) {
            if (system("/Applications/MobileShadowSocks.app/sshelper -4"))
                [self showRunCmdError];
            else
                _prefDidChange = ![apiPrefContent writeToFile:prefPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
    return !_prefDidChange;
}

- (void)showRunCmdError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operation failed. Missing necessary files or command utilities.\nPlease check your files and runtime dependency and try again later.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)showAbout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:@"Version 0.1.8\nTwitter: @linusyang\nhttp://linusyang.com/\n\nShadowSocks is created by @clowwindy" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
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
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, _cellWidth, 24)];
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
    _prefDidChange = YES;
    [[NSUserDefaults standardUserDefaults] setBool:switchControl.on forKey:prefKeyName[[switchControl tag]]];
}

#pragma mark - Text field delegate
- (void)hideKeyboard {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]])
            [cell.accessoryView resignFirstResponder];
    }
}

- (void)setViewEnabled:(BOOL)isEnabled {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *) cell.accessoryView;
            [textField setEnabled:isEnabled];
        } 
        else if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
            UISwitch *switcher = (UISwitch *) cell.accessoryView;
            [switcher setEnabled:isEnabled];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    _prefDidChange = YES;
    NSString *nowSetting = [textField text];
    if (nowSetting == nil || [nowSetting isEqualToString:@""])
        nowSetting = defaultSetting[[textField tag]];
    [[NSUserDefaults standardUserDefaults] setObject:[textField text] forKey:prefKeyName[[textField tag]]];
}

@end
