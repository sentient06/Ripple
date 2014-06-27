//
//  Output.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__Output__
#define __RipplePrototype__Output__

#include <iostream>

class Output {
    static const char red[11];
    static const char gre[11];
    static const char yel[11];
    static const char blu[11];
    static const char pur[11];
    static const char cya[11];
    static const char ncl[11];
public:
    void puts(const char msg[]);
    void error(const char msg[]);
    void warning(const char msg[]);
    void success(const char msg[]);
    void print(const char msg[]);
    void comment(const char msg[]);
    void debug(const char msg[]);
};

#endif /* defined(__RipplePrototype__Output__) */
