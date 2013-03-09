//
//  SettingTableViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "SettingTableViewController.h"

#define kgrayBlueColor [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:1.0]
#define kgrayBlueColorDisabled [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:0.439216f]

@implementation SettingTableViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
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
    _utility = [[ShadowUtility alloc] initWithDaemonIdentifier:DAEMON_ID];
    _tagNumber = 0;
    _tagKey = [[NSMutableArray alloc] init];
    _tagAlwaysEnabled = [[NSMutableArray alloc] init];
    _tableSectionNumber = 2;
    _tableRowNumber = [[NSArray alloc] initWithObjects:
                       [NSNumber numberWithInt:4], 
                       [NSNumber numberWithInt:3], 
                       nil];
    _tableSectionTitle = [[NSArray alloc] initWithObjects:
                          NSLocalizedString(@"Server Information", nil), 
                          NSLocalizedString(@"Proxy Settings", nil), 
                          nil];
    _tableElements = [[NSArray alloc] initWithObjects:
                      [NSArray arrayWithObjects:
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Server", nil), 
                        @"REMOTE_SERVER", 
                        @"127.0.0.1", 
                        CELL_TEXT, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Port", nil), 
                        @"REMOTE_PORT", 
                        @"8080", 
                        CELL_TEXT CELL_NUM, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Password", nil), 
                        @"SOCKS_PASS", 
                        @"123456", 
                        CELL_TEXT CELL_PASS, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"RC4 Crypto", nil), 
                        @"USE_RC4", 
                        @"NO", 
                        CELL_SWITCH, nil], 
                       nil],
                      [NSArray arrayWithObjects:
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Auto Proxy", nil), 
                        @"AUTO_PROXY", 
                        @"NO", 
                        CELL_SWITCH CELL_ALWAYS, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"PAC File", nil), 
                        @"PAC_FILE", 
                        [NSString stringWithFormat:@"%@/auto.pac", [[NSBundle mainBundle] bundlePath]], 
                        CELL_TEXT CELL_ALWAYS, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Exceptions", nil), 
                        @"EXCEPTION_LIST", 
                        NSLocalizedString(@"Split with comma", nil), 
                        CELL_TEXT, nil], 
                       nil],  
                      nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [NSThread detachNewThreadSelector:@selector(threadInitProxyStatus) toTarget:self withObject:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc
{
    [_utility release];
    [_tableRowNumber release];
    [_tableSectionTitle release];
    [_tableElements release];
    [_tagKey release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableSectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *rowNumber = (NSNumber *) [_tableRowNumber objectAtIndex:section];
    return [rowNumber intValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return (NSString *) [_tableSectionTitle objectAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == _tableSectionNumber - 1)
        return [NSString stringWithFormat:@"%@\n© 2013 Linus Yang", NSLocalizedString(@"Localization by Linus Yang", @"Localization Information")];
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"%ld-%ld", [indexPath section], [indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        NSArray *tableSection = [_tableElements objectAtIndex:[indexPath section]];
        NSArray *tableCell = [tableSection objectAtIndex:[indexPath row]];
        NSString *cellTitle = (NSString *) [tableCell objectAtIndex:0];
        NSString *cellType = (NSString *) [tableCell objectAtIndex:3];
        NSString *cellDefaultValue = (NSString *) [tableCell objectAtIndex:2];
        NSString *cellKey = (NSString *) [tableCell objectAtIndex:1];
        [[cell textLabel] setText:cellTitle];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        if ([cellType hasPrefix:CELL_TEXT]) {
            NSString *currentSetting = [[NSUserDefaults standardUserDefaults] stringForKey:cellKey];
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, _cellWidth, 24)];
            [textField setTextColor:kgrayBlueColor];
            [textField setText:currentSetting ? currentSetting : @""];
            [textField setPlaceholder:cellDefaultValue];
            if ([cellType hasSuffix:CELL_NUM])
                [textField setKeyboardType:UIKeyboardTypePhonePad];
            if ([cellType hasSuffix:CELL_PASS])
                [textField setSecureTextEntry:YES];
            [textField setAdjustsFontSizeToFitWidth:YES];
            [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setDelegate:self];
            [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [textField setTag:_tagNumber];
            if ([cellKey isEqualToString:@"PAC_FILE"]) {
                _pacFileCellTag = _tagNumber;
                BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTO_PROXY"];
                [textField setEnabled:isEnabled];
                if (!isEnabled)
                    [textField setTextColor:kgrayBlueColorDisabled];
                [[cell textLabel] setAlpha:isEnabled ? 1.0f : 0.439216f];
                [cell setUserInteractionEnabled:isEnabled];
            }
            [_tagKey addObject:cellKey];
            if ([cellType hasSuffix:CELL_ALWAYS])
                [_tagAlwaysEnabled addObject:[NSNumber numberWithInt:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:textField];
            [textField release];
        }
        else if ([cellType hasPrefix:CELL_SWITCH]) {
            BOOL switchValue = [[NSUserDefaults standardUserDefaults] boolForKey:cellKey];
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switcher setOn:switchValue animated:NO];
            [switcher addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            [switcher setTag:_tagNumber];
            if ([cellKey isEqualToString:@"AUTO_PROXY"])
                _autoProxyCellTag = _tagNumber;
            [_tagKey addObject:cellKey];
            if ([cellType hasSuffix:CELL_ALWAYS])
                [_tagAlwaysEnabled addObject:[NSNumber numberWithInt:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:switcher];
            [switcher release];
        }
    }
    return cell;
}

#pragma mark - Alert views

- (void)showAbout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:@"Version " APP_VER @" (Rev " APP_BUILD @")\nTwitter: @linusyang\nhttp://linusyang.com/\n\nShadowSocks is created by @clowwindy" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)showError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Operation failed.\nPlease try again later.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)showFileNotFound
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"PAC file not found. Use default instead.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

#pragma mark - Switch delegate

- (void)setPacFileCellEnabled:(BOOL)isEnabled
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *) cell.accessoryView;
            if ([textField tag] == _pacFileCellTag) {
                [textField setEnabled:isEnabled];
                [textField setTextColor:isEnabled ? kgrayBlueColor : kgrayBlueColorDisabled];
                [[cell textLabel] setAlpha:isEnabled ? 1.0f : 0.439216f];
                [cell setUserInteractionEnabled:isEnabled];
            }
        }
    }
}

- (void)switchChanged:(id)sender
{
    UISwitch* switcher = sender;
    NSString *key = (NSString *) [_tagKey objectAtIndex:[switcher tag]];
    [[NSUserDefaults standardUserDefaults] setBool:switcher.on forKey:key];
    if ([switcher tag] == _autoProxyCellTag)
        [self setPacFileCellEnabled:switcher.on];
}

#pragma mark - Text field delegate

- (void)hideKeyboard
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]])
            [cell.accessoryView resignFirstResponder];
    }
}

- (void)setViewEnabled:(BOOL)isEnabled
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *) cell.accessoryView;
            if ([_tagAlwaysEnabled indexOfObject:[NSNumber numberWithInt:[textField tag]]] == NSNotFound) {
                [textField setEnabled:isEnabled];
                [textField setTextColor:isEnabled ? kgrayBlueColor : kgrayBlueColorDisabled];
                [[cell textLabel] setAlpha:isEnabled ? 1.0f : 0.439216f];
                [cell setUserInteractionEnabled:isEnabled];
            }
        } 
        else if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
            UISwitch *switcher = (UISwitch *) cell.accessoryView;
            if ([_tagAlwaysEnabled indexOfObject:[NSNumber numberWithInt:[switcher tag]]] == NSNotFound) {
                [switcher setEnabled:isEnabled];
                [[cell textLabel] setAlpha:isEnabled ? 1.0f : 0.439216f];
                [cell setUserInteractionEnabled:isEnabled];
            }
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
    NSString *key = (NSString *) [_tagKey objectAtIndex:[textField tag]];
    [[NSUserDefaults standardUserDefaults] setObject:[textField text] forKey:key];
}

#pragma mark - Proxy threads

- (void)threadRunProxy:(NSNumber *)willStart
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL start = [willStart boolValue];
    BOOL run = NO;
    if (start) {
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSString *pacFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"PAC_FILE"];
        if (pacFile) {
            pacFile = [pacFile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (![pacFile isEqualToString:@""] && ![[NSFileManager defaultManager] fileExistsAtPath:pacFile])
                [self performSelectorOnMainThread:@selector(showFileNotFound) withObject:nil waitUntilDone:YES];
        }
    }
    if ([_utility startStopDaemon:start]) {
        if ([_utility setProxy:start])
            run = YES;
    }
    if (!run) {
        [self performSelectorOnMainThread:@selector(showError) withObject:nil waitUntilDone:YES];
        start = NO;
    }
    [self performSelectorOnMainThread:@selector(doAfterProcess:) withObject:[NSNumber numberWithBool:start] waitUntilDone:NO];
    [pool release];
}

- (void)threadFixProxy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSDictionary *proxySettings = (NSDictionary *) CFNetworkCopySystemProxySettings();
    BOOL isRunning = [_utility isRunning];
    BOOL proxyEnabled = [[proxySettings objectForKey:(NSString *) kCFNetworkProxiesProxyAutoConfigEnable] boolValue];
    if (isRunning != proxyEnabled)
        [_utility setProxy:isRunning];
    [pool release];
}

- (void)threadInitProxyStatus
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL isRunning = [_utility isRunning];
    [self performSelectorOnMainThread:@selector(setRunningStatus:) withObject:[NSNumber numberWithBool:isRunning] waitUntilDone:NO];
    [pool release];
}

#pragma mark - Proxy functions

- (void)setRunningStatus:(NSNumber *)running
{
    BOOL isRunning = [running boolValue];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:isRunning];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:(isRunning ? 1 : 0)];
    [self setViewEnabled:!isRunning];
    if ([[self navigationItem] leftBarButtonItem]) {
        [[[self navigationItem] leftBarButtonItem] setTitle:(isRunning ? NSLocalizedString(@"Stop", nil) : NSLocalizedString(@"Start", nil))];
        [[[self navigationItem] leftBarButtonItem] setStyle:(isRunning ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered)];
        [[[self navigationItem] leftBarButtonItem] setAction:(isRunning ? @selector(stopProcess) : @selector(startProcess))];
    }
}

- (void)doProcess:(BOOL)start
{
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    [self hideKeyboard];
    [NSThread detachNewThreadSelector:@selector(threadRunProxy:) 
                             toTarget:self 
                           withObject:[NSNumber numberWithBool:start]];
}

- (void)doAfterProcess:(NSNumber *)isRunning
{
    [self setRunningStatus:isRunning];
    [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
}

- (void)fixProxy
{
    [NSThread detachNewThreadSelector:@selector(threadFixProxy) toTarget:self withObject:nil];
}

- (void)startProcess
{
    [self doProcess:YES];
}

- (void)stopProcess
{
    [self doProcess:NO];
}

@end
