@interface LFTemporaryFile : NSObject {
  BOOL isTemp;
}
@property(readonly,nonatomic) NSString* path;
-(id)initWithPath:(NSString*)_path forWriting:(BOOL)write;
@end
