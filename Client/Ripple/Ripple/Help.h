//
//  Help.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__Help__
#define __RipplePrototype__Help__

#include <iostream>

class Help {
    static const char cya[11];
    static const char ncl[11];
public:
    void displayMessage(const char executable[]) const;
    void displayHelp(const char executable[] = "", const char topic[] = "");
};

#endif /* defined(__RipplePrototype__Help__) */