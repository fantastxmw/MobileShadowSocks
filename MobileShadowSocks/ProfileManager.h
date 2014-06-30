//
//  ProfileManager.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GLOBAL_PROFILE_NOW_KEY @"SELECTED_PROFILE"
#define GLOBAL_PROFILE_LIST_KEY @"PROFILE_LIST"
#define GLOBAL_PROXY_ENABLE_KEY @"PROXY_ENABLED"

#define PROFILE_DEFAULT_NAME NSLocalizedString(@"Default", nil)
#define PROFILE_DEFAULT_INDEX -1
#define PROFILE_NAME_KEY @"PROFILE_NAME"

#define kProfileServer @"REMOTE_SERVER"
#define kProfilePort @"REMOTE_PORT"
#define kProfilePass @"SOCKS_PASS"
#define kProfileCrypto @"CRYPTO_METHOD"
#define kProfilePerApp @"PER_APP"
#define kProfilePac @"PAC_FILE"
#define kProfileExcept @"EXCEPTION_LIST"
#define kProfileAutoProxy @"AUTO_PROXY"

@interface ProfileManager : NSObject

@property (nonatomic, retain, readonly) NSString *configPath;

+ (ProfileManager *)sharedProfileManager;

- (BOOL)syncSettings;
- (void)removeConfigFile;
- (BOOL)configFileExists;

- (NSInteger)currentProfile;
- (NSInteger)profileListCount;
- (NSString *)nameOfProfile:(NSInteger)index;
- (NSString *)nameOfCurrentProfile;

- (void)selectProfile:(NSInteger)profileIndex;
- (void)removeProfile:(NSInteger)profileIndex;
- (void)reorderProfile:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)renameProfile:(NSInteger)index withName:(NSString *)name;
- (void)reloadProfile;
- (void)createProfile:(NSString *)profileName withInfo:(NSDictionary *)rawInfo;

- (void)saveObject:(id)value forKey:(NSString *)key;
- (id)readObject:(NSString *)key;
- (void)saveBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)readBool:(NSString *)key;
- (void)saveInt:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)readInt:(NSString *)key;
- (NSString *)fetchConfigForKey:(NSString *)key andDefault:(NSString *)defaultValue;

@end
