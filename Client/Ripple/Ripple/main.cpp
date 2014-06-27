//
//  main.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//
// ------------------------------------------------------------------------------
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
// ------------------------------------------------------------------------------
//  - -- --- ---- ==== ===== > >> !!! WARNING !!! << < ===== ==== ---- --- -- -
//
// This code was done in a macintosh computer and may not work properly in a
// different system without adaptations!
// ------------------------------------------------------------------------------
// This code is the result of tests and it was made for the sole purpose of
// personal fulfillment and is purely experimental.
// It is not recomended to be used in a professional environment. The code is not
// properly sanitised and the best practices are not rigidly followed.
// Do not trust the access to such an application to someone likely to mess up
// with your server.
// ------------------------------------------------------------------------------
//
// XCode is recommended for compiling.
//
// For quick console compilation (G++):
// g++ -o ripple main.cpp App.cpp Data.cpp Help.cpp Output.cpp Pigeon.cpp Server.cpp
//
// ln -s `pwd`/ripple /usr/local/bin/rp
//
// http://www.cplusplus.com/forum/articles/13355/

#include <iostream>
#include <string>
//#include <fstream>
//#include <sys/stat.h>

#include "Help.h"
#include "Data.h"
#include "Server.h"
#include "App.h"
#include "Pigeon.h"
#include "Output.h"

using namespace std;

int main(int argc, const char * argv[]) {
    Help help;
    Data data;
    Server server;
    App app;
    Pigeon pigeon;
    Output o;

    string msg = "err0";
    char debugMessage[512];
    bool debug = false;
    
    if ( string(argv[argc-1]) == "-db" ||
         string(argv[argc-1]) == "--debug" ) {
        argc -= 1;
        debug = true;
    }
    
    if ( argc == 1 ) {
        help.displayMessage(argv[0]);
        return 0;
    } else if ( argc == 2 ) {
             if ( string(argv[1]) == "help"    ) help.displayHelp(argv[0]);
        else if ( string(argv[1]) == "server"  ) data.showServerName(argv[0]);
        else if ( string(argv[1]) == "test"    ) msg = "test";
        else if ( string(argv[1]) == "list"    ) msg = "list";
        else msg = "err1";
    } else if ( argc == 3 ) {
             if ( string(argv[1]) == "help"    ) help.displayHelp(argv[0], argv[2]);
        else if ( string(argv[1]) == "nginx"   ) msg = server.nginx(argv[2]);
        else if ( string(argv[1]) == "-n"      ) msg = server.nginx(argv[2]);
        else if ( string(argv[1]) == "thin"    ) msg = server.thin(argv[2]);
        else if ( string(argv[1]) == "-t"      ) msg = server.thin(argv[2]);
        else if ( string(argv[1]) == "server" ||
                  string(argv[1]) == "-s"      ) server.parseAction(argc);
        else if ( string(argv[1]) == "app"    ||
                  string(argv[1]) == "-a"     ||
                  string(argv[1]) == "."      ||
                  string(argv[1]) == "add"    ||
                  string(argv[1]) == "+"       ) msg = "err2";
        else msg = "err1";
    } else if ( argc > 3 ) {

        // Here the arguments must be parsed elsewhere.
        int argCount = argc-2;
        const char * arguments[argCount];
        for (int i = 2; i < argc; i++) {
            arguments[i-2] = argv[i];
        }
        
             if ( string(argv[1]) == "server" ||
                  string(argv[1]) == "-s"      ) server.parseAction(argCount, arguments);
        else if ( string(argv[1]) == "add"    ||
                  string(argv[1]) == "+"       ) msg = app.add(argCount, arguments);
        else if ( string(argv[1]) == "app"    ||
                  string(argv[1]) == "-a"     ||
                  string(argv[1]) == "."       ) msg = app.parseActions(argCount, arguments);
        else msg = "err1";
    }
    
    if (debug) {
        o.warning("Debugging...\n");
        for (int u = 1; u < argc+1; u++) {
            snprintf(debugMessage, 512, "%2d %.7s %s", u, "................", argv[u]);
            o.debug(debugMessage);
        }
        snprintf(debugMessage, 512, "\n%.10s %.10s\n%.10s %d\n", "Server ...............", data.getServerName() == "" ? "---" : data.getServerName().c_str(), "Argc ..............", argc);
        o.debug(debugMessage);
    }
    
    if (!msg.empty()) {
        if (msg == "err0") {
            return 0;
        } else if (msg == "err1") {
            o.error("Unkown action");
        } else if (msg == "err2") {
            o.error("Missing argument");
        } else {
            pigeon.post(msg.c_str(), debug);
        }
    }
    
    return 0;
}

