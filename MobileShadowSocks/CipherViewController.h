//
//  CipherViewController.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-5-26.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingTableViewController.h"

@interface CipherViewController : UITableViewController {
    NSInteger _selectedCipher;
}

+ (BOOL)cipherIsValid:(NSString *)cipher;
+ (NSString *)defaultCipher;

@end
