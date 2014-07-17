@class LFFinderController;

// Specifies the action of the Save button
// To display the Save button instead of the Edit button, set <sourcePath>
typedef enum {
  LFFinderModeDefault, // Calls delegate method if it exists, otherwise defaults to LFFinderModeCopy
  LFFinderModeLink, // Creates a hard link to <sourcePath> in the selected folder
    // Defaults to LFFinderModeCopy if linking fails, or if the item has already been hard-linked
  LFFinderModeCopy, // Copies <sourcePath> to the selected folder
  LFFinderModeMove  // Moves <sourcePath> to the selected folder
} LFFinderMode;

@protocol LFFinderActionDelegate <NSObject>
@optional
-(void)finder:(LFFinderController*)finder didSaveItemAtPath:(NSString*)path toPath:(NSString*)dest;
  // Called after LFFinderController has finished saving but before it has dismissed itself
  // Applies to LFFinderModeLink, LFFinderModeCopy, and LFFinderModeMove
-(void)finder:(LFFinderController*)finder didSelectItemAtPath:(NSString*)path;
  // If implemented, overrides the default action when an item is selected
-(void)finder:(LFFinderController*)finder didSelectItemsAtPaths:(NSArray*)paths;
  // If implemented, enables the multiple-selection button; method called after items are selected

// The next two only apply to LFFinderModeDefault, but only one should be implemented
// They are called after the Save button is pressed
-(void)finder:(LFFinderController*)finder didSelectPath:(NSString*)path;
-(void)finder:(LFFinderController*)finder saveItemAtPath:(NSString*)path toPath:(NSString*)dest;
  // Allows the user to specify a custom file name
@end

@interface LFFinderController : UINavigationController <UITableViewDelegate,UITableViewDataSource> {
  NSMutableArray* history;
  UIButton* dimmingView;
  UIView* historyView;
  UITableView* historyTable;
  BOOL customPrompt,historyChanged;
}
@property(assign,nonatomic) LFFinderMode saveMode;
@property(assign,nonatomic) id<LFFinderActionDelegate> actionDelegate;
@property(retain,nonatomic) NSString* sourcePath;
@property(retain,nonatomic) NSString* prompt;
@property(readonly,nonatomic) UIBarButtonItem* dismissItem;
@property(readonly,nonatomic) UIBarButtonItem* historyItem;
-(id)initWithMode:(LFFinderMode)mode;
-(void)dismiss;
@end
