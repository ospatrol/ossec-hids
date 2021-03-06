/* @(#) $Id: ./src/headers/string_op.h, 2011/09/08 dcid Exp $
 */

/* Copyright (C) 2009 Trend Micro Inc.
 * All rights reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation
 *
 * License details at the LICENSE file included with OSPatrol
 */


#ifndef H_STRINGOP_OS
#define H_STRINGOP_OS


/** os_trimcrlf
 * Trims the cr and/or LF from the last positions of a string
 */
void os_trimcrlf(char *str);

/* Similiar to Perl's substr() function */
int os_substr(char *dest, const char *src, int position, int length);

/* Remove a character from a string */
char *os_strip_char(char *source, char remove);

#endif

/* EOF */
