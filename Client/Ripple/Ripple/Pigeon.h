//
//  Pigeon.h
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#ifndef __RipplePrototype__Pigeon__
#define __RipplePrototype__Pigeon__

#include <iostream>

class Pigeon {
    char fullCmd[512];
    static const char user[16];
    static const char action[8];
    static const char trigger[64];
public:
    int post(const char msg[], bool debug);
    int checkOnlineServer(std::string serverAddr);
    int downloadFile(const char fileRemote[], const char fileLocal[], bool debug);
    int uploadFile(const char fileLocal[], const char fileRemote[], bool debug);
};

#endif /* defined(__RipplePrototype__Pigeon__) */
