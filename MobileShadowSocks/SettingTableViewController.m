//
//  SettingTableViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-1-31.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import "SettingTableViewController.h"
#import "CipherViewController.h"
#import "ProfileViewController.h"
#import "CodeGeneratorViewController.h"
#import "NSString+Base64.h"

#define APP_VER @"0.3"
#define APP_BUILD @"4"

#define kURLPrefix @"ss://"

#define CELL_INDEX_TITLE 0
#define CELL_INDEX_KEY 1
#define CELL_INDEX_DEFAULT 2
#define CELL_INDEX_TYPE 3
#define CELL_INDEX_NUM 4
#define CELL_TEXT @"TextField"
#define CELL_PASS @"Pass"
#define CELL_NUM @"Num"
#define CELL_SWITCH @"Switch"
#define CELL_NOTIFY @"Notify"
#define CELL_BUTTON @"Button"
#define CELL_VIEW @"View"
#define ALERT_TAG_ABOUT 1
#define ALERT_TAG_DEFAULT_PAC 2
#define ALERT_TAG_NEW_PROFILE 3
#define ALERT_TAG_REPAIR 4
#define ALERT_TAG_SCANERROR 5

typedef enum {
    kActionSheetQRCode = 0,
    
    kActionSheetCount
} ActionSheetTag;

typedef enum {
    QRCodeActionCamera = 0,
    QRCodeActionLibrary,
    QRCodeActionShare
} QRCodeAction;

#define LOCAL_PORT 1983
#define PAC_PORT 1993
#define MAX_TRYTIMES 10
#define LOCAL_TIMEOUT 60
#define UPDATE_CONF "Update-Conf"
#define FORCE_STOP "Force-Stop"
#define SET_PROXY_PAC "SetProxy-Pac"
#define SET_PROXY_SOCKS "SetProxy-Socks"
#define SET_PROXY_NONE "SetProxy-None"

#define PROXY_FORCE_STOP 4
#define PROXY_PAC_STATUS 3
#define PROXY_SOCKS_STATUS 2
#define PROXY_NONE_STATUS 1
#define PROXY_UPDATE_CONF 0

typedef enum {
    kProxyPac,
    kProxySocks,
    kProxyNone
} ProxyStatus;

#define JSON_CONFIG_NAME @"com.linusyang.shadowsocks.json"
#define PAC_DEFAULT_NAME @"auto.pac"
#define RESPONSE_SUCC @"Updated."
#define RESPONSE_FAIL @"Failed."

#define GLOBAL_PROFILE_NOW_KEY @"SELECTED_PROFILE"
#define GLOBAL_PROFILE_LIST_KEY @"PROFILE_LIST"
#define GLOBAL_PROXY_ENABLE_KEY @"PROXY_ENABLED"

#define PROFILE_DEFAULT_NAME NSLocalizedString(@"Default", nil)
#define PROFILE_DEFAULT_INDEX -1
#define PROFILE_NAME_KEY @"PROFILE_NAME"

#define kgrayBlueColor [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:1.0]
#define kgrayBlueColorDisabled [UIColor colorWithRed:0.318 green:0.4 blue:0.569 alpha:0.439216f]
#define kblackColor [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]
#define kblackColorDisabled [UIColor colorWithRed:0 green:0 blue:0 alpha:0.439216f]

@interface UISwitch (Addition)
- (void)setAlternateColors:(BOOL)enabled;
@end

@interface UIApplication (Addition)
- (void)setApplicationBadgeString:(NSString *)badgeString;
@end

@interface UIAlertView (Addition)
- (void)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;
@end

@interface SettingTableViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, retain) UIPopoverController *popController;
@property (nonatomic, assign) BOOL isPoped;

@end

@implementation SettingTableViewController

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _isPrefChanged = YES;
        _legacySystem = SYSTEM_VERSION_LESS_THAN(@"5.0");
        
        _pacURL = [[NSString alloc] initWithFormat:@"http://127.0.0.1:%d/proxy.pac", PAC_PORT];
        _pacDefaultFile = [[NSString alloc] initWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], PAC_DEFAULT_NAME];
        
        NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
        NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
        _configPath = [[NSString alloc] initWithFormat:@"%@/%@", prefsDirectory, JSON_CONFIG_NAME];
        
        _currentProfile = PROFILE_DEFAULT_INDEX;
        [self reloadProfile];
        
        _alertViewUserInfo = [[NSMutableDictionary alloc] init];
       
        if (DEVICE_IS_IPAD())
            _cellWidth = 560.0f;
        else
            _cellWidth = 180.0f;
        
        _tagNumber = 1000;
        _tagKey = [[NSMutableDictionary alloc] init];
        _tableSectionTitle = [[NSArray alloc] initWithObjects:
                              NSLocalizedString(@"General", nil),
                              NSLocalizedString(@"Server Information", nil),
                              NSLocalizedString(@"Proxy Settings", nil),
                              nil];
        _tableElements = [[NSArray alloc] initWithObjects:
                          [NSArray arrayWithObjects:
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Enable Proxy", nil),
                            GLOBAL_PROXY_ENABLE_KEY,
                            @"NO",
                            CELL_SWITCH, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Profile", nil),
                            GLOBAL_PROFILE_NOW_KEY,
                            PROFILE_DEFAULT_NAME,
                            CELL_VIEW, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Create New Profile", nil),
                            @"NEW_PROFILE_BUTTON",
                            @"",
                            CELL_BUTTON, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"QR Code", nil),
                            @"QRCODE_BUTTON",
                            @"",
                            CELL_BUTTON, nil],
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
    UIBarButtonItem *repairButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Repair", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(repairDaemon)];
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(showAbout)];
    [[self navigationItem] setLeftBarButtonItem:repairButton];
    [[self navigationItem] setRightBarButtonItem:aboutButton];
    [[self navigationItem] setTitle:NSLocalizedString(@"ShadowSocks", nil)];
    [repairButton release];
    [aboutButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadProfile];
    [[self tableView] reloadData];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (DEVICE_IS_IPAD()) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)dealloc
{
    [_pacURL release];
    [_configPath release];
    [_tableSectionTitle release];
    [_tableElements release];
    [_tagKey release];
    [_pacDefaultFile release];
    [_alertViewUserInfo release];
    [_popController release];
    _popController = nil;
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_tableElements count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *) [_tableElements objectAtIndex:section] count];
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
    if (section == [_tableElements count] - 1)
        return [NSString stringWithFormat:@"%@\n© 2013-2014 Linus Yang", NSLocalizedString(@"Localization by Linus Yang", @"Localization Information")];
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
        } else if ([cellKey isEqualToString:@"NEW_PROFILE_BUTTON"]) {
            [self showNewProfile:nil withMessage:nil];
        } else if ([cellKey isEqualToString:@"QRCODE_BUTTON"]) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Import or Share Profiles by QR Code",nil)
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:
                                          NSLocalizedString(@"From Camera",nil),
                                          NSLocalizedString(@"From Photo Library",nil),
                                          NSLocalizedString(@"Share",nil),
                                          nil];
            [actionSheet setTag:kActionSheetQRCode];
            [actionSheet showInView:self.view];
            [actionSheet release];
        }
    } else if ([cellType hasPrefix:CELL_VIEW]) {
        if ([cellKey isEqualToString:@"CRYPTO_METHOD"]) {
            CipherViewController *cipherViewController = [[CipherViewController alloc] initWithStyle:UITableViewStyleGrouped withParentView:self];
            [self.navigationController pushViewController:cipherViewController animated:YES];
            [cipherViewController release];
        } else if ([cellKey isEqualToString:GLOBAL_PROFILE_NOW_KEY]) {
            ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithStyle:UITableViewStyleGrouped withParentView:self];
            [self.navigationController pushViewController:profileViewController animated:YES];
            [profileViewController release];
        }
    }
    [[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tableSection = [_tableElements objectAtIndex:[indexPath section]];
    NSArray *tableCell = [tableSection objectAtIndex:[indexPath row]];
    if ([tableCell count] < CELL_INDEX_NUM) {
        return [[[UITableViewCell alloc] init] autorelease];
    }
    
    NSString *cellTitle = (NSString *) [tableCell objectAtIndex:CELL_INDEX_TITLE];
    NSString *cellType = (NSString *) [tableCell objectAtIndex:CELL_INDEX_TYPE];
    NSString *cellDefaultValue = (NSString *) [tableCell objectAtIndex:CELL_INDEX_DEFAULT];
    NSString *cellKey = (NSString *) [tableCell objectAtIndex:CELL_INDEX_KEY];
    NSString *cellIdentifier = [NSString stringWithFormat:@"SettingTableCellIdentifier-%d-%d", (int) [indexPath section], (int) [indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        UITableViewCellStyle cellStyle = [cellType hasPrefix:CELL_VIEW] ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
        [[cell textLabel] setText:cellTitle];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
        [[cell textLabel] setTextColor:kblackColor];
        if ([cellType hasPrefix:CELL_TEXT]) {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, _cellWidth, 24)];
            [textField setTextColor:kgrayBlueColor];
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
            }
            [_tagKey setObject:cellKey forKey:[NSNumber numberWithInteger:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:textField];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [textField release];
        }
        else if ([cellType hasPrefix:CELL_SWITCH]) {
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switcher addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            [switcher setTag:_tagNumber];
            if ([cellKey isEqualToString:GLOBAL_PROXY_ENABLE_KEY]) {
                _enableCellTag = _tagNumber;
                if ([switcher respondsToSelector:@selector(setAlternateColors:)])
                    [switcher setAlternateColors:YES];
            } else if ([cellKey isEqualToString:@"AUTO_PROXY"]) {
                _autoProxyCellTag = _tagNumber;
            }
            [_tagKey setObject:cellKey forKey:[NSNumber numberWithInteger:_tagNumber]];
            _tagNumber++;
            [cell setAccessoryView:switcher];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [switcher release];
        }
        else if ([cellType hasPrefix:CELL_BUTTON]) {
#ifdef __IPHONE_6_0
            [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
#else
            [[cell textLabel] setTextAlignment:UITextAlignmentCenter];
#endif
        }
        else if ([cellType hasPrefix:CELL_VIEW]) {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }
    
    if ([cellType hasPrefix:CELL_TEXT]) {
        UITextField *textField = (UITextField *) [cell accessoryView];
        NSString *currentSetting = [self readObject:cellKey];
        [textField setText:currentSetting ? currentSetting : @""];
        if ([cellKey isEqualToString:@"PAC_FILE"]) {
            BOOL isEnabled = [self readBool:@"AUTO_PROXY"];
            [textField setEnabled:isEnabled];
            [textField setTextColor:isEnabled ? kgrayBlueColor : kgrayBlueColorDisabled];
            [[cell textLabel] setTextColor:isEnabled ? kblackColor : kblackColorDisabled];
            [cell setUserInteractionEnabled:isEnabled];
        }
    } else if ([cellType hasPrefix:CELL_SWITCH]) {
        UISwitch *switcher = (UISwitch *) [cell accessoryView];
        BOOL switchValue = [self readBool:cellKey];
        [switcher setOn:switchValue animated:NO];
    } else if ([cellType hasPrefix:CELL_VIEW]) {
        NSString *currentSetting = nil;
        if ([cellKey isEqualToString:GLOBAL_PROFILE_NOW_KEY]) {
            currentSetting = [self nameOfProfile:_currentProfile];
        } else {
            currentSetting = [self readObject:cellKey];
        }
        NSString *labelString = currentSetting ? currentSetting : cellDefaultValue;
        [[cell detailTextLabel] setText:labelString];
    }
    
    return cell;
}

#pragma mark - Alert views

- (void)showAbout
{
    NSString *aboutMessage = [NSString stringWithFormat:@"%@ %@ (%@ %@)\n%@: @linusyang\nhttp://linusyang.com/\n\n%@",
                              NSLocalizedString(@"Version", nil), APP_VER, NSLocalizedString(@"Rev", nil), APP_BUILD,
                              NSLocalizedString(@"Twitter", nil), NSLocalizedString(@"ShadowSocks is created by @clowwindy", nil)];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:aboutMessage delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:NSLocalizedString(@"Help Page",nil), nil];
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

- (void)checkFileNotFound
{
    NSString *pacFile = [[self readObject:@"PAC_FILE"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([pacFile length] == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:pacFile]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"PAC file not found. Redirect all traffic to proxy.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
}

- (void)repairDaemon
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Repair Service", nil)
                                                    message:NSLocalizedString(@"Warning: Reparing service will drop all proxy connections. This is only needed when you cannot enable the proxy. Are you sure to continue?", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"Repair",nil), nil];
    [alert setTag:ALERT_TAG_REPAIR];
    [alert show];
    [alert release];
}

- (void)showNewProfile:(NSDictionary *)profileInfo withMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Profile", nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"OK",nil),
                          nil];
    UITextField *textField = [self textFieldInAlertView:alert isInit:YES];
    [textField setPlaceholder:NSLocalizedString(@"Name", nil)];
    [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [alert setTag:ALERT_TAG_NEW_PROFILE];
    if (profileInfo) {
        [_alertViewUserInfo setObject:profileInfo forKey:[NSNumber numberWithInteger:ALERT_TAG_NEW_PROFILE]];
        NSString *presetName = [NSString stringWithFormat:@"SS-%@", [profileInfo objectForKey:@"REMOTE_SERVER"]];
        [textField setText:presetName];
    } else {
        [_alertViewUserInfo removeObjectForKey:[NSNumber numberWithInteger:ALERT_TAG_NEW_PROFILE]];
    }
    [alert show];
    [alert release];
}

- (void)showQRCodeError:(NSString *)rawLink
{
    [self showQRCodeError:rawLink baseHint:NSLocalizedString(@"Cannot parse URL link", nil)];
}

- (void)showQRCodeError:(NSString *)rawLink baseHint:(NSString *)baseHint
{
    NSString *message;
    if (rawLink) {
        message = [NSString stringWithFormat:@"%@:\n%@", baseHint, rawLink];
    } else {
        message = [baseHint stringByAppendingString:@"."];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"QR Code Error", nil)
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"Open Link",nil), nil];
    [alert setTag:ALERT_TAG_SCANERROR];
    if (rawLink) {
        [_alertViewUserInfo setObject:rawLink forKey:[NSNumber numberWithInteger:ALERT_TAG_SCANERROR]];
    } else {
        [_alertViewUserInfo removeObjectForKey:[NSNumber numberWithInteger:ALERT_TAG_SCANERROR]];
    }
    [alert show];
    [alert release];
}

- (UITextField *)textFieldInAlertView:(UIAlertView *)alertView isInit:(BOOL)isInit
{
    UITextField *textField = nil;
    if (_legacySystem) {
        if (isInit) {
            if ([alertView respondsToSelector:@selector(addTextFieldWithValue:label:)]) {
                [alertView addTextFieldWithValue:@"" label:@""];
            }
        }
        if ([alertView respondsToSelector:@selector(textFieldAtIndex:)]) {
            textField = [alertView textFieldAtIndex:0];
        }
    } else {
        if (isInit) {
            [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        }
        textField = [alertView textFieldAtIndex:0];
    }
    return textField;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        if ([alertView tag] == ALERT_TAG_ABOUT)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/linusyang/MobileShadowSocks/blob/master/README.md"]];
        else if ([alertView tag] == ALERT_TAG_DEFAULT_PAC) {
            for (UITableViewCell *cell in self.tableView.visibleCells) {
                if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
                    UITextField *textField = (UITextField *) cell.accessoryView;
                    if ([textField tag] == _pacFileCellTag) {
                        [textField setText:_pacDefaultFile];
                        [self saveObject:_pacDefaultFile forKey:@"PAC_FILE"];
                        [self setPrefChanged];
                        break;
                    }
                }
            }
        } else if ([alertView tag] == ALERT_TAG_NEW_PROFILE) {
            UITextField *textField = [self textFieldInAlertView:alertView isInit:NO];
            NSDictionary *userInfo = [_alertViewUserInfo objectForKey:[NSNumber numberWithInteger:ALERT_TAG_NEW_PROFILE]];
            [self createProfile:[textField text] withInfo:userInfo];
        } else if ([alertView tag] == ALERT_TAG_REPAIR) {
            [NSThread detachNewThreadSelector:@selector(threadSendNotifyMessage:) toTarget:self withObject:[NSNumber numberWithInt:PROXY_FORCE_STOP]];
        } else if ([alertView tag] == ALERT_TAG_SCANERROR) {
            NSString *rawLink = [_alertViewUserInfo objectForKey:[NSNumber numberWithInteger:ALERT_TAG_SCANERROR]];
            if (rawLink) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rawLink]];
            }
        }
    }
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (DEVICE_IS_IPAD()) {
        [self.popController dismissPopoverAnimated:YES];
        self.isPoped = NO;
    } else {
        [picker dismissModalViewControllerAnimated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [CodeScannerViewController scanImage:image completion:^(BOOL success, NSString *resultText) {
        if (success) {
            [self scannerDidGetResult:resultText willDismiss:NO];
        } else {
            [self showQRCodeError:nil];
        }
    }];
    [self imagePickerControllerDidCancel:picker];
}

#pragma mark - UIPopoverController Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popController = nil;
    self.isPoped = NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (DEVICE_IS_IPAD() && self.isPoped) {
        [self showPopController];
    }
}

- (void)showPopController
{
    CGRect popFrame;
    popFrame.origin.x = CGRectGetWidth(self.view.frame) / 2.0f;
    popFrame.origin.y = CGRectGetHeight(self.view.frame) / 2.0f - 50.0f;
    popFrame.size.width = 1.0f;
    popFrame.size.height = 1.0f;
    [self.popController presentPopoverFromRect:popFrame inView:self.view permittedArrowDirections:0 animated:YES];
    self.isPoped = YES;
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    QRCodeAction action = (QRCodeAction) buttonIndex;
    switch (action) {
        case QRCodeActionCamera: {
            CodeScannerViewController *scannerViewController = [[CodeScannerViewController alloc] init];
            scannerViewController.delegate = self;
            [self.navigationController pushViewController:scannerViewController animated:YES];
            [scannerViewController release];
            break;
        }
            
        case QRCodeActionLibrary: {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
                pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                pickerController.delegate = self;
                if (DEVICE_IS_IPAD()) {
                    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:pickerController];
                    popController.delegate = self;
                    self.popController = popController;
                    [popController release];
                    [self showPopController];
                } else {
                    [self presentModalViewController:pickerController animated:YES];
                }
                [pickerController release];
            } else {
                [self showError:NSLocalizedString(@"Photo library is not available.", nil)];
            }
            break;
        }
            
        case QRCodeActionShare: {
            NSString *remoteServer = [self fetchConfigForKey:@"REMOTE_SERVER" andDefault:@"127.0.0.1"];
            NSString *remotePort = [self fetchConfigForKey:@"REMOTE_PORT" andDefault:@"8080"];
            NSString *socksPass = [self fetchConfigForKey:@"SOCKS_PASS" andDefault:@"123456"];
            NSString *cryptoMethod = [self fetchConfigForKey:@"CRYPTO_METHOD" andDefault:[CipherViewController defaultCipher]];
            NSString *rawLink = [NSString stringWithFormat:@"%@:%@@%@:%@", cryptoMethod, socksPass, remoteServer, remotePort];
            NSString *encodedLink = [NSString stringWithFormat:@"%@%@", kURLPrefix, [rawLink base64EncodedString]];
            CodeGeneratorViewController *genViewController = [[CodeGeneratorViewController alloc] initWithQRCodeLink:encodedLink];
            [self.navigationController pushViewController:genViewController animated:YES];
            [genViewController release];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Scanner Delegate

- (void)scannerDidGetResult:(NSString *)resultText willDismiss:(BOOL)dismiss
{
    if (dismiss) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    do {
        if (![resultText hasPrefix:kURLPrefix]) {
            break;
        }
        NSString *decodedLink = [[resultText substringFromIndex:[kURLPrefix length]] base64DecodedString];
        if (decodedLink == nil || [decodedLink length] == 0) {
            decodedLink = [resultText substringFromIndex:[kURLPrefix length]];
        }
        resultText = [kURLPrefix stringByAppendingString:decodedLink];
        
        NSRange firstColon = [decodedLink rangeOfString:@":"];
        NSRange lastColon = [decodedLink rangeOfString:@":" options:NSBackwardsSearch];
        NSRange separator = [decodedLink rangeOfString:@"@" options:NSBackwardsSearch];
        if (firstColon.location == NSNotFound ||
            lastColon.location == NSNotFound ||
            separator.location == NSNotFound ||
            lastColon.location == [decodedLink length] - 1) {
            break;
        }
        
        NSString *linkMethod = [[decodedLink substringToIndex:firstColon.location] lowercaseString];
        NSString *linkPort = [decodedLink substringFromIndex:lastColon.location + 1];
        NSString *linkPassword = [decodedLink substringWithRange:NSMakeRange(firstColon.location + 1, separator.location - firstColon.location - 1)];
        NSString *linkAddress = [decodedLink substringWithRange:NSMakeRange(separator.location + 1, lastColon.location - separator.location - 1)];
        if (linkMethod == nil || linkPort == nil || linkPassword == nil || linkAddress == nil) {
            break;
        }
        
        if (![CipherViewController cipherIsValid:linkMethod]) {
            NSString *message = [NSString stringWithFormat:@"%@ \"%@\" %@",
                                 NSLocalizedString(@"Cipher", nil),
                                 linkMethod,
                                 NSLocalizedString(@"is not supported", nil)];
            [self showQRCodeError:resultText baseHint:message];
            return;
        }
        
        NSDictionary *linkInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  linkAddress, @"REMOTE_SERVER",
                                  linkPort, @"REMOTE_PORT",
                                  linkPassword, @"SOCKS_PASS",
                                  linkMethod, @"CRYPTO_METHOD",
                                  nil];
        NSString *linkTitle = [NSString stringWithFormat:@"%@: %@:%@\n%@: %@\n %@: %@",
                               NSLocalizedString(@"Server", nil), linkAddress, linkPort,
                               NSLocalizedString(@"Password", nil), linkPassword,
                               NSLocalizedString(@"Cipher", nil), linkMethod];
        [self showNewProfile:linkInfo withMessage:linkTitle];
        return;
    } while (0);
    
    [self showQRCodeError:resultText];
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
                [switcher setOn:[enabledObject boolValue]];
                break;
            }
        }
    }
}

- (void)setBadge:(NSNumber *)enabledObject
{
    if ([enabledObject boolValue]) {
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
    [self saveBool:switcher.on forKey:key];
    if ([switcher tag] == _autoProxyCellTag) {
        [self setPacFileCellEnabled:switcher.on];
        if ([self proxyEnabled]) {
            if (switcher.on) {
                [self checkFileNotFound];
            }
            [NSThread detachNewThreadSelector:@selector(threadChangeProxyStatus:) 
                                     toTarget:self 
                                   withObject:[NSNumber numberWithBool:switcher.on]];
        }
    }
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
    [self saveObject:[textField text] forKey:key];
    [self setPrefChanged];
}

#pragma mark - Proxy threads

- (void)threadRunProxy:(NSNumber *)willStart
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL willStartProxy = [willStart boolValue];
    ProxyStatus status = kProxyNone;
    if (willStartProxy) {
        BOOL isAuto = [self readBool:@"AUTO_PROXY"];
        if (isAuto) {
            status = kProxyPac;
            [self performSelectorOnMainThread:@selector(checkFileNotFound) withObject:nil waitUntilDone:NO];
        } else {
            status = kProxySocks;
        }
    }
    if ([self setProxy:status]) {
        if (willStartProxy) {
            [self notifyChanged:YES];
        }
    } else {
        willStartProxy = !willStartProxy;
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:_configPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:_configPath error:&error];
        }
        [self performSelectorOnMainThread:@selector(showError:) withObject:NSLocalizedString(@"Failed to change proxy settings.\nMaybe no network access available.", nil) waitUntilDone:NO];
    }
    [self setProxyEnabled:willStartProxy];
    [pool release];
}

- (void)threadFixProxy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ProxyStatus nowStatus = [self currentProxyStatus];
    BOOL nowEnabled = (nowStatus != kProxyNone) ? YES : NO;
    BOOL prefEnabled = [self readBool:GLOBAL_PROXY_ENABLE_KEY];
    BOOL prefAuto = [self readBool:@"AUTO_PROXY"];
    ProxyStatus prefStatus = kProxyNone;
    if (prefEnabled)
        prefStatus = prefAuto ? kProxyPac : kProxySocks;
    
    BOOL proxyEnabled = prefEnabled;
    if (nowStatus != prefStatus) {
        if ([self setProxy:prefStatus] == NO) {
            proxyEnabled = nowEnabled;
        }
    }
    [self setProxyEnabled:proxyEnabled];
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
    const char *messageHeader = UPDATE_CONF;
    int messageId = [messageNumber intValue];
    switch (messageId) {
        case PROXY_UPDATE_CONF:
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
        case PROXY_FORCE_STOP:
            messageHeader = FORCE_STOP;
            break;
        default:
            messageHeader = SET_PROXY_NONE;
            break;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_configPath] || messageId == PROXY_FORCE_STOP) {
        [self syncSettings];
    }
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_pacURL]];
    [request setValue:@"True" forHTTPHeaderField:[NSString stringWithFormat:@"%s", messageHeader]];
    [request setTimeoutInterval:5.0];
    BOOL ret = NO;
    int i;
    for (i = 0; i < MAX_TRYTIMES; i++) {
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        if (data == nil) {
            continue;
        }
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([str hasPrefix:RESPONSE_SUCC]) {
            ret = YES;
            [str release];
            break;
        } else if ([str hasPrefix:RESPONSE_FAIL]) {
            [str release];
            break;
        }
        [str release];
    }
    if (messageId == PROXY_UPDATE_CONF && ret == YES) {
        _isPrefChanged = NO;
    }
    [pool release];
    return ret;
}

#pragma mark - Proxy functions

- (ProxyStatus)currentProxyStatus
{
    ProxyStatus status = kProxyNone;
    CFDictionaryRef proxyDict = CFNetworkCopySystemProxySettings();
    BOOL pacEnabled = [[(NSDictionary *) proxyDict objectForKey:@"ProxyAutoConfigEnable"] boolValue];
    BOOL socksEnabled = [[(NSDictionary *) proxyDict objectForKey:@"SOCKSEnable"] boolValue];
    if (socksEnabled || pacEnabled) {
        status = pacEnabled ? kProxyPac : kProxySocks;
    }
    CFRelease(proxyDict);
    return status;
}

- (BOOL)proxyEnabled
{
    return [self readBool:GLOBAL_PROXY_ENABLE_KEY];
}

- (void)setProxyEnabled:(BOOL)enabled
{
    [self saveBool:enabled forKey:GLOBAL_PROXY_ENABLE_KEY];
    [self performSelectorOnMainThread:@selector(setBadge:) withObject:[NSNumber numberWithBool:enabled] waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(setProxySwitcher:) withObject:[NSNumber numberWithBool:enabled] waitUntilDone:NO];
}

- (void)fixProxy
{
    [NSThread detachNewThreadSelector:@selector(threadFixProxy) toTarget:self withObject:nil];
}

- (void)setPrefChanged
{
    _isPrefChanged = YES;
}

- (void)notifyChanged:(BOOL)isForce
{
    BOOL proxyEnabled = [self proxyEnabled];
    if (!isForce && !proxyEnabled) {
        return;
    }
    if (_isPrefChanged) {
        [self syncSettings];
        if (!isForce) {
            [NSThread detachNewThreadSelector:@selector(threadChangeProxyStatus:)
                                     toTarget:self
                                   withObject:[NSNumber numberWithBool:[self readBool:@"AUTO_PROXY"]]];
        }
        [NSThread detachNewThreadSelector:@selector(threadSendNotifyMessage:) toTarget:self withObject:[NSNumber numberWithInt:PROXY_UPDATE_CONF]];
    }
}

- (void)saveSettings
{
    if (_isPrefChanged) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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

#pragma mark - Profile read settings

- (void)saveObject:(id)value forKey:(NSString *)key
{
    if (key == nil) {
        return;
    }
    if ([self isDefaultProfile] || \
        [key isEqualToString:GLOBAL_PROXY_ENABLE_KEY] || \
        [key isEqualToString:GLOBAL_PROFILE_NOW_KEY] || \
        [key isEqualToString:GLOBAL_PROFILE_LIST_KEY]) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    } else {
        NSArray *profileList = [self profileList];
        NSDictionary *currentDict = [profileList objectAtIndex:_currentProfile];
        if (currentDict == nil) {
            return;
        }
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:currentDict];
        [newDict setObject:value forKey:key];
        NSMutableArray *newProfileList = [NSMutableArray arrayWithArray:profileList];
        [newProfileList replaceObjectAtIndex:_currentProfile withObject:newDict];
        [self updateProfileList:newProfileList];
    }
}

- (id)readObject:(NSString *)key
{
    id value = nil;
    if (key == nil) {
        return nil;
    }
    if ([self isDefaultProfile] || \
        [key isEqualToString:GLOBAL_PROXY_ENABLE_KEY] || \
        [key isEqualToString:GLOBAL_PROFILE_NOW_KEY] || \
        [key isEqualToString:GLOBAL_PROFILE_LIST_KEY]) {
        value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    } else {
        NSArray *profileList = [self profileList];
        NSDictionary *currentDict = [profileList objectAtIndex:_currentProfile];
        value = [currentDict objectForKey:key];
    }
    return value;
}

- (void)saveBool:(BOOL)value forKey:(NSString *)key
{
    [self saveObject:[NSNumber numberWithBool:value] forKey:key];
}

- (BOOL)readBool:(NSString *)key
{
    return [[self readObject:key] boolValue];
}

- (void)saveInt:(NSInteger)value forKey:(NSString *)key
{
    [self saveObject:[NSNumber numberWithInteger:value] forKey:key];
}

- (NSInteger)readInt:(NSString *)key
{
    NSNumber *value = [self readObject:key];
    if (value == nil || ![value isKindOfClass:[NSNumber class]]) {
        return PROFILE_DEFAULT_INDEX;
    }
    return [value integerValue];
}

- (NSString *)fetchConfigForKey:(NSString *)key andDefault:(NSString *)defaultValue
{
    NSString *config = [self readObject:key];
    NSString *trimmedConfig = [config stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (config == nil || [config length] == 0 || [trimmedConfig length] == 0) {
        config = defaultValue;
    }
    return config;
}

- (BOOL)isDefaultProfile
{
    return _currentProfile == PROFILE_DEFAULT_INDEX;
}

#pragma mark - Profile operations

- (NSInteger)currentProfile
{
    return _currentProfile;
}

- (NSArray *)profileList
{
    NSArray *profileList = [[NSUserDefaults standardUserDefaults] objectForKey:GLOBAL_PROFILE_LIST_KEY];
    if ([profileList isKindOfClass:[NSArray class]]) {
        return profileList;
    }
    return nil;
}

- (NSInteger)profileListCount
{
    return [[self profileList] count];
}

- (NSString *)nameOfProfile:(NSInteger)index
{
    NSString *name = nil;
    NSArray *profileList = [self profileList];
    if (index == PROFILE_DEFAULT_INDEX) {
        name = PROFILE_DEFAULT_NAME;
    } else if (profileList != nil && index >= 0 && index < [profileList count]) {
        NSDictionary *profile = [profileList objectAtIndex:index];
        if ([profile isKindOfClass:[NSDictionary class]]) {
            name = [profile objectForKey:PROFILE_NAME_KEY];
        }
    }
    return name;
}

- (void)renameProfile:(NSInteger)index withName:(NSString *)name
{
    NSArray *profileList = [self profileList];
    if (profileList == nil) {
        return;
    }
    NSString *finalName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (finalName == nil || [finalName length] == 0) {
        return;
    }
    if (index >= 0 && index < [profileList count]) {
        NSDictionary *profile = [profileList objectAtIndex:index];
        if ([profile isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *newProfile = [NSMutableDictionary dictionaryWithDictionary:profile];
            [newProfile setObject:finalName forKey:PROFILE_NAME_KEY];
            NSMutableArray *newProfileList = [NSMutableArray arrayWithArray:profileList];
            [newProfileList replaceObjectAtIndex:index withObject:newProfile];
            [self updateProfileList:newProfileList];
        }
    }
}

- (void)updateProfileList:(id)value
{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:GLOBAL_PROFILE_LIST_KEY];
}

- (void)selectProfile:(NSInteger)profileIndex
{
    [self saveInt:profileIndex forKey:GLOBAL_PROFILE_NOW_KEY];
    _currentProfile = profileIndex;
    [self setPrefChanged];
}

- (void)removeProfile:(NSInteger)profileIndex
{
    NSArray *profileList = [self profileList];
    if (profileList == nil) {
        return;
    }
    if (profileIndex >= 0 && profileIndex < [profileList count]) {
        NSMutableArray *newProfileList = [NSMutableArray arrayWithArray:profileList];
        [newProfileList removeObjectAtIndex:profileIndex];
        [self updateProfileList:newProfileList];
        [self selectProfile:PROFILE_DEFAULT_INDEX];
    }
}

- (void)reorderProfile:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSArray *profileList = [self profileList];
    if (profileList == nil || fromIndex == toIndex) {
        return;
    }
    if (toIndex >= 0 && toIndex < [profileList count] &&
        fromIndex >= 0 && fromIndex < [profileList count]) {
        NSMutableArray *newProfileList = [NSMutableArray arrayWithArray:profileList];
        id movingObject = [profileList objectAtIndex:fromIndex];
        [newProfileList removeObjectAtIndex:fromIndex];
        [newProfileList insertObject:movingObject atIndex:toIndex];
        [self updateProfileList:newProfileList];
        [self selectProfile:PROFILE_DEFAULT_INDEX];
    }
}

- (void)reloadProfile
{
    _currentProfile = [self readInt:GLOBAL_PROFILE_NOW_KEY];
    if (_currentProfile < 0 || _currentProfile >= [self profileListCount]) {
        _currentProfile = PROFILE_DEFAULT_INDEX;
    }
}

- (void)createProfile:(NSString *)rawName withInfo:(NSDictionary *)rawInfo
{
    NSString *profileName = [rawName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (profileName == nil || [profileName length] == 0) {
        return;
    }
    NSMutableDictionary *profileInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:profileName, PROFILE_NAME_KEY, nil];
    if (rawInfo) {
        [profileInfo addEntriesFromDictionary:rawInfo];
    }
    NSArray *profileList = [self profileList];
    NSMutableArray *newProfileList = [NSMutableArray arrayWithArray:profileList];
    [newProfileList addObject:profileInfo];
    [self updateProfileList:newProfileList];
    [self selectProfile:[newProfileList count] - 1];
    [[self tableView] reloadData];
}

#pragma mark - JSON settings sync

- (void)appendString:(NSMutableString *)string key:(NSString *)key value:(NSString *)value isString:(BOOL)isString
{
    if (value == nil) {
        return;
    }
    static NSString *stringFormat =  @"    \"%@\":\"%@\",\n";
    static NSString *normalFormat = @"    \"%@\":%@,\n";
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (isString) {
        trimmedValue = [self escapeString:trimmedValue];
    }
    [string appendFormat:isString ? stringFormat : normalFormat, key, trimmedValue];
}

- (NSString *)escapeString:(NSString *)string
{
    NSString *escapedValue = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escapedValue = [escapedValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return escapedValue;
}

- (void)syncSettings
{
    NSString *remoteServer = [self fetchConfigForKey:@"REMOTE_SERVER" andDefault:@"127.0.0.1"];
    NSString *remotePort = [self fetchConfigForKey:@"REMOTE_PORT" andDefault:@"8080"];
    NSString *localPort = [NSString stringWithFormat:@"%d", LOCAL_PORT];
    NSString *socksPass = [self fetchConfigForKey:@"SOCKS_PASS" andDefault:@"123456"];
    NSString *timeOut = [NSString stringWithFormat:@"%d", LOCAL_TIMEOUT];
    NSString *cryptoMethod = [self fetchConfigForKey:@"CRYPTO_METHOD" andDefault:[CipherViewController defaultCipher]];
    NSMutableString *exceptString = nil;
    NSString *pacFilePath = [self fetchConfigForKey:@"PAC_FILE" andDefault:nil];
    NSInteger i;
    
    NSString *excepts = [self fetchConfigForKey:@"EXCEPTION_LIST" andDefault:nil];
    if (excepts) {
        NSMutableArray *exceptArray = [NSMutableArray array];
        NSArray *origArray = [excepts componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        for (NSString *s in origArray) {
            if (![s isEqualToString:@""]) {
                [exceptArray addObject:s];
            }
        }
        if ([exceptArray count] > 0) {
            exceptString = [NSMutableString stringWithFormat:@"[\"%@\"", [self escapeString:[exceptArray objectAtIndex:0]]];
            for (i = 1; i < [exceptArray count]; i++) {
                [exceptString appendFormat:@",\"%@\"", [self escapeString:[exceptArray objectAtIndex:i]]];
            }
            [exceptString appendFormat:@"]"];
        }
    }
    
    if (![CipherViewController cipherIsValid:cryptoMethod]) {
        cryptoMethod = [CipherViewController defaultCipher];
    }

    NSMutableString *jsonConfigString = [NSMutableString stringWithString:@"{\n"];
    [self appendString:jsonConfigString key:@"server" value:remoteServer isString:YES];
    [self appendString:jsonConfigString key:@"server_port" value:remotePort isString:NO];
    [self appendString:jsonConfigString key:@"local_port" value:localPort isString:NO];
    [self appendString:jsonConfigString key:@"password" value:socksPass isString:YES];
    [self appendString:jsonConfigString key:@"timeout" value:timeOut isString:NO];
    [self appendString:jsonConfigString key:@"method" value:cryptoMethod isString:YES];
    [self appendString:jsonConfigString key:@"except_list" value:exceptString isString:NO];
    [self appendString:jsonConfigString key:@"pac_path" value:pacFilePath isString:YES];
    [jsonConfigString appendFormat:@"    \"pac_port\":%d\n}\n", PAC_PORT];
    [jsonConfigString writeToFile:_configPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
