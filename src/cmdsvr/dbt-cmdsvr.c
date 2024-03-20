/* Command server definitions. */
#define dbt_cmdsvr_conf() (&dbt_cmdsvr_conf_buff)
typedef enum dbt_cmdsvr_cmd_e {
    DBT_CMDSVR_CMD_DUMP,
    DBT_CMDSVR_CMD_TAINTALL,
    DBT_CMDSVR_CMD_SETDEBUGSTR,
    __NUM_DBT_CMDSVR_CMDS
} dbt_cmdsvr_cmd_t;

#define DBT_CMDSVR_CMD_STRS \
    "dump", "taintall", "setdebugstr", \
    NULL

#include <pthread.h>
#include <stdio.h>
#include <assert.h>
#include <cmdsvr.h>

util_cmdsvr_conf_t dbt_cmdsvr_conf_buff;

/* Command server functions. */
__attribute__((noinline)) void __libdft_cmd(int cmd, void *arg1)
{
    assert(cmd >= 0 && cmd < __NUM_DBT_CMDSVR_CMDS);
    asm("");
}

static util_cmdsvr_cb_ret_t dbt_cmdsvr_cb(util_cmdsvr_conf_t *conf)
{
    int cmd_num = conf->req.cmd;
    const char * cmd_str = conf->req.cmd_strs[cmd_num];
    size_t cmd_str_len = strlen(cmd_str);
    size_t next_arg_i = cmd_str_len;
    while (conf->req.buff[next_arg_i] == ' ' || conf->req.buff[next_arg_i] == '\t') next_arg_i++;
    char * arg_str = &conf->req.buff[next_arg_i];
    //_UTIL_PRINTF("dbt_cmdsvr_cb: Calling __libdft_cmd with cmd=%d and arg_str='%s'\n", cmd_num, arg_str);
    __libdft_cmd(conf->req.cmd, arg_str);
    return UTIL_CMDSVR_CB_RET_OK;
}

static void dbt_cmdsvr_init()
{
    static const char *dbt_cmdsvr_cmd_strs[] = { DBT_CMDSVR_CMD_STRS };
    util_cmdsvr_conf_t *cmdsvr_conf = dbt_cmdsvr_conf();

    cmdsvr_conf->file = (char*) _UTIL_CMDSVR_NAME_TO_FILE("dbt");
    util_cmdsvr_from_env(cmdsvr_conf);

    cmdsvr_conf->cb = dbt_cmdsvr_cb;
    cmdsvr_conf->id = getpid();
    cmdsvr_conf->req.cmd_strs = dbt_cmdsvr_cmd_strs;
    cmdsvr_conf->req.max_size = 1000;
    if (pthread_attr_init(&cmdsvr_conf->pthread_attr) != 0) { _UTIL_PRINTF("Error calling pthread_attr_init()!\n"); return; }
    util_cmdsvr_init(cmdsvr_conf);
}

static void dbt_cmdsvr_close()
{
    util_cmdsvr_close(dbt_cmdsvr_conf());
}

/* Event handlers. */
void dbt_cmdsvr_atfork_child()
{
    util_cmdsvr_close_child(dbt_cmdsvr_conf());
    dbt_cmdsvr_init();
}

void dbt_cmdsvr_atexit()
{
    dbt_cmdsvr_close();
}

void dbt_cmdsvr_atexec()
{
    dbt_cmdsvr_close();
}

void dbt_cmdsvr_atinit()
{
    dbt_cmdsvr_init();
}

/* Constructor. */
__attribute__((constructor)) void dbt_cmdsvr_constructor()
{
    dbt_cmdsvr_atinit();
    atexit(&dbt_cmdsvr_atexit);
    pthread_atfork(NULL, NULL, dbt_cmdsvr_atfork_child);
}
