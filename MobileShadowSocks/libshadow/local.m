#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <locale.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <time.h>
#include <unistd.h>
#include <assert.h>
#include <launch.h>
#include <Foundation/Foundation.h>

#include "local.h"
#include "socks5.h"
#include "Constant.h"
#include "build_time.h"

#ifndef EAGAIN
#define EAGAIN EWOULDBLOCK
#endif

#ifndef EWOULDBLOCK
#define EWOULDBLOCK EAGAIN
#endif

#define min(a,b) (((a)<(b))?(a):(b))

static char *_server;
static char *_remote_port;
static int   _timeout;
static char *_key;
static ev_timer _local_timer;
static int _local_timeout;

int setnonblocking(int fd) {
    int flags;
    if (-1 ==(flags = fcntl(fd, F_GETFL, 0)))
        flags = 0;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int create_and_bind(int local_port) {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s, listen_sock;
    char port[30];

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC; /* Return IPv4 and IPv6 choices */
    hints.ai_socktype = SOCK_STREAM; /* We want a TCP socket */

    sprintf(port, "%d", local_port);
    s = getaddrinfo("127.0.0.1", port, &hints, &result);
    if (s != 0) {
        LOGD("getaddrinfo: %s\n", gai_strerror(s));
        return -1;
    }

    for (rp = result; rp != NULL; rp = rp->ai_next) {
        listen_sock = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (listen_sock == -1)
            continue;

        int opt = 1;
        int err = setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
        if (err) {
            perror("setsocket");
        }

        s = bind(listen_sock, rp->ai_addr, rp->ai_addrlen);
        if (s == 0) {
            /* We managed to bind successfully! */
            break;
        } else {
            perror("bind");
        }

        close(listen_sock);
    }

    if (rp == NULL) {
        LOGE("Could not bind\n");
        return -1;
    }

    freeaddrinfo(result);

    return listen_sock;
}

static void server_recv_cb (EV_P_ ev_io *w, int revents) {
    struct server_ctx *server_recv_ctx = (struct server_ctx *)w;
    struct server *server = server_recv_ctx->server;
    struct remote *remote = server->remote;

    if (remote == NULL) {
        close_and_free_server(EV_A_ server);
        return;
    }
    while (1) {
        char *buf = remote->buf;
        int *buf_len = &remote->buf_len;
        if (server->stage != 5) {
            buf = server->buf;
            buf_len = &server->buf_len;
        }

        ssize_t r = recv(server->fd, buf, BUF_SIZE, 0);

        if (r == 0) {
            // connection closed
            *buf_len = 0;
            close_and_free_remote(EV_A_ remote);
            close_and_free_server(EV_A_ server);
            return;
        } else if(r < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // no data
                // continue to wait for recv
                break;
            } else {
                perror("server recv");
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }
        }

        // local socks5 server
        if (server->stage == 5) {
            encrypt_ctx(remote->buf, r, server->e_ctx);
            int w = send(remote->fd, remote->buf, r, 0);
            if(w == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    // no data, wait for send
                    remote->buf_len = r;
                    ev_io_stop(EV_A_ &server_recv_ctx->io);
                    ev_io_start(EV_A_ &remote->send_ctx->io);
                    break;
                } else {
                    perror("send");
                    close_and_free_remote(EV_A_ remote);
                    close_and_free_server(EV_A_ server);
                    return;
                }
            } else if(w < r) {
                char *pt = remote->buf;
                char *et = pt + r;
                while (pt + w < et) {
                    *pt = *(pt + w);
                    pt++;
                }
                remote->buf_len = r - w;
                assert(remote->buf_len >= 0);
                ev_io_stop(EV_A_ &server_recv_ctx->io);
                ev_io_start(EV_A_ &remote->send_ctx->io);
                break;
            }
        } else if (server->stage == 0) {
            struct method_select_response response;
            response.ver = SVERSION;
            response.method = 0;
            char *send_buf = (char *)&response;
            send(server->fd, send_buf, sizeof(response), 0);
            server->stage = 1;
            return;
        } else if (server->stage == 1) {
            struct socks5_request *request = (struct socks5_request *)server->buf;

            if (request->cmd != 1) {
                LOGE("unsupported cmd: %d\n", request->cmd);
                struct socks5_response response;
                response.ver = SVERSION;
                response.rep = CMD_NOT_SUPPORTED;
                response.rsv = 0;
                response.atyp = 1;
                char *send_buf = (char *)&response;
                send(server->fd, send_buf, 4, 0);
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }

            char addr_to_send[256];
            unsigned char addr_len = 0;
            addr_to_send[addr_len++] = request->atyp;

            // get remote addr and port
            if (request->atyp == 1) {

                // IP V4
                size_t in_addr_len = sizeof(struct in_addr);
                memcpy(addr_to_send + addr_len, server->buf + 4, in_addr_len + 2);
                addr_len += in_addr_len + 2;

            } else if (request->atyp == 3) {
                // Domain name
                unsigned char name_len = *(unsigned char *)(server->buf + 4);
                addr_to_send[addr_len++] = name_len;
                memcpy(addr_to_send + addr_len, server->buf + 4 + 1, name_len);
                addr_len += name_len;

                // get port
                addr_to_send[addr_len++] = *(unsigned char *)(server->buf + 4 + 1 + name_len); 
                addr_to_send[addr_len++] = *(unsigned char *)(server->buf + 4 + 1 + name_len + 1); 
            } else {
                LOGE("unsupported addrtype: %d\n", request->atyp);
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }

            encrypt_ctx(addr_to_send, addr_len, server->e_ctx);
            send(remote->fd, addr_to_send, addr_len, 0);

            // Fake reply
            struct socks5_response response;
            response.ver = SVERSION;
            response.rep = 0;
            response.rsv = 0;
            response.atyp = 1;

            struct in_addr sin_addr;
            inet_aton("0.0.0.0", &sin_addr);

            memcpy(server->buf, &response, 4);
            memcpy(server->buf + 4, &sin_addr, sizeof(struct in_addr));
            *((unsigned short *)(server->buf + 4 + sizeof(struct in_addr))) 
                = (unsigned short) htons(atoi(_remote_port));

            int reply_size = 4 + sizeof(struct in_addr) + sizeof(unsigned short);
            int r = send(server->fd, server->buf, reply_size, 0);
            if (r < reply_size) {
                LOGE("header not complete sent\n");
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }

            server->stage = 5;
        }
    }
}

static void server_send_cb (EV_P_ ev_io *w, int revents) {
    struct server_ctx *server_send_ctx = (struct server_ctx *)w;
    struct server *server = server_send_ctx->server;
    struct remote *remote = server->remote;
    if (server->buf_len == 0) {
        // close and free
        close_and_free_remote(EV_A_ remote);
        close_and_free_server(EV_A_ server);
        return;
    } else {
        // has data to send
        ssize_t r = send(server->fd, server->buf,
                server->buf_len, 0);
        if (r < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                perror("send");
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
            }
            return;
        }
        if (r < server->buf_len) {
            // partly sent, move memory, wait for the next time to send
            char *pt = server->buf;
            char *et = pt + server->buf_len;
            while (pt + r < et) {
                *pt = *(pt + r);
                pt++;
            }
            server->buf_len -= r;
            assert(server->buf_len >= 0);
            return;
        } else {
            // all sent out, wait for reading
            ev_io_stop(EV_A_ &server_send_ctx->io);
            if (remote != NULL) {
                ev_io_start(EV_A_ &remote->recv_ctx->io);
            } else {
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }
        }
    }
}

static void listen_timeout_cb(EV_P_ ev_timer *watcher, int revents) {
    LOGD("Service timeout, exit\n");
    ev_unloop (EV_A_ EVUNLOOP_ALL);
}

static void remote_timeout_cb(EV_P_ ev_timer *watcher, int revents) {
    struct remote_ctx *remote_ctx = (struct remote_ctx *) (((void*)watcher)
            - sizeof(ev_io));
    struct remote *remote = remote_ctx->remote;
    struct server *server = remote->server;

    LOGD("Remote timeout, disconnect\n");

    ev_timer_stop(EV_A_ watcher);

    if (server == NULL) {
        close_and_free_remote(EV_A_ remote);
        return;
    }
    close_and_free_remote(EV_A_ remote);
    close_and_free_server(EV_A_ server);
}

static void remote_recv_cb (EV_P_ ev_io *w, int revents) {
    struct remote_ctx *remote_recv_ctx = (struct remote_ctx *)w;
    struct remote *remote = remote_recv_ctx->remote;
    struct server *server = remote->server;
    if (server == NULL) {
        close_and_free_remote(EV_A_ remote);
        return;
    }
    while (1) {
        ssize_t r = recv(remote->fd, server->buf, BUF_SIZE, 0);

        if (r == 0) {
            // connection closed
            server->buf_len = 0;
            close_and_free_remote(EV_A_ remote);
            close_and_free_server(EV_A_ server);
            return;
        } else if(r < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // no data
                // continue to wait for recv
                break;
            } else {
                perror("remote recv");
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }
        }
        decrypt_ctx(server->buf, r, server->d_ctx);
        int w = send(server->fd, server->buf, r, 0);
        if(w == -1) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // no data, wait for send
                server->buf_len = r;
                ev_io_stop(EV_A_ &remote_recv_ctx->io);
                ev_io_start(EV_A_ &server->send_ctx->io);
                break;
            } else {
                perror("send");
                close_and_free_remote(EV_A_ remote);
                close_and_free_server(EV_A_ server);
                return;
            }
        } else if(w < r) {
            char *pt = server->buf;
            char *et = pt + r;
            while (pt + w < et) {
                *pt = *(pt + w);
                pt++;
            }
            server->buf_len = r - w;
            assert(server->buf_len >= 0);
            ev_io_stop(EV_A_ &remote_recv_ctx->io);
            ev_io_start(EV_A_ &server->send_ctx->io);
            break;
        }
    }
}

static void remote_send_cb (EV_P_ ev_io *w, int revents) {
    struct remote_ctx *remote_send_ctx = (struct remote_ctx *)w;
    struct remote *remote = remote_send_ctx->remote;
    struct server *server = remote->server;

    if (!remote_send_ctx->connected) {

        struct sockaddr_storage addr;
        socklen_t len = sizeof addr;
        int r = getpeername(remote->fd, (struct sockaddr*)&addr, &len);
        if (r == 0) {
            remote_send_ctx->connected = 1;
            ev_io_stop(EV_A_ &remote_send_ctx->io);
            ev_timer_stop(EV_A_ &remote_send_ctx->watcher);
            ev_io_start(EV_A_ &server->recv_ctx->io);
            ev_io_start(EV_A_ &remote->recv_ctx->io);
            return;
        } else {
            perror("getpeername");
            // not connected
            close_and_free_remote(EV_A_ remote);
            close_and_free_server(EV_A_ server);
            return;
        }
    } else {
        if (remote->buf_len == 0) {
            // close and free
            close_and_free_remote(EV_A_ remote);
            close_and_free_server(EV_A_ server);
            return;
        } else {
            // has data to send
            ssize_t r = send(remote->fd, remote->buf,
                    remote->buf_len, 0);
            if (r < 0) {
                if (errno != EAGAIN && errno != EWOULDBLOCK) {
                    perror("send");
                    // close and free
                    close_and_free_remote(EV_A_ remote);
                    close_and_free_server(EV_A_ server);
                }
                return;
            }
            if (r < remote->buf_len) {
                // partly sent, move memory, wait for the next time to send
                char *pt = remote->buf;
                char *et = pt + remote->buf_len;
                while (pt + r < et) {
                    *pt = *(pt + r);
                    pt++;
                }
                remote->buf_len -= r;
                assert(remote->buf_len >= 0);
                return;
            } else {
                // all sent out, wait for reading
                ev_io_stop(EV_A_ &remote_send_ctx->io);
                if (server != NULL) {
                    ev_io_start(EV_A_ &server->recv_ctx->io);
                } else {
                    close_and_free_remote(EV_A_ remote);
                    close_and_free_server(EV_A_ server);
                    return;
                }
            }
        }

    }
}

struct remote* new_remote(int fd) {
    struct remote *remote;
    remote = malloc(sizeof(struct remote));
    remote->recv_ctx = malloc(sizeof(struct remote_ctx));
    remote->send_ctx = malloc(sizeof(struct remote_ctx));
    remote->fd = fd;
    ev_io_init(&remote->recv_ctx->io, remote_recv_cb, fd, EV_READ);
    ev_io_init(&remote->send_ctx->io, remote_send_cb, fd, EV_WRITE);
    ev_timer_init(&remote->send_ctx->watcher, remote_timeout_cb, _timeout, 0);
    remote->recv_ctx->remote = remote;
    remote->recv_ctx->connected = 0;
    remote->send_ctx->remote = remote;
    remote->send_ctx->connected = 0;
    remote->buf_len = 0;
    return remote;
}

void free_remote(struct remote *remote) {
    if (remote != NULL) {
        if (remote->server != NULL) {
            remote->server->remote = NULL;
        }
        free(remote->recv_ctx);
        free(remote->send_ctx);
        free(remote);
    }
}

void close_and_free_remote(EV_P_ struct remote *remote) {
    if (remote != NULL) {
        ev_timer_stop(EV_A_ &remote->send_ctx->watcher);
        ev_io_stop(EV_A_ &remote->send_ctx->io);
        ev_io_stop(EV_A_ &remote->recv_ctx->io);
        close(remote->fd);
        free_remote(remote);
    }
}
struct server* new_server(int fd) {
    struct server *server;
    server = malloc(sizeof(struct server));
    server->recv_ctx = malloc(sizeof(struct server_ctx));
    server->send_ctx = malloc(sizeof(struct server_ctx));
    server->fd = fd;
    ev_io_init(&server->recv_ctx->io, server_recv_cb, fd, EV_READ);
    ev_io_init(&server->send_ctx->io, server_send_cb, fd, EV_WRITE);
    server->recv_ctx->server = server;
    server->recv_ctx->connected = 0;
    server->send_ctx->server = server;
    server->send_ctx->connected = 0;
    server->stage = 0;
    if (_method == RC4) {
        server->e_ctx = malloc(sizeof(struct rc4_state));
        server->d_ctx = malloc(sizeof(struct rc4_state));
        enc_ctx_init(server->e_ctx, 1);
        enc_ctx_init(server->d_ctx, 0);
    } else {
        server->e_ctx = NULL;
        server->d_ctx = NULL;
    }
    server->buf_len = 0;
    return server;
}
void free_server(struct server *server) {
    if (server != NULL) {
        if (server->remote != NULL) {
            server->remote->server = NULL;
        }
        if (_method == RC4) {
            free(server->e_ctx);
            free(server->d_ctx);
        }
        free(server->recv_ctx);
        free(server->send_ctx);
        free(server);
    }
}
void close_and_free_server(EV_P_ struct server *server) {
    if (server != NULL) {
        ev_io_stop(EV_A_ &server->send_ctx->io);
        ev_io_stop(EV_A_ &server->recv_ctx->io);
        close(server->fd);
        free_server(server);
    }
}
static void accept_cb (EV_P_ ev_io *w, int revents)
{
    struct listen_ctx *listener = (struct listen_ctx *)w;
    int serverfd;
    while (1) {
        serverfd = accept(listener->fd, NULL, NULL);
        if (serverfd == -1) {
            perror("accept");
            break;
        }
        ev_timer_again(EV_A_ &_local_timer);
        setnonblocking(serverfd);
        struct server *server = new_server(serverfd);
        struct addrinfo hints, *res;
        int sockfd;
        memset(&hints, 0, sizeof hints);
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        int err = getaddrinfo(_server, _remote_port, &hints, &res);
        if (err) {
            perror("getaddrinfo");
            close_and_free_server(EV_A_ server);
            break;
        }

        sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (sockfd < 0) {
            perror("socket");
            close(sockfd);
            close_and_free_server(EV_A_ server);
            freeaddrinfo(res);
            break;
        }

        struct timeval timeout;
        timeout.tv_sec = _timeout;
        timeout.tv_usec = 0;
        err = setsockopt(sockfd, SOL_SOCKET, 
                SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
        if (err) perror("setsockopt");
        err = setsockopt(sockfd, SOL_SOCKET,
                SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));
        if (err) perror("setsockopt");

        setnonblocking(sockfd);
        struct remote *remote = new_remote(sockfd);
        server->remote = remote;
        remote->server = server;
        connect(sockfd, res->ai_addr, res->ai_addrlen);
        freeaddrinfo(res);
        // listen to remote connected event
        ev_io_start(EV_A_ &remote->send_ctx->io);
        ev_timer_start(EV_A_ &remote->send_ctx->watcher);
        break;
    }
}

int get_pac_content(char **content) {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
    *content = 0;
    if (dict && [[dict objectForKey:@"AUTO_PROXY"] boolValue]) {
        NSString *filePath = [(NSString *) [dict objectForKey:@"PAC_FILE"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            const char *file_str = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil]cStringUsingEncoding:NSUTF8StringEncoding];
            if (file_str) {
                *content = strdup(file_str);
                [pool release];
                return 1;
            }
        }
    }
    [pool release];
    return 0;
}

static void pac_accept_cb (EV_P_ ev_io *w, int revents) {
    struct listen_ctx *listener = (struct listen_ctx *)w;
    int serverfd;
    int will_update;
    FILE *stream;
    char *pac_file;
    struct sockaddr_in client;
    socklen_t socksize;
    char buf[BUFF_SIZE];
    while (1) {
        memset(&client, 0, sizeof(client));
        memset(&buf, 0, sizeof(buf));
        socksize = sizeof(struct sockaddr_in);
        serverfd = accept(listener->fd, (struct sockaddr *) &client, &socksize);
        if (serverfd == -1) {
            perror("accept");
            break;
        }
        ev_timer_again(EV_A_ &_local_timer);
        setnonblocking(serverfd);
        if (!(stream = fdopen(serverfd, "r+"))) {
            perror("fdopen");
            break;
        }
        will_update = 0;
        do {
            fgets(buf, BUFF_SIZE, stream);
            if (strstr(buf, UPDATE_CONF))
                will_update = 1;
        } while (strcmp(buf, "\r\n") && strcmp(buf, "\n"));
        fprintf(stream, HTTP_RESPONSE);
        if (will_update) {
            update_config();
            fprintf(stream, "Updated.\n");
        }
        else {
            if (get_pac_content(&pac_file)) {
                fprintf(stream, "%s", pac_file);
                free(pac_file);
            }
            else
                fprintf(stream, EMPTY_PAC, LOCAL_PORT);
        }
        fflush(stream);
        fclose(stream);
        close(serverfd);
        break;
    }
}

int store_config(char ** config_ptr, const char *new_config, const char *default_value) {
    int changed = 0;
    if (!*config_ptr) {
        *config_ptr = strdup(default_value);
        changed = 1;
    }
    if (new_config) {
        if (strcmp(*config_ptr, new_config)) {
            free(*config_ptr);
            *config_ptr = strdup(new_config);
            changed = 1;
        }
    }
    return changed;
}

void update_config() {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_FILE];
    NSString *remoteServer = [prefDict objectForKey:@"REMOTE_SERVER"];
    NSString *remotePort = [prefDict objectForKey:@"REMOTE_PORT"];
    NSString *socksPass = [prefDict objectForKey:@"SOCKS_PASS"];
    BOOL useCrypto = [[prefDict objectForKey:@"USE_RC4"] boolValue];
    store_config(&_server, [remoteServer cStringUsingEncoding:NSUTF8StringEncoding], "127.0.0.1");
    store_config(&_remote_port, [remotePort cStringUsingEncoding:NSUTF8StringEncoding], "8080");
    int key_changed = store_config(&_key, [socksPass cStringUsingEncoding:NSUTF8StringEncoding], "123456");
    int new_method = useCrypto ? RC4 : TABLE;
    if (key_changed || new_method != _method) {
        _method = new_method;
        LOGD("Using cipher:\t%s\n", _method == RC4 ? "RC4" : "Non-RC4");
        if (_method == RC4)
            enc_key_init(_key);
        else
            get_table(_key);
    }
    LOGD("Remote server:\t%s:%s\n", _server, _remote_port);
    [pool release];
}

int main (int argc, const char **argv) {
    _server = 0;
    _remote_port = 0;
    _method = TABLE;
    _key = 0;
    _timeout = 0;
    _local_timeout = 0;
    
    int launchd_mode = 0;
    if (argc > 1) {
        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-d") == 0)
                launchd_mode = 1;
            else if (isdigit(argv[i][0])) {
                if (!_timeout)
                    _timeout = atoi(argv[i]);
                if (!_local_timeout)
                    _local_timeout = atoi(argv[i]);
            }
        }
    }
    if (_timeout <= 0)
        _timeout = REMOTE_TIMEOUT;
    if (_local_timeout <= 0)
        _local_timeout = LOCAL_TIMEOUT;
    LOGD("ShadowSocks-libev (Build %s)\n", BUILDTIME);
    update_config();
    LOGD("Exit no action:\t%ds\n", _local_timeout);
    LOGD("Remote timeout:\t%ds\n", _timeout);

    signal(SIGPIPE, SIG_IGN);
    struct listen_ctx local_ctx;
    struct listen_ctx pac_ctx;
    if (launchd_mode) {
        launch_data_t sockets_dict;
        launch_data_t checkin_response;
        launch_data_t checkin_request;
        launch_data_t the_label;
        launch_data_t listening_fd_array;
        launch_data_t this_listening_fd;

        // check-in launchd service
        if ((checkin_request = launch_data_new_string(LAUNCH_KEY_CHECKIN)) == NULL) {
            LOGE("launch_data_new_string error\n");
            return 1;
        }
        if ((checkin_response = launch_msg(checkin_request)) == NULL) {
            LOGE("launch_msg error\n");
            return 1;
        }
        if (LAUNCH_DATA_ERRNO == launch_data_get_type(checkin_response)) {
            LOGE("check-in failed\n");
            return 1;
        }
        the_label = launch_data_dict_lookup(checkin_response, LAUNCH_JOBKEY_LABEL);
        if (NULL == the_label) {
            LOGE("no label found\n");
            return 1;
        }
        sockets_dict = launch_data_dict_lookup(checkin_response, LAUNCH_JOBKEY_SOCKETS);
        if (NULL == sockets_dict) {
            LOGE("no sockets found to answer requests on\n");
            return 1;
        }

        // get socks server file descriptor from launchd
        listening_fd_array = launch_data_dict_lookup(sockets_dict, LAUNCHD_NAME_SOCKS);
        if (NULL == listening_fd_array) {
            LOGE("no socks entry found in plist\n");
            return 1;
        }
        this_listening_fd = launch_data_array_get_index(listening_fd_array, 0);
        local_ctx.fd = launch_data_get_fd(this_listening_fd);
        if (local_ctx.fd == -1) {
            LOGE("failed to get socks fd\n");
            return 1;
        }

        // get pac file server file descriptor from launchd
        listening_fd_array = launch_data_dict_lookup(sockets_dict, LAUNCHD_NAME_PAC);
        if (NULL == listening_fd_array) {
            LOGE("no pac entry found in plist\n");
            return 1;
        }
        this_listening_fd = launch_data_array_get_index(listening_fd_array, 0);
        pac_ctx.fd = launch_data_get_fd(this_listening_fd);
        if (pac_ctx.fd == -1) {
            LOGE("failed to get pac fd\n");
            return 1;
        }

        launch_data_free(checkin_response);
        launch_data_free(checkin_request);
    }
    else {
        int listenfd;

        // get socks server file descriptor
        listenfd = create_and_bind(LOCAL_PORT);
        if (listenfd < 0) {
            LOGE("bind() error\n");
            return 1;
        }
        if (listen(listenfd, SOMAXCONN) == -1) {
            LOGE("listen() error\n");
            return 1;
        }
        setnonblocking(listenfd);
        local_ctx.fd = listenfd;

        // get pac file server file descriptor
        listenfd = create_and_bind(PAC_PORT);
        if (listenfd < 0) {
            LOGE("bind() error\n");
            return 1;
        }
        if (listen(listenfd, SOMAXCONN) == -1) {
            LOGE("listen() error\n");
            return 1;
        }
        setnonblocking(listenfd);
        pac_ctx.fd = listenfd;
    }
    
    struct ev_loop *loop = ev_default_loop(0);
    if (!loop) {
        LOGE("Fatal error: libev loop failed");
        return 1;
    }
    LOGD("Socks server:\t127.0.0.1:%d\n", LOCAL_PORT);
    LOGD("Pac httpd:\t127.0.0.1:%d\n", PAC_PORT);
    ev_io_init(&local_ctx.io, accept_cb, local_ctx.fd, EV_READ);
    ev_io_start(EV_A_ &local_ctx.io);
    ev_io_init(&pac_ctx.io, pac_accept_cb, pac_ctx.fd, EV_READ);
    ev_io_start(EV_A_ &pac_ctx.io);
    ev_timer_init(&_local_timer, listen_timeout_cb, 0, _local_timeout);
    ev_timer_again(EV_A_ &_local_timer);
    LOGD("Service running...\n");
    ev_run(loop, 0);
    return 0;
}
