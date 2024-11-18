#ifndef _TYPES_H_
#define _TYPES_H_

#include <stddef.h>

#define TRUE 1
#define FALSE 0

typedef unsigned char uchar;
typedef unsigned int uint;
typedef unsigned int size_t;
typedef unsigned short ushort;
typedef unsigned char bool;
typedef unsigned long ulong;

#define MIN(a,b) (a < b ? a : b)
#define MAX(a,b) (a > b ? a : b)

#include <stdio.h>
#define DEBUG(...) printf(__VA_ARGS__)
#define DBGBRK { char* d = 0xfffd; *d = (char) 0; }

#endif