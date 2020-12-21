/*
 * lst_primitives.h
 *
 * Primitives of the LittleSmalltalk system
 *
 * ---------------------------------------------------------------
 * Little Smalltalk-G, Version 6
 * 
 * Copyright (C) 1987-2005 by Timothy A. Budd
 * Copyright (C) 2007 by Charles R. Childers
 * Copyright (C) 2005-2007 by Danny Reinhold
 * Copyright (C) 2020 by Gregor Richards
 * 
 * ============================================================================
 * This license applies to the virtual machine and to the initial image of 
 * the Little Smalltalk system and to all files in the Little Smalltalk 
 * packages.
 * ============================================================================
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the "Software"), to deal 
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef LST_PRIMITIVES_H
#define LST_PRIMITIVES_H

#include "memory.h"

#define LITTLE_SMALLTALK_VERSION "Little Smalltalk-G, version 6.0"

extern char **lstArgv;
extern int lstArgc;
extern int lstDebugging;

void lstPrimitivesInit();
void lstPrimitivesRelease();
struct object  *primitive(int primitiveNumber, struct object *args,
                          int *failed);

#if defined(LST_USE_FFI) && 1 == LST_USE_FFI
#include "lst_ffi_primitives.h"
#endif

#if defined(LST_USE_SOCKET) && 1 == LST_USE_SOCKET
void lstSocketInit();
void lstSocketRelease();
struct object  *lstSocketPrimitive(int primitiveNumber, struct object *args,
                          int *failed);
struct object  *lstInetPrimitive(int primitiveNumber, struct object *args,
                          int *failed);
#endif

#endif
