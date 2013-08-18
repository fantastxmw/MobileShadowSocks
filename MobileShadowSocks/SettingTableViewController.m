//
//  SettingTableViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "SettingTableViewController.h"
#import "CipherViewController.h"

#define APP_VER @"0.2.4"
#define APP_BUILD @"3"

#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_NOTIFY @"Notify"
#define CELL_BUTTON @"Button"
#define CELL_VIEW @"View"
#define ALERT_TAG_ABOUT 1
#define ALERT_TAG_DEFAULT_PAC 2

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define MAX_TRYTIMES 10
#define UPDATE_CONF "Update-Conf"
#define SET_PROXY_PAC "SetProxy-Pac"
#define SET_PROXY_SOCKS "SetProxy-Socks"
#define SET_PROXY_NONE "SetProxy-None"

#define kgrayBlueColor [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:1.0]
#define kgrayBlueColorDisabled [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:0.439216f]
#define kblackColor [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]
#define kblackColorDisabled [UIColor colorWithRed:0 green:0 blue:0 alpha:0.439216f]

@interface UISwitch (Addtion)
- (void)setAlternateColors:(BOOL)enabled;
@end

@implementation SettingTableViewController

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _isEnabled = NO;
        _isPrefChanged = YES;
        _pacURL = [[NSString alloc] initWithFormat:@"http://127.0.0.1:%d/shadow.pac", PAC_PORT];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            _cellWidth = 560.0f;
        else
            _cellWidth = 180.0f;
        _tagNumber = 1000;
        _tagKey = [[NSMutableDictionary alloc] init];
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
                            NSLocalizedString(@"Cipher", nil),
                            @"CRYPTO_METHOD",
                            @"table",
                            CELL_VIEW, nil],
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
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showAbout)];
    [[self navigationItem] setRightBarButtonItem:aboutButton];
    [[self navigationItem] setTitle:NSLocalizedString(@"ShadowSocks", nil)];
    [aboutButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
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
                                                            message:NSLocalizedString(@"Default PAC file might only be useful for users in China. Confirm to use it?", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil) 
                                                  otherButtonTitles:NSLocalizedString(@"OK",nil), 
                                  nil];
            [alert setTag:ALERT_TAG_DEFAULT_PAC];
            [alert show];
            [alert release];
        }
    } else if ([cellType hasPrefix:CELL_VIEW]) {
        if ([cellKey isEqualToString:@"CRYPTO_METHOD"]) {
            CipherViewController *cipherViewController = [[CipherViewController alloc] initWithStyle:UITableViewStyleGrouped withParentView:self];
            [self.navigationController pushViewController:cipherViewController animated:YES];
            [cipherViewController release];
        }
    }
    [[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"%ld-%ld", (long) [indexPath section], (long) [indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSArray *tableSection = [_tableElements objectAtIndex:[indexPath section]];
    NSArray *tableCell = [tableSection objectAtIndex:[indexPath row]];
    NSString *cellTitle = (NSString *) [tableCell objectAtIndex:0];
    NSString *cellType = (NSString *) [tableCell objectAtIndex:3];
    NSString *cellDefaultValue = (NSString *) [tableCell objectAtIndex:2];
    NSString *cellKey = (NSString *) [tableCell objectAtIndex:1];
    UITableViewCellStyle cellStyle = [cellType hasPrefix:CELL_VIEW] ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:CellIdentifier] autorelease];
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
            [_tagKey setObject:cellKey forKey:[NSNumber numberWithInteger:_tagNumber]];
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
            } else if ([cellKey isEqualToString:@"AUTO_PROXY"]) {
                _autoProxyCellTag = _tagNumber;
            }
            [_tagKey setObject:cellKey forKey:[NSNumber numberWithInteger:_tagNumber]];
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
        else if ([cellType hasPrefix:CELL_VIEW]) {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }
    if ([cellKey isEqualToString:@"CRYPTO_METHOD"]) {
        NSString *currentSetting = [[NSUserDefaults standardUserDefaults] stringForKey:cellKey];
        NSString *labelString = currentSetting ? currentSetting : cellDefaultValue;
        [[cell detailTextLabel] setText:labelString];
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

- (void)setProxySwitcher:(NSNumber *)enabledObject
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
            UISwitch *switcher = (UISwitch *) cell.accessoryView;
            if ([switcher tag] == _enableCellTag) {
                [[NSUserDefaults standardUserDefaults] setBool:[enabledObject boolValue] forKey:@"PROXY_ENABLED"];
                [switcher setOn:[enabledObject boolValue]];
                break;
            }
        }
    }
}

- (void)setBadge:(BOOL)enabled
{
    if (enabled) {
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
    NSString *key = [_tagKey objectForKey:[NSNumber numberWithInteger:[switcher tag]]];
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
    NSString *key = [_tagKey objectForKey:[NSNumber numberWithInteger:[textField tag]]];
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
    [self performSelectorOnMainThread:@selector(setProxySwitcher:) withObject:[NSNumber numberWithBool:_isEnabled] waitUntilDone:NO];
    [self setBadge:_isEnabled];
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
        [self performSelectorOnMainThread:@selector(setProxySwitcher:) withObject:[NSNumber numberWithBool:_isEnabled] waitUntilDone:NO];
    }
    [self setBadge:_isEnabled];
    
    [pool release];
}

- (void)threadChangeProxyStatus:(NSNumber *)isAutoProxy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setProxy:([isAutoProxy boolValue] ? kProxyPac : kProxySocks)];
    [pool release];
}

- (BOOL)threadSendNotifyMessage:(NSNumber *)messageNumber
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_pacURL]];
    const char *messageHeader = UPDATE_CONF;
    int messageId = [messageNumber intValue];
    switch (messageId) {
        case 0:
            messageHeader = UPDATE_CONF;
            break;
        case PROXY_NONE_STATUS:
            messageHeader = SET_PROXY_NONE;
            break;
        case PROXY_SOCKS_STATUS:
            messageHeader = SET_PROXY_SOCKS;
            break;
        case PROXY_PAC_STATUS:
            messageHeader = SET_PROXY_PAC;
            break;
        default:
            messageHeader = SET_PROXY_NONE;
            break;
    }
    [request setValue:@"True" forHTTPHeaderField:[NSString stringWithFormat:@"%s", messageHeader]];
    NSHTTPURLResponse *response;
    BOOL ret = NO;
    int i;
    for (i = 0; i < MAX_TRYTIMES; i++) {
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([str hasPrefix:@"Updated."]) {
            ret = YES;
            [str release];
            break;
        } else if ([str hasPrefix:@"Failed."]) {
            [str release];
            break;
        }
        [str release];
    }
    if (messageId == 0 && ret == YES)
        _isPrefChanged = NO;
    [request release];
    [pool release];
    return ret;
}

#pragma mark - Proxy functions

- (void)fixProxy
{
    [NSThread detachNewThreadSelector:@selector(threadFixProxy) toTarget:self withObject:nil];
}

- (void)setPrefChanged
{
    _isPrefChanged = YES;
}

- (void)notifyChanged
{
    if (_isPrefChanged)
        [NSThread detachNewThreadSelector:@selector(threadSendNotifyMessage:) toTarget:self withObject:[NSNumber numberWithInt:0]];
}

- (void)notifyChangedWhenRunning
{
    if (_isPrefChanged && _isEnabled)
        [NSThread detachNewThreadSelector:@selector(threadSendNotifyMessage:) toTarget:self withObject:[NSNumber numberWithInt:0]];
}

- (BOOL)setProxy:(ProxyStatus)status
{
    int statusId = PROXY_NONE_STATUS;
    switch (status) {
        case kProxySocks:
            statusId = PROXY_SOCKS_STATUS;
            break;
        case kProxyPac:
            statusId = PROXY_PAC_STATUS;
            break;
        default:
            statusId = PROXY_NONE_STATUS;
            break;
    }
    return [self threadSendNotifyMessage:[NSNumber numberWithInt:statusId]];
}

@end
