@interface LFClient : NSObject
+(NSDictionary*)attributesOfItemAtPath:(NSString*)path error:(NSError**)error;
+(NSArray*)contentsOfDirectoryAtPath:(NSString*)path error:(NSError**)error;
+(NSArray*)contentsOfZIPArchiveAtPath:(NSString*)path comment:(NSString**)comment error:(NSError**)error;
+(BOOL)copyItemAtPath:(NSString*)path toPath:(NSString*)dest error:(NSError**)error;
+(BOOL)createDirectoryAtPath:(NSString*)path withIntermediateDirectories:(BOOL)create attributes:(NSDictionary*)attributes error:(NSError**)error;
+(BOOL)createSymbolicLinkAtPath:(NSString*)path withDestinationPath:(NSString*)target error:(NSError**)error;
+(BOOL)createZIPArchiveAtPath:(NSString*)path withItemsAtPaths:(NSArray*)paths comment:(NSString*)comment error:(NSError**)error;
+(BOOL)fileExistsAtPath:(NSString*)path;
+(BOOL)fileExistsAtPath:(NSString*)path isDirectory:(BOOL*)isDir;
+(BOOL)linkItemAtPath:(NSString*)path toPath:(NSString*)dest error:(NSError**)error;
+(BOOL)moveItemAtPath:(NSString*)path toPath:(NSString*)dest error:(NSError**)error;
+(BOOL)removeItemAtPath:(NSString*)path error:(NSError**)error;
+(BOOL)setAttributes:(NSDictionary*)attributes ofItemAtPath:(NSString*)path error:(NSError**)error;
+(NSFileHandle*)openFileAtPath:(NSString*)path mode:(const char*)mode error:(NSError**)error;
@end
