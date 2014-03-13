//
//  ProfileManager.m
//  MobileShadowSocks
//
//  Created by Linus Yang on 14-3-12.
//  Copyright (c) 2014 Linus Yang. All rights reserved.
//

#import "ProfileManager.h"
#import "CipherViewController.h"
#import "SettingTableViewController.h"

#define JSON_CONFIG_NAME @"com.linusyang.shadowsocks.json"

@interface ProfileManager ()

@property (nonatomic, assign) NSInteger currentProfile;

@end

@implementation ProfileManager

SINGLETON_FOR_CLASS(ProfileManager)

- (id)init
{
    self = [super init];
    if (self) {
        _currentProfile = PROFILE_DEFAULT_INDEX;
        [self reloadProfile];
        
        NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
        NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
        _configPath = [[NSString alloc] initWithFormat:@"%@/%@", prefsDirectory, JSON_CONFIG_NAME];
    }
    return self;
}

- (void)dealloc
{
    [_configPath release];
    _configPath = nil;
    [super dealloc];
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

- (NSString *)nameOfCurrentProfile
{
    return [self nameOfProfile:self.currentProfile];
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

- (void)createProfile:(NSString *)profileName withInfo:(NSDictionary *)rawInfo
{
    if (profileName == nil || [profileName length] == 0) {
        // Overwrite `default' profile
        if (rawInfo != nil) {
            [rawInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
            }];
            [self selectProfile:PROFILE_DEFAULT_INDEX];
        }
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

- (BOOL)syncSettings
{
    NSString *remoteServer = [self fetchConfigForKey:kProfileServer andDefault:@"127.0.0.1"];
    NSString *remotePort = [self fetchConfigForKey:kProfilePort andDefault:@"8080"];
    NSString *localPort = [NSString stringWithFormat:@"%d", LOCAL_PORT];
    NSString *socksPass = [self fetchConfigForKey:kProfilePass andDefault:@"123456"];
    NSString *timeOut = [NSString stringWithFormat:@"%d", LOCAL_TIMEOUT];
    NSString *cryptoMethod = [self fetchConfigForKey:kProfileCrypto andDefault:[CipherViewController defaultCipher]];
    NSMutableString *exceptString = nil;
    NSString *pacFilePath = [self fetchConfigForKey:kProfilePac andDefault:nil];
    NSInteger i;
    
    NSString *excepts = [self fetchConfigForKey:kProfileExcept andDefault:nil];
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
    
    if ([self configFileExists]) {
        NSString *fileContent = [NSString stringWithContentsOfFile:self.configPath encoding:NSUTF8StringEncoding error:nil];
        if ([fileContent isEqualToString:jsonConfigString]) {
            return NO;
        }
    }
    
    [jsonConfigString writeToFile:_configPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return YES;
}

- (void)removeConfigFile
{
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:self.configPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.configPath error:&error];
    }
}

- (BOOL)configFileExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.configPath];
}

@end
