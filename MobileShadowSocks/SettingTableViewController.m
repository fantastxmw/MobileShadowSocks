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
#define kblackColor [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]
#define kblackColorDisabled [UIColor colorWithRed:0 green:0 blue:0 alpha:0.439216f]

@implementation SettingTableViewController

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        setuid(0);
        seteuid(501);
        _isLaunched = NO;
        _isEnabled = NO;
        _isPrefChanged = NO;
    }
    return self;
}

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
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showAbout)];
    [[self navigationItem] setRightBarButtonItem:aboutButton];
    [[self navigationItem] setTitle:NSLocalizedString(@"ShadowSocks", nil)];
    [aboutButton release];
    _pacURL = [[NSString alloc] initWithFormat:@"http://127.0.0.1:%d/shadow.pac", PAC_PORT];
    _tagNumber = 0;
    _tagKey = [[NSMutableArray alloc] init];
    _tagWillNotifyChange = [[NSMutableArray alloc] init];
    _tableSectionNumber = 3;
    _tableRowNumber = [[NSArray alloc] initWithObjects:
                       [NSNumber numberWithInt:1], 
                       [NSNumber numberWithInt:4], 
                       [NSNumber numberWithInt:4], 
                       nil];
    _tableSectionTitle = [[NSArray alloc] initWithObjects:
                          @"",
                          NSLocalizedString(@"Server Information", nil), 
                          NSLocalizedString(@"Proxy Settings", nil), 
                          nil];
    _tableElements = [[NSArray alloc] initWithObjects:
                      [NSArray arrayWithObjects:
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Enable Proxy", nil), 
                        @"PROXY_ENABLED", 
                        @"NO", 
                        CELL_SWITCH, nil], 
                       nil],
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
                        CELL_SWITCH, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"PAC File", nil), 
                        @"PAC_FILE", 
                        NSLocalizedString(@"Please specify file path", nil), 
                        CELL_TEXT, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Exceptions", nil), 
                        @"EXCEPTION_LIST", 
                        NSLocalizedString(@"Split with comma", nil), 
                        CELL_TEXT, nil], 
                       [NSArray arrayWithObjects:
                        NSLocalizedString(@"Use Default PAC File", nil), 
                        @"DEFAULT_PAC_BUTTON", 
                        @"", 
                        CELL_BUTTON, nil],
                       nil],  
                      nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _isLaunched = YES;
    [NSThread detachNewThreadSelector:@selector(threadFixProxy) toTarget:self withObject:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc
{
    [_pacURL release];
    [_tableRowNumber release];
    [_tableSectionTitle release];
    [_tableElements release];
    [_tagKey release];
    [_tagWillNotifyChange release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableSectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSNumber *) [_tableRowNumber objectAtIndex:section] intValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = [_tableSectionTitle objectAtIndex:section];
    if (title && ![title isEqualToString:@""])
        return title;
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == _tableSectionNumber - 1)
        return [NSString stringWithFormat:@"%@\n© 2013 Linus Yang", NSLocalizedString(@"Localization by Linus Yang", @"Localization Information")];
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tableSection = [_tableElements objectAtIndex:[indexPath section]];
    NSArray *tableCell = [tableSection objectAtIndex:[indexPath row]];
    NSString *cellKey = (NSString *) [tableCell objectAtIndex:1];
    NSString *cellType = (NSString *) [tableCell objectAtIndex:3];
    if ([cellType hasPrefix:CELL_BUTTON]) {
        if ([cellKey isEqualToString:@"DEFAULT_PAC_BUTTON"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) 
                                                            message:NSLocalizedString(@"Default PAC file is based on ChnRoutes and might only be useful for users in China. Confirm to use it?", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil) 
                                                  otherButtonTitles:NSLocalizedString(@"OK",nil), 
                                  nil];
            [alert setTag:ALERT_TAG_DEFAULT_PAC];
            [alert show];
            [alert release];
        }
    }
    [[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
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
        [[cell textLabel] setTextColor:kblackColor];
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
                if (!isEnabled) {
                    [textField setTextColor:kgrayBlueColorDisabled];
                    [[cell textLabel] setTextColor:kblackColorDisabled];
                }
                [cell setUserInteractionEnabled:isEnabled];
            }
            [_tagKey addObject:cellKey];
            if ([indexPath section] == 1)
                [_tagWillNotifyChange addObject:[NSNumber numberWithInt:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:textField];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [textField release];
        }
        else if ([cellType hasPrefix:CELL_SWITCH]) {
            BOOL switchValue = [[NSUserDefaults standardUserDefaults] boolForKey:cellKey];
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switcher setOn:switchValue animated:NO];
            [switcher addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            [switcher setTag:_tagNumber];
            if ([cellKey isEqualToString:@"PROXY_ENABLED"]) {
                _enableCellTag = _tagNumber;
                _isEnabled = switchValue;
                if ([switcher respondsToSelector:@selector(setAlternateColors:)])
                    [switcher setAlternateColors:YES];
            }
            if ([cellKey isEqualToString:@"AUTO_PROXY"])
                _autoProxyCellTag = _tagNumber;
            [_tagKey addObject:cellKey];
            if ([indexPath section] == 1)
                [_tagWillNotifyChange addObject:[NSNumber numberWithInt:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:switcher];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [switcher release];
        }
        else if ([cellType hasPrefix:CELL_BUTTON]) {
            [[cell textLabel] setTextAlignment:UITextAlignmentCenter];
        }
    }
    return cell;
}

#pragma mark - Alert views

- (void)showAbout
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:@"Version " APP_VER @" (Rev " APP_BUILD @")\nTwitter: @linusyang\nhttp://linusyang.com/\n\nShadowSocks is created by @clowwindy" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:NSLocalizedString(@"Help Page",nil), nil];
    [alert setTag:ALERT_TAG_ABOUT];
    [alert show];
    [alert release];
}

- (void)showError:(NSString *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:error ? error : NSLocalizedString(@"Operation failed.\nPlease try again later.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)showFileNotFound
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"PAC file not found. Redirect all traffic to proxy.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        if ([alertView tag] == ALERT_TAG_ABOUT)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/linusyang/MobileShadowSocks#mobileshadowsocks"]];
        else if ([alertView tag] == ALERT_TAG_DEFAULT_PAC) {
            for (UITableViewCell *cell in self.tableView.visibleCells) {
                if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
                    UITextField *textField = (UITextField *) cell.accessoryView;
                    if ([textField tag] == _pacFileCellTag) {
                        NSString *pacFile = [NSString stringWithFormat:@"%@/auto.pac", [[NSBundle mainBundle] bundlePath]];
                        [textField setText:pacFile];
                        [[NSUserDefaults standardUserDefaults] setObject:pacFile forKey:@"PAC_FILE"];
                        break;
                    }
                }
            }
        }
    }
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
                [[cell textLabel] setTextColor:isEnabled ? kblackColor : kblackColorDisabled];
                [cell setUserInteractionEnabled:isEnabled];
                break;
            }
        }
    }
}

- (void)setProxySwitcher
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
            UISwitch *switcher = (UISwitch *) cell.accessoryView;
            if ([switcher tag] == _enableCellTag) {
                [[NSUserDefaults standardUserDefaults] setBool:_isEnabled forKey:@"PROXY_ENABLED"];
                [switcher setOn:_isEnabled];
                break;
            }
        }
    }
}

- (void)setBadge
{
    if (_isEnabled) {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(setApplicationBadgeString:)])
            [[UIApplication sharedApplication] setApplicationBadgeString:NSLocalizedString(@"On", nil)];
        else
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    }
    else
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)switchChanged:(id)sender
{
    UISwitch* switcher = sender;
    if ([switcher tag] == _enableCellTag) {
        [NSThread detachNewThreadSelector:@selector(threadRunProxy:) 
                                 toTarget:self 
                               withObject:[NSNumber numberWithBool:switcher.on]];
        return;
    }
    NSString *key = [_tagKey objectAtIndex:[switcher tag]];
    [[NSUserDefaults standardUserDefaults] setBool:switcher.on forKey:key];
    if ([switcher tag] == _autoProxyCellTag) {
        [self setPacFileCellEnabled:switcher.on];
        if (_isEnabled) {
            [NSThread detachNewThreadSelector:@selector(threadChangeProxyStatus:) 
                                     toTarget:self 
                                   withObject:[NSNumber numberWithBool:switcher.on]];
        }
    }
    if ([_tagWillNotifyChange indexOfObject:[NSNumber numberWithInt:[switcher tag]]] != NSNotFound)
        _isPrefChanged = YES;
}

#pragma mark - Text field delegate

- (void)hideKeyboard
{
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
    NSString *key = (NSString *) [_tagKey objectAtIndex:[textField tag]];
    [[NSUserDefaults standardUserDefaults] setObject:[textField text] forKey:key];
    if ([_tagWillNotifyChange indexOfObject:[NSNumber numberWithInt:[textField tag]]] != NSNotFound)
        _isPrefChanged = YES;
}

#pragma mark - Proxy threads

- (void)threadRunProxy:(NSNumber *)willStart
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL start = [willStart boolValue];
    ProxyStatus status = kProxyNone;
    if (start) {
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self notifyChanged];
        NSString *pacFile = [[[NSUserDefaults standardUserDefaults] stringForKey:@"PAC_FILE"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        BOOL isAuto = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTO_PROXY"];
        if (isAuto) {
            status = kProxyPac;
            if (!pacFile || ![[NSFileManager defaultManager] fileExistsAtPath:pacFile])
                [self performSelectorOnMainThread:@selector(showFileNotFound) withObject:nil waitUntilDone:YES];
        }
        else
            status = kProxySocks;
    }
    if ([self setProxy:status])
        _isEnabled = start;
    else {
        _isEnabled = !start;
        [self performSelectorOnMainThread:@selector(showError:) withObject:NSLocalizedString(@"Failed to change proxy settings.\nMaybe no network access available.", nil) waitUntilDone:NO];
    }
    [self performSelectorOnMainThread:@selector(setProxySwitcher) withObject:nil waitUntilDone:NO];
    [self setBadge];
    [pool release];
}

- (void)threadFixProxy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CFDictionaryRef proxyDict = CFNetworkCopySystemProxySettings();
    BOOL pacEnabled = [[(NSDictionary *) proxyDict objectForKey:@"ProxyAutoConfigEnable"] boolValue];
    BOOL socksEnabled = [[(NSDictionary *) proxyDict objectForKey:@"SOCKSEnable"] boolValue];
    BOOL isEnabled = (socksEnabled || pacEnabled) ? YES : NO;
    CFRelease(proxyDict);
    ProxyStatus nowStatus = kProxyNone;
    if (isEnabled)
        nowStatus = pacEnabled ? kProxyPac : kProxySocks;
    
    BOOL prefEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"PROXY_ENABLED"];
    BOOL prefAuto = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTO_PROXY"];
    ProxyStatus prefStatus = kProxyNone;
    if (prefEnabled)
        prefStatus = prefAuto ? kProxyPac : kProxySocks;
    
    _isEnabled = prefEnabled;
    if (nowStatus != prefStatus) {
        if (![self setProxy:prefStatus])
            _isEnabled = isEnabled;
        [self performSelectorOnMainThread:@selector(setProxySwitcher) withObject:nil waitUntilDone:NO];
    }
    [self setBadge];
    
    [pool release];
}

- (void)threadChangeProxyStatus:(NSNumber *)isAutoProxy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setProxy:([isAutoProxy boolValue] ? kProxyPac : kProxySocks)];
    [pool release];
}

- (void)threadNotifyChanged
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_pacURL]];
    [request setValue:@"True" forHTTPHeaderField:[NSString stringWithFormat:@"%s", UPDATE_CONF]];
    NSHTTPURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    _isPrefChanged = NO;
    [request release];
    [pool release];
}

#pragma mark - Proxy functions

- (void)fixProxy
{
    if (_isLaunched)
        [NSThread detachNewThreadSelector:@selector(threadFixProxy) toTarget:self withObject:nil];
}

- (void)notifyChanged
{
    if (_isPrefChanged)
        [NSThread detachNewThreadSelector:@selector(threadNotifyChanged) toTarget:self withObject:nil];
}

- (BOOL)setProxy:(ProxyStatus)status
{
    BOOL isEnabled;
    BOOL socks;
    BOOL ret;
    isEnabled = socks = NO;
    switch (status) {
        case kProxyPac:
            isEnabled = YES;
            break;
        case kProxySocks:
            isEnabled = socks = YES;
            break;
        default:
            break;
    }
    ret = NO;
    NSString *excepts = [NSString stringWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"EXCEPTION_LIST"]];
    seteuid(0);
    SCDynamicStoreRef store = SCDynamicStoreCreate(0, STORE_ID, 0, 0);
    CFArrayRef list = SCDynamicStoreCopyKeyList(store, SC_IDENTI);
    NSMutableSet *set = [NSMutableSet set];
    int i, j, len;
    for (NSString *state in (NSArray *) list) {
        const char *s = [state cStringUsingEncoding:NSUTF8StringEncoding];
        len = (int) ([state length] - 35);
        for (i = 0; i < len; i++) {
            for (j = i; j - i < 36; j++) {
                if (j - i ==  8 || j - i == 13 || 
                    j - i == 18 || j - i == 23) {
                    if (s[j] != '-')
                        break;
                }
                else if (!((s[j] >= 'A' && s[j] <= 'Z') ||
                           (s[j] >= '0' && s[j] <= '9')))
                    break;
            }
            if (j - i == 36)
                [set addObject:[state substringWithRange:NSMakeRange(i, 36)]];
        }
    }
    NSArray *interfaces = [set allObjects];
    SCPreferencesRef pref = SCPreferencesCreate(0, STORE_ID, 0);
    if ([interfaces count] > 0) {
        NSMutableArray *exceptArray = [NSMutableArray array];
        NSArray *origArray = [excepts componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        for (NSString *s in origArray)
            if (![s isEqualToString:@""])
                [exceptArray addObject:s];
        NSMutableDictionary *proxySet = [NSMutableDictionary dictionary];
        if (isEnabled) {
            if ([exceptArray count] > 0)
                [proxySet setObject:exceptArray forKey:@"ExceptionsList"];
            if (socks) {
                [proxySet setObject:[NSNumber numberWithInt:1] forKey:@"SOCKSEnable"];
                [proxySet setObject:@"127.0.0.1" forKey:@"SOCKSProxy"];
                [proxySet setObject:[NSNumber numberWithInt:LOCAL_PORT] forKey:@"SOCKSPort"];
            }
            else {
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
                [proxySet setObject:[NSNumber numberWithInt:2] forKey:@"HTTPProxyType"];
                [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
                [proxySet setObject:[NSNumber numberWithInt:1] forKey:@"ProxyAutoConfigEnable"];
                [proxySet setObject:_pacURL forKey:@"ProxyAutoConfigURLString"];
            }
        }
        else {
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPEnable"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPProxyType"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"HTTPSEnable"];
            [proxySet setObject:[NSNumber numberWithInt:0] forKey:@"ProxyAutoConfigEnable"];
        }
        ret = YES;
        for (NSString *networkid in interfaces)
            ret &= SCPreferencesPathSetValue(pref, (CFStringRef) [NSString stringWithFormat:@"/NetworkServices/%@/Proxies", networkid], (CFDictionaryRef) proxySet);
        ret &= SCPreferencesCommitChanges(pref);
        ret &= SCPreferencesApplyChanges(pref);
        SCPreferencesSynchronize(pref);
    }
    CFRelease(pref);
    CFRelease(list);
    CFRelease(store);
    seteuid(501);
    return ret;
}

@end
