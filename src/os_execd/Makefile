# Makefile for execd
# Daniel B. Cid <daniel.cid@gmail.com>||<daniel@underlinux.com.br>

PT=../
NAME=ospatrol-execd

include ../Config.Make

LOCAL = execd.c exec.c config.c

OBJS = ${OS_SHARED} ${OS_NET} ${OS_REGEX} ${OS_XML}

addclient:
		${CC} ${CFLAGS} ${OS_LINK} ${LOCAL} ${OBJS} -o ${NAME}
		${CC} ${CFLAGS} -c ${LOCAL}
clean:
		${CLEAN}
build:
		${BUILD}
