# **Introduction**

Libfinder is an iPhone/iPad-compatible library for jailbroken iOS5+ that provides:

* A view controller for manipulating, selecting, and saving files
* A drop-in NSFileManager replacement that can access the entire filesystem from within a sandboxed environment

It is primarily intended for Cydia developers who have some basic familiarity with the UIKit framework.

For a working example, please refer to the [source code](https://bitbucket.org/lordscotland/safaripdfprinter/) of [PDF Printer for Safari](http://apt.thebigboss.org/mobileweb/onepackage.php?bundleid=com.officialscheduler.safaripdfprinter).

# **How to use**

Download these headers to your working directory and ensure that `libfinder.dylib` (from the Cydia package) is in your library path. Include the appropriate headers in your source files, and link with `-lfinder`.

To use with Theos, copy the headers to `$THEOS/include`. If you are cross-compiling, copy `libfinder.dylib` to `$THEOS/lib`. Add `(projectname)_LDFLAGS = -lfinder` to your Makefile.

---

The following describes the components of libfinder's public API, grouped by header.

## **LFFinderController** (LFFinderController.h)

This class provides the main user interface for managing, viewing, selecting, and saving files. Some of its salient features include:

 * Previewing files supported by iOS (PDF files, Microsoft Office documents, iWork documents, multimedia, images, and text files)
 * Opening files in external apps
 * Copying, moving, renaming, and deleting files and folders
 * Creating ZIP archives and listing their contents
 * Selecting one or multiple files
 * Saving files to selected folders

Like other view controllers, you may present this view controller modally. However, on iPad, using a [popover](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIPopoverController_class/Reference/Reference.html) instead is recommended, as it is less obtrusive than the modal view controller.

Example on iPhone:

	LFFinderController* finder=[[LFFinderController alloc] init];
	finder.prompt=@"Choose file";
	finder.actionDelegate=self; // to handle selected files
	[self presentViewController:finder animated:YES completion:NULL];
	[finder release];

Example on iPad:

	if(!sharedPopover){
		LFFinderController* finder=[[LFFinderController alloc]
		  initWithMode:LFFinderModeMove];
		finder.sourcePath=@"/tmp/outfile.txt";
		sharedPopover=[[UIPopoverController alloc]
		  initWithContentViewController:finder];
		[finder release];
	}
	[sharedPopover
	  presentPopoverFromBarButtonItem:saveToolbarItem
	  permittedArrowDirections:UIPopoverArrowDirectionAny
	  animated:YES];

Combined example:

	LFFinderController* finder=[[LFFinderController alloc]
	  initWithMode:LFFinderModeCopy];
	finder.actionDelegate=self;
	finder.sourcePath=@"/var/mobile/Documents/outdir";
	if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad){
		// iPad-only
		if(!sharedPopover){
			sharedPopover=[[UIPopoverController alloc]
			  initWithContentViewController:finder];
		}
		[sharedPopover
		  presentPopoverFromBarButtonItem:saveToolbarItem
		  permittedArrowDirections:UIPopoverArrowDirectionAny
		  animated:NO];
	}
	else {
		[self presentViewController:finder animated:YES completion:NULL];
	}
	[finder release];

## **LFClient** (LFClient.h)

This class enables sandboxed applications to access and manipulate all parts of the filesystem accessible to the "mobile" user. It provides the core functionality that underlies LFFinderController.

For the most part, LFClient is designed to be a drop-in replacement for [NSFileManager](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSFileManager_Class/Reference/Reference.html). For example, when run from inside MobileSafari, this code returns a complete list of file names in the `Library` directory:

	NSError* error;
	[LFClient contentsOfDirectoryAtPath:@"/var/mobile/Library" error:&error];

...whereas the matching NSFileManager call would fail and return `nil`:

	NSError* error;
	[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library" error:&error];

Two additional methods are included for creating and querying ZIP archives. File extraction and encryption are not available.

Example of how to create a ZIP file:

	[LFClient createZIPArchiveAtPath:@"/var/mobile/archive.zip"
	  withItemsAtPaths:[NSArray arrayWithObjects:
	    @"/var/mobile/Media/HighlandPark",
	    @"/var/mobile/Library/Logs",
	    @"/var/mobile/Library/Safari/History.plist",
	    nil]
	  comment:@"logs"
	  error:NULL];

Example of how to list the contents of a ZIP file:

	NSString* comment=nil;
	for (NSDictionary* item in [LFClient
	  contentsOfZIPArchiveAtPath:@"/var/mobile/archive.zip"
	  comment:&comment error:NULL]){
		printf("%s:\n  Original size: %llu B\n  Compressed size: %llu B\n  Last modified: %s\n",
		  [[item objectForKey:@"name"] UTF8String],
		  [[item objectForKey:@"size"] unsignedLongLongValue],
		  [[item objectForKey:@"csize"] unsignedLongLongValue],
		  [[item objectForKey:@"mtime"] description].UTF8String);
	}
	printf("COMMENT: %s\n",comment.UTF8String);

## **LFTemporaryFile** (LFTemporaryFile.h)

This class complements LFClient and enables direct read/write access to files outside an app's sandbox, _without having to copy them_. Instead, if necessary, each instance of this class creates and manages a special temporary link to its target file that is automatically removed on deallocation.

Since linking requires that the target file and the temporary file reside on the same partition, LFTemporaryFile may fail to initialize if the filesystem is abnormally structured. There is little need to make an exception for such a situation, however, as the user will likely be experiencing more serious problems.

Example of how to read and write to a custom configuration file:

	LFTemporaryFile* file=[[LFTemporaryFile alloc]
	  initWithPath:@"/var/mobile/Library/Preferences/config.plist" forWriting:YES];
	if(file){
		NSMutableDictionary* config=[NSMutableDictionary
		  dictionaryWithContentsOfFile:file.path]?:
		  [NSMutableDictionary dictionary];
		[config setObject:[NSNumber numberWithBool:YES] forKey:@"runonce"];
		[config writeToFile:file.path atomically:NO];
		[file release];
	}

As of version 1.0-7, this can also be achieved using LFClient and NSPropertyListSerialization:

	NSFileHandle* handle=[LFClient
	  openFileAtPath:@"/var/mobile/Library/Preferences/config.plist"
	  mode:"w+b" error:NULL];
	if(handle){
		NSMutableDictionary* config=[NSPropertyListSerialization
		  propertyListWithData:[handle readDataToEndOfFile]
		  options:NSPropertyListMutableContainers format:NULL error:NULL]?:
		  [NSMutableDictionary dictionary];
		[config setObject:[NSNumber numberWithBool:YES] forKey:@"runonce"];
		[handle seekToFileOffset:0];
		[handle truncateFileAtOffset:0];
		[handle writeData:[NSPropertyListSerialization 
		  dataWithPropertyList:config
		  format:NSPropertyListBinaryFormat_v1_0
		  options:0 error:NULL]];
		[handle release]; // close file
	}

## **Miscellaneous categories** (LFExtras.h)

Libfinder defines a few categories on NSString, NSNumber, and NSError. See the header file for details.
