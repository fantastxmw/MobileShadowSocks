//
//  PerAppViewController.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-6-30.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "PerAppStubViewController.h"

#define kSectionInfo 1
#define kURLPlugin @"cydia://package/com.linusyang.ssperapp"
#define kURLPref @"prefs:root=ShadowSocks"
#define kPerAppPath @"/Library/MobileSubstrate/DynamicLibraries/SSPerApp.dylib"

@interface PerAppStubViewController ()

@property (nonatomic, assign) BOOL hasPerApp;

@end

@interface LSApplicationWorkspace : NSObject

+ (id)defaultWorkspace;
- (BOOL)openSensitiveURL:(NSURL *)url withOptions:(id)options;

@end

@implementation PerAppStubViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Per-App Proxy", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.hasPerApp = [[NSFileManager defaultManager] fileExistsAtPath:kPerAppPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionInfo + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kSectionInfo) {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kSectionInfo - 1) {
        if (!self.hasPerApp) {
            return NSLocalizedString(@"Per-App Proxy needs to install “ShadowSocks Per-App Plugin” from Cydia.", nil);
        } else {
            return NSLocalizedString(@"“ShadowSocks Per-App Plugin” is installed. Please use Settings to setup Per-App Proxy.", nil);
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PerAppTableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        [[cell textLabel] setAdjustsFontSizeToFitWidth:YES];
    }
    if (!self.hasPerApp) {
        [[cell textLabel] setText:NSLocalizedString(@"Visit Cydia", nil)];
    } else {
        [[cell textLabel] setText:NSLocalizedString(@"Go to Settings", nil)];
    }
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.hasPerApp) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kURLPlugin]];
    } else {
        [[LSApplicationWorkspace defaultWorkspace] openSensitiveURL:[NSURL URLWithString:kURLPref] withOptions:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
