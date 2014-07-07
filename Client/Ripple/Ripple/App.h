//
//  App.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__App__
#define __RipplePrototype__App__

#include <iostream>
#include "Output.h"

class App {
    Output o;
    std::string name;
    std::string url;
    int ports;
    char cmd[512];
public:
    App();
    std::string add(int argc, const char * argv[]);
    std::string parseActions(int argc, const char * argv[]);
    std::string set(int argc, const char * argv[]);
    std::string status(const char app[]);
    std::string start(const char app[]);
    std::string stop(const char app[]);
    std::string restart(const char app[]);
    std::string enable(const char app[]);
    std::string disable(const char app[]);
    std::string avail(const char app[]);
    std::string deploy(const char app[]);
    std::string hinder(const char app[]);
    std::string remove(const char app[]);
    std::string destroy(const char app[]);
    std::string allApps(const char action[]);
};

#endif /* defined(__RipplePrototype__App__) */
