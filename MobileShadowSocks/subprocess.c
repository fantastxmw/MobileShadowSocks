//
//  subprocess.c
//  MobileShadowSocks
//
//  Created by Linus Yang on 13-3-11.
//  Copyright (c) 2013 Linus Yang. All rights reserved.
//

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#define PIPE_READ 0
#define PIPE_WRITE 1
#define BUF_SIZE 1024

#include "subprocess.h"

int run_process(const char *execs, const char **args, const char *input, char **output, int nowait) {
    int pipe_input[2];
    int pipe_output[2];
    int status;
    int wait_result;
    int length;
    int total;
    char *now;
    char *buf;
    pid_t pid;
    
    if (pipe(pipe_input) < 0) {
        fprintf(stderr, "Error: cannot build input pipe\n");
        return 1;
    }
    if (pipe(pipe_output) < 0) {
        fprintf(stderr, "Error: cannot build output pipe\n");
        return 1;
    }
    pid = fork();
    if (pid < 0) {
        close(pipe_input[PIPE_READ]);
        close(pipe_input[PIPE_WRITE]);
        close(pipe_output[PIPE_READ]);
        close(pipe_output[PIPE_WRITE]);
        fprintf(stderr, "Error: cannot fork\n");
    }
    else if (pid == 0) {
        if (dup2(pipe_input[PIPE_READ], STDIN_FILENO) < 0) {
            fprintf(stderr, "Error: cannot redirect stdin pipe\n");
            return 1;
        }
        if (dup2(pipe_output[PIPE_WRITE], STDOUT_FILENO) < 0) {
            fprintf(stderr, "Error: cannot redirect stdout pipe\n");
            return 1;
        }
        if (dup2(pipe_output[PIPE_WRITE], STDERR_FILENO) < 0) {
            fprintf(stderr, "Error: cannot redirect stderr pipe\n");
            return 1;
        }
        close(pipe_input[PIPE_READ]);
        close(pipe_input[PIPE_WRITE]);
        close(pipe_output[PIPE_READ]);
        close(pipe_output[PIPE_WRITE]);
        execv(execs, (char **) args);
        fprintf(stderr, "Error: cannot run subprocess\n");
        exit(1);
    }
    else {
        close(pipe_input[PIPE_READ]);
        close(pipe_output[PIPE_WRITE]);
        if (input)
            write(pipe_input[PIPE_WRITE], input, strlen(input));
        close(pipe_input[PIPE_WRITE]);
        if (!nowait)
            wait_result = waitpid(pid, &status, 0);
        else {
            *output = 0;
            close(pipe_output[PIPE_READ]);
            return 0;
        }
        buf = (char *) malloc(BUF_SIZE);
        now = buf;
        total = 0;
        while ((length = (int) read(pipe_output[PIPE_READ], now, BUF_SIZE - 1)) > 0) {
            total += length;
            buf = (char *) realloc(buf, total + BUF_SIZE - 1);
            now = buf + total;
        }
        *now = 0;
        *output = buf;
        close(pipe_output[PIPE_READ]);
        if (wait_result > 0 && WIFEXITED(status))
            return WEXITSTATUS(status);
        return 0;
    }
    return 1;
}
