//
//  Server.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#include <string>
#include "Server.h"
#include "Pigeon.h"
#include "Data.h"
#include "Output.h"

using namespace std;

string Server::nginx(const char action[]) {
    string cmd = "nginx";
    if ( string(action) == "start" )
        cmd += " start";
    else if ( string(action) == "stop" )
        cmd += " stop";
    else if ( string(action) == "restart" )
        cmd += " restart";
    else
        cmd = "err1";
    return cmd;
}

string Server::thin(const char action[]) {
    string cmd = "thin";
    if ( string(action) == "start" )
        cmd += " start all";
    else if ( string(action) == "stop" )
        cmd += " stop all";
    else if ( string(action) == "restart" )
        cmd += " restart all";
    else
        cmd = "err1";
    return cmd;
}

void Server::parseAction(int argc, const char * argv[]) {
    Output o;
    Data d;
    if (argv == NULL) {
        o.error("Unknown command");
        o.print("'server' commands are: 'add', 'remove' and 'use'");
        o.print("Commands must be followed by server's name.");
        return;
    }
    if ( string(argv[0]) == "add" ) {
        d.saveConfig(argv[1]);
    } else
    if ( string(argv[0]) == "remove" ) {
        cout << "Server remove " << argv[1] << endl;
    } else
    if ( string(argv[0]) == "use" ) {
        cout << "Server use " << argv[1] << endl;
    }
}