//
//  Data.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__Data__
#define __RipplePrototype__Data__

#include <iostream>

class Data {
    static const char cya[11];
    static const char ncl[11];
public:
    std::string configDir();
    std::string configFile();
    std::string exec(char* cmd);
    std::string getServerName();
    void showServerName(const char executable[]);
    std::string readConfig(char* file);
    int saveConfig(const char* server);
};

#endif /* defined(__RipplePrototype__Data__) */
