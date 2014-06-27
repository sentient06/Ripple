//
//  Server.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__Server__
#define __RipplePrototype__Server__

#include <iostream>

class Server {
public:
    std::string nginx(const char action[]);
    std::string thin(const char action[]);
    void parseAction(int argc, const char * argv[] = NULL);
};

#endif /* defined(__RipplePrototype__Server__) */
