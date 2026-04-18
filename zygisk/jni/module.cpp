#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <android/log.h>
#include <netdb.h>
#include <arpa/inet.h>
#include "zygisk.hpp"
#include "xhook/xhook.h"

#define TAG  "Zygisk-RmlwkDnsLogger"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

struct android_net_context {
    unsigned app_netid;
    unsigned app_mark;
    unsigned dns_netid;
    unsigned dns_mark;
    uid_t    uid;
    unsigned flags;
    void    *qhook;
};

static char s_pkg[256];
static int  s_log_fd = -1;

static int (*orig_getaddrinfo)(
        const char *, const char *,
        const struct addrinfo *, struct addrinfo **) = nullptr;

static int (*orig_getaddrinfofornet)(
        const char *, const char *, const struct addrinfo *,
        unsigned, unsigned, struct addrinfo **) = nullptr;

static int (*orig_getaddrinfofornetcontext)(
        const char *, const char *, const struct addrinfo *,
        const struct android_net_context *, struct addrinfo **) = nullptr;

static bool skip_node(const char *node) {
    if (!node || !node[0]) return true;
    if (strncmp(node, "127.", 4) == 0) return true;
    static const char *const noise[] = {
        "localhost", "ip6-localhost", "ip6-loopback",
        "0.0.0.0", "::1", "::", nullptr
    };
    for (const char *const *p = noise; *p; ++p)
        if (strcmp(node, *p) == 0) return true;
    return false;
}

static bool addr_is_blocked(const struct addrinfo *res) {
    for (const struct addrinfo *p = res; p; p = p->ai_next) {
        if (!p->ai_addr) continue;

        if (p->ai_family == AF_INET) {
            const uint32_t ip = ntohl(
                reinterpret_cast<const struct sockaddr_in *>(p->ai_addr)->sin_addr.s_addr);
            if (ip == 0u || (ip >> 24) == 0x7Fu) return true;

        } else if (p->ai_family == AF_INET6) {
            const uint8_t *b =
                reinterpret_cast<const struct sockaddr_in6 *>(p->ai_addr)->sin6_addr.s6_addr;

            bool all_zero = true;
            for (int i = 0; i < 16 && all_zero; ++i)
                if (b[i]) all_zero = false;
            if (all_zero) return true;

            bool lo = true;
            for (int i = 0; i < 15 && lo; ++i)
                if (b[i]) lo = false;
            if (lo && b[15] == 1) return true;
        }
    }
    return false;
}

static void check_dns(const char *node, const struct addrinfo *res) {
    if (!node || !res || skip_node(node)) return;
    if (!addr_is_blocked(res)) return;
    if (s_log_fd < 0) return;

    char buf[640];
    int n = snprintf(buf, sizeof(buf), "%s|%s\n", s_pkg[0] ? s_pkg : "unknown", node);
    if (n > 0 && n < (int)sizeof(buf)) {
        write(s_log_fd, buf, n);
    }
}

static int my_getaddrinfo(const char *node, const char *service,
                          const struct addrinfo *hints, struct addrinfo **res) {
    const int r = orig_getaddrinfo(node, service, hints, res);
    if (r == 0 && res && *res) check_dns(node, *res);
    return r;
}

static int my_getaddrinfofornet(const char *node, const char *service,
                                const struct addrinfo *hints,
                                unsigned netid, unsigned mark,
                                struct addrinfo **res) {
    if (!orig_getaddrinfofornet) return my_getaddrinfo(node, service, hints, res);
    const int r = orig_getaddrinfofornet(node, service, hints, netid, mark, res);
    if (r == 0 && res && *res) check_dns(node, *res);
    return r;
}

static int my_getaddrinfofornetcontext(const char *node, const char *service,
                                       const struct addrinfo *hints,
                                       const struct android_net_context *ctx,
                                       struct addrinfo **res) {
    if (!orig_getaddrinfofornetcontext) return my_getaddrinfo(node, service, hints, res);
    const int r = orig_getaddrinfofornetcontext(node, service, hints, ctx, res);
    if (r == 0 && res && *res) check_dns(node, *res);
    return r;
}

static bool install_hooks() {
    xhook_enable_debug(0);

    const char *all = ".*\\.so$";

    if (xhook_register(all, "getaddrinfo",
                        reinterpret_cast<void *>(my_getaddrinfo),
                        reinterpret_cast<void **>(&orig_getaddrinfo)) != 0) {
        LOGE("xhook_register(getaddrinfo) failed");
        return false;
    }

    xhook_register(all, "android_getaddrinfofornet",
                   reinterpret_cast<void *>(my_getaddrinfofornet),
                   reinterpret_cast<void **>(&orig_getaddrinfofornet));
    xhook_register(all, "android_getaddrinfofornetcontext",
                   reinterpret_cast<void *>(my_getaddrinfofornetcontext),
                   reinterpret_cast<void **>(&orig_getaddrinfofornetcontext));

    if (xhook_refresh(0) != 0) {
        LOGE("xhook_refresh failed");
        return false;
    }

    if (!orig_getaddrinfo) {
        LOGE("getaddrinfo not resolved");
        return false;
    }

    return true;
}

static int recv_fd(int sock) {
    char dummy;
    struct iovec iov = { &dummy, 1 };

    char ctrl[CMSG_SPACE(sizeof(int))];
    memset(ctrl, 0, sizeof(ctrl));

    struct msghdr msg = {};
    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = ctrl;
    msg.msg_controllen = sizeof(ctrl);

    if (recvmsg(sock, &msg, 0) < 0) return -1;

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    if (!cmsg || cmsg->cmsg_type != SCM_RIGHTS) return -1;

    int fd;
    memcpy(&fd, CMSG_DATA(cmsg), sizeof(fd));
    return fd;
}

class DnsLoggerModule : public zygisk::ModuleBase {
public:
    void onLoad(zygisk::Api *_api, JNIEnv *_env) override {
        api = _api;
        env = _env;
    }

    void preAppSpecialize(zygisk::AppSpecializeArgs *args) override {
        const auto unload = [this] {
            api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
        };

        const auto uid = static_cast<uint32_t>(args->uid);
        if (uid >= 99000u && uid <= 99999u)                            return unload();
        if (api->getFlags() & zygisk::StateFlag::PROCESS_ON_DENYLIST) return unload();
        if (args->is_child_zygote && *args->is_child_zygote)           return unload();

        const int sock = api->connectCompanion();
        if (sock < 0) return unload();

        uint8_t enabled = 0;
        const bool ok = (read(sock, &enabled, 1) == 1);
        if (!ok || !enabled) {
            close(sock);
            return unload();
        }
        s_log_fd = recv_fd(sock);
        close(sock);

        if (s_log_fd >= 0) {
            int flags = fcntl(s_log_fd, F_GETFL, 0);
            if (flags != -1) fcntl(s_log_fd, F_SETFL, flags | O_NONBLOCK);
        }

        if (s_log_fd < 0) {
            LOGE("failed to receive log fd from companion");
            return unload();
        }

        s_pkg[0] = '\0';
        if (args->nice_name) {
            const char *raw = env->GetStringUTFChars(args->nice_name, nullptr);
            if (raw) {
                strncpy(s_pkg, raw, sizeof(s_pkg) - 1);
                s_pkg[sizeof(s_pkg) - 1] = '\0';
                env->ReleaseStringUTFChars(args->nice_name, raw);
                char *colon = strchr(s_pkg, ':');
                if (colon) *colon = '\0';
            }
        }

        if (!install_hooks()) {
            LOGE("hook install failed for [%s] uid=%u", s_pkg[0] ? s_pkg : "?", uid);
            close(s_log_fd);
            s_log_fd = -1;
            return unload();
        }
    }

private:
    zygisk::Api *api = nullptr;
    JNIEnv      *env = nullptr;
};

static void send_fd(int sock, int fd) {
    char dummy = 0;
    struct iovec iov = { &dummy, 1 };

    char ctrl[CMSG_SPACE(sizeof(int))];
    memset(ctrl, 0, sizeof(ctrl));

    struct msghdr msg = {};
    msg.msg_iov        = &iov;
    msg.msg_iovlen     = 1;
    msg.msg_control    = ctrl;
    msg.msg_controllen = sizeof(ctrl);

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type  = SCM_RIGHTS;
    cmsg->cmsg_len   = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(cmsg), &fd, sizeof(int));

    sendmsg(sock, &msg, 0);
}

/* ── Companion-side pipe relay ──────────────────────────────────
 *
 * Instead of handing apps a raw file fd (which SELinux blocks for
 * untrusted_app writing to adb_data_file), we give them the write-end
 * of a pipe.  A relay thread in the companion (running as root/magisk)
 * reads from the pipe and appends to dns.log.
 *
 * One pipe is shared across all apps.  Writes <= PIPE_BUF (4096 B)
 * are atomic on Linux, and our log lines are well under that limit.
 * ────────────────────────────────────────────────────────────── */

static pthread_mutex_t g_relay_mtx = PTHREAD_MUTEX_INITIALIZER;
static int  g_relay_wfd = -1;   // write-end, sent to apps via send_fd
static bool g_relay_up  = false;

static void *relay_worker(void *arg) {
    int rfd   = static_cast<int *>(arg)[0];
    int logfd = static_cast<int *>(arg)[1];
    free(arg);

    char buf[4097];
    ssize_t n;
    while ((n = read(rfd, buf, sizeof(buf) - 1)) > 0) {
        buf[n] = '\0';
        
        // Copy buffer to parse and print nicely to logcat without breaking original buffer for file I/O
        char log_buf[4097];
        memcpy(log_buf, buf, n + 1);
        char *saveptr = nullptr;
        char *line = strtok_r(log_buf, "\n", &saveptr);
        while (line) {
            char *pipe_pos = strchr(line, '|');
            if (pipe_pos) {
                *pipe_pos = '\0';
                const char *pkg = line;
                const char *domain = pipe_pos + 1;
                __android_log_print(ANDROID_LOG_INFO, TAG, "Domain blocked: %s | Requester Package ID: %s", domain, pkg);
            } else {
                __android_log_print(ANDROID_LOG_INFO, TAG, "%s", line);
            }
            line = strtok_r(nullptr, "\n", &saveptr);
        }

        const char *p = buf;
        ssize_t rem = n;
        while (rem > 0) {
            ssize_t w = write(logfd, p, rem);
            if (w <= 0) break;
            p   += w;
            rem -= w;
        }
    }

    close(rfd);
    close(logfd);

    pthread_mutex_lock(&g_relay_mtx);
    if (g_relay_wfd >= 0) { close(g_relay_wfd); g_relay_wfd = -1; }
    g_relay_up = false;
    pthread_mutex_unlock(&g_relay_mtx);

    return nullptr;
}

/* Lazily start the relay; returns the write-end fd or -1. */
static int ensure_relay() {
    pthread_mutex_lock(&g_relay_mtx);

    if (g_relay_up && g_relay_wfd >= 0) {
        int fd = g_relay_wfd;
        pthread_mutex_unlock(&g_relay_mtx);
        return fd;
    }

    /* make sure the log directory exists */
    mkdir("/data/adb/Re-Malwack/logs", 0755);

    int logfd = open("/data/adb/Re-Malwack/logs/dns.log",
                     O_WRONLY | O_CREAT | O_APPEND, 0666);
    if (logfd < 0) {
        LOGE("relay: cannot open dns.log (%d)", errno);
        pthread_mutex_unlock(&g_relay_mtx);
        return -1;
    }

    int pfd[2];
    if (pipe(pfd) < 0) {
        LOGE("relay: pipe() failed (%d)", errno);
        close(logfd);
        pthread_mutex_unlock(&g_relay_mtx);
        return -1;
    }

    int *args = static_cast<int *>(malloc(2 * sizeof(int)));
    args[0] = pfd[0];   // read-end  → relay thread
    args[1] = logfd;     // log file  → relay thread

    pthread_t t;
    if (pthread_create(&t, nullptr, relay_worker, args) != 0) {
        LOGE("relay: pthread_create failed (%d)", errno);
        free(args);
        close(pfd[0]);
        close(pfd[1]);
        close(logfd);
        pthread_mutex_unlock(&g_relay_mtx);
        return -1;
    }
    pthread_detach(t);

    g_relay_wfd = pfd[1];
    g_relay_up  = true;

    __android_log_print(ANDROID_LOG_INFO, TAG, "relay: started (pipe w=%d, log fd=%d)", pfd[1], logfd);
    pthread_mutex_unlock(&g_relay_mtx);
    return pfd[1];
}

static void companion_handler(int client) {
    uint8_t enabled = 0;

    FILE *cfg = fopen("/data/adb/Re-Malwack/config.sh", "r");
    if (cfg) {
        char line[256];
        while (fgets(line, sizeof(line), cfg)) {
            const char *p = line;
            while (*p == ' ' || *p == '\t') ++p;
            if (*p == '#' || *p == '\0') continue;
            if (strncmp(p, "dns_logging=1", 13) == 0 &&
                (p[13] == '\n' || p[13] == '\r' || p[13] == '\0')) {
                enabled = 1;
                break;
            }
        }
        fclose(cfg);
    }

    write(client, &enabled, 1);

    if (enabled) {
        int wfd = ensure_relay();
        if (wfd >= 0) {
            send_fd(client, wfd);
        }
    }

    close(client);
}

REGISTER_ZYGISK_MODULE(DnsLoggerModule)
REGISTER_ZYGISK_COMPANION(companion_handler)