# Makefile for OSPatrol
# Daniel B. Cid <daniel.cid@gmail.com>||<daniel@underlinux.com.br>
# http://ospatrol.com

PT=../
NAME=ospatrol-agentd

include ../Config.Make


clog_OBJS = *.c ${OS_CONFIG} ${OS_ZLIB} ${OS_CRYPTO} ${OS_SHARED} ${OS_XML} ${OS_REGEX} ${OS_NET} -DCLIENT

agent:
		$(CC) $(CFLAGS) ${OS_LINK} $(clog_OBJS) -o ${NAME}
clean:
		${CLEAN}
build:
		${BUILD}
