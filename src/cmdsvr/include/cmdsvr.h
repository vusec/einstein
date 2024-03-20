#ifndef _UTIL_CMDSVR_H
#define _UTIL_CMDSVR_H

#include "util_def.h"

#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <limits.h>

#include "env.h"
#include "safeio.h"

#define _UTIL_CMDSVR_DEFAULT_FILE         "app.cmd"
#define _UTIL_CMDSVR_DEFAULT_DIR          "/tmp"
#define _UTIL_CMDSVR_NAME_TO_FILE(N)     (N ".cmd")

struct util_cmdsvr_conf_s;

/* Server types. */
typedef enum util_cmdsvr_type_e {
    UTIL_CMDSVR_TYPE_UDS,
    __NUM_UTIL_CMDSVR_TYPES
} util_cmdsvr_type_t;

/* Callbacks. */
typedef enum util_cmdsvr_cb_ret_e {
    UTIL_CMDSVR_CB_RET_OK,
    UTIL_CMDSVR_CB_RET_ACK,
    __NUM_UTIL_CMDSVR_CB_RETS
} util_cmdsvr_cb_ret_t;

typedef util_cmdsvr_cb_ret_t (*util_cmdsvr_cb_t)(
    struct util_cmdsvr_conf_s *conf);

/* Configuration. */
typedef struct util_cmdsvr_req_s {
    /* Request format settings. */
    const char **cmd_strs; /* NULL terminated. */
    size_t min_size;
    size_t max_size;

    /* State. */
    long int cmd;
    char *buff;
    size_t size;
} util_cmdsvr_req_t;

typedef struct util_cmdsvr_conf_s {
    /* Thread settings. */
    pthread_attr_t pthread_attr;
    void *(*pthread_func) (void *);
    int limit_threads;
    int max_threads_allowed;
    volatile int num_startup_requests;

    /* Server type settings. */
    util_cmdsvr_cb_t cb;
    util_cmdsvr_type_t type;
    util_cmdsvr_req_t req;
    char *dir;
    char *file;
    int id;

    /* State. */
    pthread_t pthread_id;
    sigset_t pthread_sigmask;
    int has_pthread_sigmask_set;
    struct sockaddr_un local_sa;
    int num_threads;
    int listen_fd;
    int conn_fd;
} util_cmdsvr_conf_t;

static inline void util_cmdsvr_from_env(util_cmdsvr_conf_t *conf) {
    int max_threads_allowed;

    /* Set defaults. */
    if (!conf->dir) {
        conf->dir = (char*) _UTIL_CMDSVR_DEFAULT_DIR;
    }
    if (!conf->file) {
        conf->file = (char*) _UTIL_CMDSVR_DEFAULT_FILE;
    }

    /* Override defaults from the environment. */
    conf->dir= util_env_parse_str("CMDDIR", conf->dir);
    conf->file= util_env_parse_str("CMDFILE", conf->file);

    max_threads_allowed = util_env_parse_int("CMD_MAX_THREADS",-1);
    if (max_threads_allowed != -1) {
        conf->max_threads_allowed = max_threads_allowed;
        conf->limit_threads = 1;
    }

    conf->num_startup_requests= util_env_parse_int("CMD_STARTUP_REQS",
        conf->num_startup_requests);
}

static inline int util_cmdsvr_parse_req(util_cmdsvr_req_t *req)
{
    int i;
    const char *cmd_str;

    req->cmd = INT_MAX; 
    if (!req->cmd_strs) {
        return 0;
    }
    i=0;
    while((cmd_str=req->cmd_strs[i])) {
        size_t cmd_str_len = strlen(cmd_str);
        if (!strncmp(req->buff, cmd_str, cmd_str_len)) {
            char c = req->buff[cmd_str_len];
            if (c == '\0' || c == '\n' || c == ' ' || c == '\t') {
                req->cmd = i;
                break;
            }
        }
        i++;
    }
    if (req->cmd == INT_MAX) {
        return -1;
    }

    return 0;
}

static void *util_cmdsvr_func(void *conf_arg)
{
    struct sockaddr_un remote_sa;
    size_t local_sz, remote_sz;
    int fd, ret;
    util_cmdsvr_cb_ret_t cb_ret;
    util_cmdsvr_conf_t *conf = (util_cmdsvr_conf_t*) conf_arg;
    util_cmdsvr_req_t *req = &conf->req;

    /* Allocate request buffer. */
    req->buff = (char*) _UTIL_MALLOC(req->max_size+1);
    req->buff[req->max_size] = '\0';
    assert(req->buff && "malloc failed");

    /*
     * Run the command svr.
     */
    conf->listen_fd = util_safeio_socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC,
        0);
    assert(conf->listen_fd != -1 && "safe_socket failed");

    memset(&conf->local_sa, 0, sizeof(conf->local_sa));
    conf->local_sa.sun_family = AF_UNIX;
    snprintf(conf->local_sa.sun_path, UNIX_PATH_MAX, "%s/%s.%d", conf->dir,
        conf->file, conf->id);
    local_sz = SUN_LEN(&conf->local_sa);

    ret = bind(conf->listen_fd, (struct sockaddr*)&conf->local_sa,local_sz);
    assert(ret != -1 && "bind failed");

    ret = listen(conf->listen_fd, INT_MAX);
    assert(ret != -1 && "listen failed");

    ret = _UTIL_PTHREAD_SIGMASK(SIG_SETMASK, &conf->pthread_sigmask, NULL);
    assert(ret == 0 && "pthread_sigmask failed");

    //_UTIL_PRINTF("cmdsvr: ready on %s\n", conf->local_sa.sun_path);
    do {
        remote_sz = sizeof(remote_sa);

        bzero(req->buff, req->max_size);
        if ((conf->conn_fd = util_safeio_accept4(conf->listen_fd,
            (struct sockaddr *)&remote_sa, (socklen_t*) &remote_sz, SOCK_CLOEXEC)) < 0) {
            _UTIL_PRINTF("cmdsvr: Unable to accept ctl connection: %s",
                strerror(errno));
            continue;
        }

        if ((ret = recv(conf->conn_fd, req->buff,
                req->max_size, 0)) < 0) {
            _UTIL_PRINTF("cmdsvr: Unable to receive command: %s\n",
                strerror(errno));
            goto loop_end;
        }
        req->size = ret;

        if (req->size > req->max_size || req->size < req->min_size) {
            _UTIL_PRINTF("cmdsvr: Received incorrect sized request (expected [%zd;%zd], received %zd)\n",
                req->min_size, req->max_size, req->size);
            goto loop_end;
        }

        /* Parse request and invoke callback. */
        if (util_cmdsvr_parse_req(req) < 0) {
            _UTIL_PRINTF("cmdsvr: Received bad request (cmd=%ld)\n", req->cmd);
            goto loop_end;
        }
        cb_ret = conf->cb(conf);

        /*
         * Send back ack if requested.
         */
        if (cb_ret == UTIL_CMDSVR_CB_RET_ACK &&
            send(conf->conn_fd, req->buff, req->size, 0) < 0) {
            _UTIL_PRINTF("cmdsvr: Command ack sending failed: %s\n",
                strerror(errno));
        }

loop_end:
	fd = conf->conn_fd;
        conf->conn_fd = 0;
        close(fd);
        if (conf->num_startup_requests > 0) {
            conf->num_startup_requests--;
        }
    } while(1);

    return NULL;
}

static inline void util_cmdsvr_close_child(util_cmdsvr_conf_t *conf)
{
    util_cmdsvr_req_t *req = &conf->req;

    if (conf->conn_fd) {
        close(conf->conn_fd);
    }
    if (conf->listen_fd) {
        close(conf->listen_fd);
    }
    if (req->buff) {
        _UTIL_FREE(req->buff);
    }
}

static inline void util_cmdsvr_close(util_cmdsvr_conf_t *conf)
{
    void *retval;
    int ret;

    ret = _UTIL_PTHREAD_CANCEL(conf->pthread_id);
    assert(ret == 0);
    ret = _UTIL_PTHREAD_JOIN(conf->pthread_id, &retval);
    assert(ret == 0);

    util_cmdsvr_close_child(conf);
    if (conf->local_sa.sun_path[0]) {
        unlink(conf->local_sa.sun_path);
    }
}

static inline void util_cmdsvr_init(util_cmdsvr_conf_t *conf)
{
    int ret;
    int max_threads_reached;
    util_cmdsvr_req_t *req = &conf->req;

    /* Set default function unless one was provided. */
    if (!conf->pthread_func) {
        conf->pthread_func = util_cmdsvr_func;
    }

    /* Set default sigmask unless one was provided. */
    if (!conf->has_pthread_sigmask_set) {
        sigfillset(&conf->pthread_sigmask);
        sigdelset(&conf->pthread_sigmask, SIGSEGV);
        sigdelset(&conf->pthread_sigmask, SIGABRT);
    }

    /* See if we have already reached the maximum number of threads. */
    max_threads_reached = conf->limit_threads
        && conf->num_threads>=conf->max_threads_allowed;
    if (conf->num_startup_requests == 0 && max_threads_reached) {
        return;
    }

    /* Check configuration. */
    assert(conf->cb);
    assert(conf->type == UTIL_CMDSVR_TYPE_UDS);
    assert(req->max_size > 0);
    if (!req->min_size) {
        req->min_size = 1;
    }

    /* Start cmdsvr thread. */
    ret = _UTIL_PTHREAD_CREATE(&conf->pthread_id, &conf->pthread_attr,
        conf->pthread_func, conf);
    assert(ret == 0 && "pthread_create failed");
    conf->num_threads++;
    if (conf->num_startup_requests == 0) {
        usleep(2000);
    }

    /* Serve startup requests if requested. */
    while (conf->num_startup_requests > 0) {
        usleep(100*1000);
    }
    if (max_threads_reached) {
        util_cmdsvr_close(conf);
    }
}

#endif /* _UTIL_CMDSVR_H */

