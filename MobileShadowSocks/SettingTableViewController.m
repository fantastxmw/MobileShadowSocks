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
#import "ImagePickerViewController.h"
#import "ProxyManager.h"
#import "ProfileManager.h"
#import "UIAlertView+TextField.h"
#import "UIAlertView+Blocks.h"
#import "PerAppStubViewController.h"
#import "UIView+UserInfo.h"
#import "AppDelegate.h"

#define APP_VER @"0.3.2"
#define APP_BUILD @"3"

#define kURLPrefix @"ss://"
#define kURLHelpFile @"https://github.com/linusyang/MobileShadowSocks/blob/master/README.md"
#define kURLPubAccounts @"https://www.shadowsocks.net/"
#define PAC_DEFAULT_NAME @"auto.pac"
#define PAC_SUFFIX @".pac"
#define PAC_FUNC_NAME @"FindProxyForURL"

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

typedef enum {
    kActionSheetQRCode = 0,
    
    kActionSheetCount
} ActionSheetTag;

typedef enum {
    kAlertViewTagAbout = 100,
    kAlertViewTagDefaultPac,
    kAlertViewTagNewProfile,
    kAlertViewTagRepair,
    kAlertViewTagScanError,

    kAlertViewTagCount
} AlertViewTag;

typedef enum {
    QRCodeActionCamera = 0,
    QRCodeActionLibrary,
    QRCodeActionShare
} QRCodeAction;

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

@interface SettingTableViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, retain) UIPopoverController *popController;
@property (nonatomic, assign) BOOL isPoped;
@property (nonatomic, retain) ProxyManager *proxyManager;

@end

@implementation SettingTableViewController

#pragma mark - Extern methods

- (BOOL)useLibFinder
{
    return NO;
}

- (UIViewController *)allocFinderController
{
    return nil;
}

- (void)finderSelectedFilePath:(NSString *)path checkSanity:(BOOL)check
{
    NSString *pacFile = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL hasPacFunc = YES;
    BOOL sanity = NO;
    if ([[pacFile lowercaseString] hasSuffix:PAC_SUFFIX] &&
        [[NSFileManager defaultManager] fileExistsAtPath:pacFile]) {
        if (check) {
            hasPacFunc = [[NSString stringWithContentsOfFile:pacFile
                                                    encoding:NSUTF8StringEncoding error:nil]
                          rangeOfString:PAC_FUNC_NAME].location != NSNotFound;
        }
        if (hasPacFunc) {
            [[ProfileManager sharedProfileManager] saveObject:pacFile forKey:kProfilePac];
            [self.tableView reloadData];
            sanity = YES;
        }
    }
    if (!sanity) {
        [self showError:NSLocalizedString(@"The file is not ended with “.pac” or a valid PAC file.", nil)];
    }
    [self imagePickerControllerDidCancel:nil];
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _isBuggyPhotoPicker = !DEVICE_IS_IPAD() && SYSTEM_VERSION_LESS_THAN(@"7.0") && !SYSTEM_VERSION_LESS_THAN(@"6.0");
        _pacDefaultFile = [[NSString alloc] initWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], PAC_DEFAULT_NAME];
        _proxyManager = [[ProxyManager alloc] init];
        _proxyManager.delegate = self;
       
        if (DEVICE_IS_IPAD())
            _cellWidth = 560.0f;
        else
            _cellWidth = 180.0f;
        
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
                            kProfileServer,
                            @"127.0.0.1",
                            CELL_TEXT, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Port", nil),
                            kProfilePort,
                            @"8080",
                            CELL_TEXT CELL_NUM, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Password", nil),
                            kProfilePass,
                            @"123456",
                            CELL_TEXT CELL_PASS, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Cipher", nil),
                            kProfileCrypto,
                            @"table",
                            CELL_VIEW, nil],
                           nil],
                          [NSArray arrayWithObjects:
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Auto Proxy", nil),
                            kProfileAutoProxy,
                            @"NO",
                            CELL_SWITCH, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Per-App Proxy", nil),
                            kProfilePerApp,
                            @"NO",
                            CELL_VIEW, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"PAC File", nil),
                            kProfilePac,
                            NSLocalizedString(@"Please specify file path", nil),
                            CELL_TEXT, nil],
                           [NSArray arrayWithObjects:
                            NSLocalizedString(@"Exceptions", nil),
                            kProfileExcept,
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
    [[ProfileManager sharedProfileManager] reloadProfile];
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
    [_tableSectionTitle release];
    [_tableElements release];
    [_pacDefaultFile release];
    [_popController release];
    _popController = nil;
    [_proxyManager release];
    _proxyManager = nil;
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
    if ([cellKey isEqualToString:kProfilePac]) {
        if ([self useLibFinder]) {
            cellType = CELL_VIEW;
        }
    }
    
    if ([cellType hasPrefix:CELL_BUTTON]) {
        if ([cellKey isEqualToString:@"DEFAULT_PAC_BUTTON"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Choose PAC File", nil)
                                                            message:NSLocalizedString(@"China Whitelist might be only useful for users in China.", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil) 
                                                  otherButtonTitles:NSLocalizedString(@"China Whitelist",nil),
                                                                    NSLocalizedString(@"Redirect All Traffic",nil),
                                  nil];
            [alert setTag:kAlertViewTagDefaultPac];
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
        if ([cellKey isEqualToString:kProfileCrypto]) {
            CipherViewController *cipherViewController = [[CipherViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:cipherViewController animated:YES];
            [cipherViewController release];
        } else if ([cellKey isEqualToString:GLOBAL_PROFILE_NOW_KEY]) {
            ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:profileViewController animated:YES];
            [profileViewController release];
        } else if ([cellKey isEqualToString:kProfilePerApp]) {
            UIViewController *viewController = [[PerAppStubViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        } else if ([cellKey isEqualToString:kProfilePac]) {
            UIViewController *finderController = [self allocFinderController];
            if (finderController != nil) {
                if (DEVICE_IS_IPAD()) {
                    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:finderController];
                    popController.delegate = self;
                    self.popController = popController;
                    [popController release];
                    [self showPopController];
                } else {
                    [self presentViewController:finderController animated:YES completion:nil];
                }
                [finderController release];
            }
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
    
    if ([cellKey isEqualToString:kProfilePac]) {
        if ([self useLibFinder]) {
            cellType = CELL_VIEW;
            cellDefaultValue = @"";
            cellIdentifier = [cellIdentifier stringByAppendingString:CELL_VIEW];
        }
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        UITableViewCellStyle cellStyle = [cellType hasPrefix:CELL_VIEW] ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
        [[cell textLabel] setText:cellTitle];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
        [[cell textLabel] setTextColor:kblackColor];
        cell.userInfo = cellKey;
        
        if ([cellType hasPrefix:CELL_TEXT]) {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, _cellWidth, 24)];
            textField.userInfo = cellKey;
            if ([AppDelegate isScottForstall]) {
                [textField setTextColor:kgrayBlueColor];
            }
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
            [cell setAccessoryView:textField];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [textField release];
        }
        else if ([cellType hasPrefix:CELL_SWITCH]) {
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            switcher.userInfo = cellKey;
            [switcher addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            if ([cellKey isEqualToString:GLOBAL_PROXY_ENABLE_KEY]) {
                if ([switcher respondsToSelector:@selector(setAlternateColors:)])
                    [switcher setAlternateColors:YES];
            }
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
        NSString *currentSetting = [[ProfileManager sharedProfileManager] readObject:cellKey];
        [textField setText:currentSetting ? currentSetting : @""];
    } else if ([cellType hasPrefix:CELL_SWITCH]) {
        UISwitch *switcher = (UISwitch *) [cell accessoryView];
        BOOL switchValue = [[ProfileManager sharedProfileManager] readBool:cellKey];
        [switcher setOn:switchValue animated:NO];
    } else if ([cellType hasPrefix:CELL_VIEW]) {
        NSString *currentSetting = nil;
        if ([cellKey isEqualToString:GLOBAL_PROFILE_NOW_KEY]) {
            currentSetting = [[ProfileManager sharedProfileManager] nameOfCurrentProfile];
        } else {
            currentSetting = [[ProfileManager sharedProfileManager] readObject:cellKey];
        }
        if (![cellKey isEqualToString:kProfilePerApp]) {
            NSString *labelString = currentSetting ? currentSetting : cellDefaultValue;
            [[cell detailTextLabel] setText:labelString];
        }
    }
    
    if ([cellKey isEqualToString:kProfilePac]) {
        BOOL isEnabled = [[ProfileManager sharedProfileManager] readBool:kProfileAutoProxy];
        [self setPacFileCell:cell enabled:isEnabled];
    }
    
    return cell;
}

#pragma mark - Alert views

- (void)showAbout
{
    NSString *aboutMessage = [NSString stringWithFormat:@"%@ %@ (%@ %@)\n%@: @linusyang\n\n%@\n%@",
                              NSLocalizedString(@"Version", nil), APP_VER, NSLocalizedString(@"Rev", nil), APP_BUILD,
                              NSLocalizedString(@"Twitter", nil), NSLocalizedString(@"ShadowSocks is created by @clowwindy", nil),
                              NSLocalizedString(@"Icon and ShadowSocks (libev) by @madeye", nil)];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About", nil) message:aboutMessage delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:NSLocalizedString(@"Help Page",nil), NSLocalizedString(@"Public Accounts",nil), nil];
    [alert setTag:kAlertViewTagAbout];
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
    NSString *pacFile = [[[ProfileManager sharedProfileManager] readObject:kProfilePac] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([pacFile length] > 0 && ![[NSFileManager defaultManager] fileExistsAtPath:pacFile]) {
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
    [alert setTag:kAlertViewTagRepair];
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
    UITextField *textField = [alert textFieldInitAtFirstIndex];
    if (message) {
        textField.placeholder = PROFILE_DEFAULT_NAME;
    } else {
        [textField setPlaceholder:NSLocalizedString(@"Name", nil)];
    }
    [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [alert setTag:kAlertViewTagNewProfile];
    alert.userInfo = profileInfo;
    if (profileInfo) {
        NSString *presetName = [NSString stringWithFormat:@"%@", [profileInfo objectForKey:kProfileServer]];
        [textField setText:presetName];
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
                                          otherButtonTitles:NSLocalizedString(@"Copy Link",nil),
                          NSLocalizedString(@"Open Link",nil), nil];
    [alert setTag:kAlertViewTagScanError];
    alert.userInfo = rawLink;
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        AlertViewTag tag = (AlertViewTag) [alertView tag];

        switch (tag) {
            case kAlertViewTagAbout: {
                NSString *targetURL = kURLHelpFile;
                if (buttonIndex != alertView.firstOtherButtonIndex) {
                    targetURL = kURLPubAccounts;
                }
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:targetURL]];
                break;
            }
                
            case kAlertViewTagDefaultPac: {
                NSString *pacFile = @"";
                if (buttonIndex == [alertView firstOtherButtonIndex]) {
                    pacFile = _pacDefaultFile;
                }
                [[ProfileManager sharedProfileManager] saveObject:pacFile forKey:kProfilePac];
                for (UITableViewCell *cell in self.tableView.visibleCells) {
                    if ([((NSString *) cell.userInfo) isEqualToString:kProfilePac]) {
                        if (![self useLibFinder]) {
                            if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
                                UITextField *textField = (UITextField *) cell.accessoryView;
                                [textField setText:pacFile];
                            }
                        } else {
                            cell.detailTextLabel.text = pacFile;
                            [self.tableView reloadRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationNone];
                        }
                        break;
                    }
                }
                break;
            }
                
            case kAlertViewTagNewProfile: {
                UITextField *textField = [alertView textFieldAtFirstIndex];
                NSDictionary *userInfo = alertView.userInfo;
                NSString *profileName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (profileName == nil || profileName.length == 0) {
                    if (userInfo != nil) {
                        NSString *alertViewMessage = alertView.message;
                        [UIAlertView showWithTitle:NSLocalizedString(@"Warning", nil)
                                           message:NSLocalizedString(@"Profile name is empty. Do you want to overwrite the default profile, or retry with a new name?", nil)
                                 cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                 otherButtonTitles:@[NSLocalizedString(@"Save to Default", nil)]
                                          tapBlock:
                         ^(UIAlertView *alertView, NSInteger buttonIndex) {
                             if (buttonIndex != alertView.cancelButtonIndex) {
                                 // Save to default
                                 [self setProfile:profileName withInfo:userInfo];
                             } else {
                                 // Retry
                                 [self showNewProfile:userInfo withMessage:alertViewMessage];
                             }
                         }];
                        
                    } else {
                        NSString *alertViewMessage = alertView.message;
                        [UIAlertView showWithTitle:NSLocalizedString(@"Error", nil)
                                           message:NSLocalizedString(@"Profile name cannot be empty. Do you want to retry?", nil)
                                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                 otherButtonTitles:@[NSLocalizedString(@"Retry", nil)]
                                          tapBlock:
                         ^(UIAlertView *alertView, NSInteger buttonIndex) {
                             if (buttonIndex != alertView.cancelButtonIndex) {
                                 // Retry
                                 [self showNewProfile:userInfo withMessage:alertViewMessage];
                             }
                         }];
                    }
                } else {
                    [self setProfile:profileName withInfo:userInfo];
                }
                break;
            }
                
            case kAlertViewTagRepair: {
                [self.proxyManager forceStopProxyDaemon];
                break;
            }
                
            case kAlertViewTagScanError: {
                NSString *rawLink = alertView.userInfo;
                if (rawLink == nil) {
                    break;
                }
                if (buttonIndex == [alertView firstOtherButtonIndex]) {
                    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
                    pasteBoard.string = rawLink;
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:rawLink]];
                }
                break;
            }
                
            default:
                break;
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
        [self dismissViewControllerAnimated:YES completion:nil];
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
                UIImagePickerController *pickerController;
                if (_isBuggyPhotoPicker) {
                    pickerController = [[ImagePickerViewController alloc] init];
                } else {
                    pickerController = [[UIImagePickerController alloc] init];
                }
                pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                pickerController.delegate = self;
                if (DEVICE_IS_IPAD()) {
                    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:pickerController];
                    popController.delegate = self;
                    self.popController = popController;
                    [popController release];
                    [self showPopController];
                } else {
                    [self presentViewController:pickerController animated:YES completion:nil];
                }
                [pickerController release];
            } else {
                [self showError:NSLocalizedString(@"Photo library is not available.", nil)];
            }
            break;
        }
            
        case QRCodeActionShare: {
            NSString *remoteServer = [[ProfileManager sharedProfileManager] fetchConfigForKey:kProfileServer andDefault:@"127.0.0.1"];
            NSString *remotePort = [[ProfileManager sharedProfileManager] fetchConfigForKey:kProfilePort andDefault:@"8080"];
            NSString *socksPass = [[ProfileManager sharedProfileManager] fetchConfigForKey:kProfilePass andDefault:@"123456"];
            NSString *cryptoMethod = [[ProfileManager sharedProfileManager] fetchConfigForKey:kProfileCrypto andDefault:[CipherViewController defaultCipher]];
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
                                  linkAddress, kProfileServer,
                                  linkPort, kProfilePort,
                                  linkPassword, kProfilePass,
                                  linkMethod, kProfileCrypto,
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

- (void)setPacFileCell:(UITableViewCell *)cell enabled:(BOOL)isEnabled
{
    UIColor *textColor;
    if ([AppDelegate isScottForstall]) {
        textColor = isEnabled ? kgrayBlueColor : kgrayBlueColorDisabled;
    } else {
        textColor = isEnabled ? kblackColor : kblackColorDisabled;
    }
    if ([self useLibFinder]) {
        cell.detailTextLabel.textColor = textColor;
    } else {
        if ([cell.accessoryView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *) cell.accessoryView;
            [textField setEnabled:isEnabled];
            [textField setTextColor:textColor];
        }
    }
    [[cell textLabel] setTextColor:isEnabled ? kblackColor : kblackColorDisabled];
    [cell setUserInteractionEnabled:isEnabled];
}

- (void)setPacFileCellEnabled:(BOOL)isEnabled
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSString *userInfo = cell.userInfo;
        if ([userInfo isEqualToString:kProfilePac]) {
            [self setPacFileCell:cell enabled:isEnabled];
            break;
        }
    }
}

- (void)setProxySwitcher:(BOOL)enabled
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSString *userInfo = cell.userInfo;
        if ([userInfo isEqualToString:GLOBAL_PROXY_ENABLE_KEY]) {
            if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
                UISwitch *switcher = (UISwitch *) cell.accessoryView;
                [switcher setOn:enabled];
            }
            break;
        }
    }
}

- (void)setAutoProxySwitcher:(BOOL)enabled
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSString *userInfo = cell.userInfo;
        if ([userInfo isEqualToString:kProfileAutoProxy]) {
            if ([cell.accessoryView isKindOfClass:[UISwitch class]]) {
                UISwitch *switcher = (UISwitch *) cell.accessoryView;
                [switcher setOn:enabled];
            }
            [self setPacFileCellEnabled:enabled];
            break;
        }
    }
}

- (void)setBadge:(BOOL)enabled
{
    if (enabled) {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(setApplicationBadgeString:)]) {
            [[UIApplication sharedApplication] setApplicationBadgeString:NSLocalizedString(@"On", nil)];
        } else {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        }
    } else {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

- (void)switchChanged:(id)sender
{
    UISwitch* switcher = sender;
    NSString *key = switcher.userInfo;
    if ([key isEqualToString:GLOBAL_PROXY_ENABLE_KEY]) {
        [self.proxyManager setProxyEnabled:switcher.on];
        return;
    }
    [[ProfileManager sharedProfileManager] saveBool:switcher.on forKey:key];
    if ([key isEqualToString:kProfileAutoProxy]) {
        [self setPacFileCellEnabled:switcher.on];
        [self.proxyManager syncAutoProxy];
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
    NSString *key = textField.userInfo;
    [[ProfileManager sharedProfileManager] saveObject:[textField text] forKey:key];
}

#pragma mark - Profile methods

- (void)setProfile:(NSString *)profileName withInfo:(NSDictionary *)userInfo
{
    [[ProfileManager sharedProfileManager] createProfile:profileName withInfo:userInfo];
    [[self tableView] reloadData];
}

#pragma mark - Proxy methods

- (void)fixProxy
{
    [self.tableView reloadData];
    [self.proxyManager syncProxyStatus:YES];
}

- (void)updateProxy
{
    [self.proxyManager syncProxyStatus:NO];
}


@end
