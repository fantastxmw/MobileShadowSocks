/*
 C API to launchctl functions.
 
 Initial version is based on launchctl 106.20, current as of Mac OS X 10.4.9.
 http://www.opensource.apple.com/darwinsource/
 
 Additions/changes to make the code into an API by Tom Harrington, tph@atomicbird.com
 
 */
#include <CoreFoundation/CoreFoundation.h>

int launchctl_load_path(CFStringRef plistPath, bool writeFlag, bool forceFlag);
int launchctl_unload_path(CFStringRef plistPath, bool writeFlag);

int launchctl_start(CFStringRef jobLabel);
int launchctl_stop(CFStringRef jobLabel);

CFArrayRef launchctl_list();

int launchctl_setenv(CFStringRef key, CFStringRef value);
int launchctl_unsetenv(CFStringRef key);
CFDictionaryRef launchctl_export();
CFStringRef launchctl_getenv(CFStringRef key);
/*
 launchctl functions not yet implemented:
 getrusage self|children
 log[level loglevel] [only| mask loglevels...]
 limit [cpu | filesize | data | stack | core | rss | memlock | maxproc | 
	 maxfiles] [both [soft| hard]]
 stdout path
 stderr path
 shutdown
 reloadttys
 umask [newmask]
 */