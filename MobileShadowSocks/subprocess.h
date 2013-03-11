//
//  subprocess.h
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-11.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#ifndef MobileShadowSocks_subprocess_h
#define MobileShadowSocks_subprocess_h

int run_process(const char *execs, const char **args, const char *input, char **output, int nowait);

#endif
