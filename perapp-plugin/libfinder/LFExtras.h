@interface NSString (AppSupport) // not implemented in libfinder
-(NSString*)stringByEscapingXMLSpecialCharacters;
@end

@interface NSString (LFExtras)
-(NSString*)stringByEscapingNewlines; // "\n" => "\\n", "\\" => "\\\\"
-(NSString*)stringByUnescapingNewlines; // the inverse of the above
@end

@interface NSNumber (LFExtras)
-(NSString*)stringByFormattingAsFileSize;
@end

@interface NSError (LFExtras)
-(void)showAlert; // thread-safe, localized
@end
