//
//  Help.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#include <string>
#include "Help.h"
#include "Output.h"

using namespace std;

const char Help::cya[11] = "\033[0;36m";
const char Help::ncl[11] = "\033[0m"; //No colour

void Help::displayMessage(const char executable[]) const {
    cout << cya << endl;
    printf("Hello.\nType '%s help' for help\n", executable);
    cout << ncl << endl;
}

void Help::displayHelp(const char executable[], const char topic[]) {
    cout << cya << endl;
    if ( string(topic).empty() ) {
        printf("Usage: %s COMMAND [command-specific-options]\n\n", executable);
        printf("Type \"%s help [topic]\" for more details. These are the primary topics:\n\n", executable);
        printf("  server #  manage servers' information\n");
        printf("  test   #  test permissions and availability\n");
        printf("  list   #  list installed applications\n");
        printf("  nginx  #  control Nginx reverse proxy\n");
        printf("  thin   #  control Thin server\n");
        printf("  app    #  control application\n");
        printf("  add    #  creates a new application's repository and config files\n");
    }
    if ( string(topic) == "help" ) {
        printf("Usage: %s help [topic]\n\n", executable);
        printf("Uh... Displays help. You just did it, by the way.\n");
    }
    if ( string(topic) == "server" ) {
        printf("Usage: %s server <server>\n\n", executable);
        cout <<
        "If no parameters are used, shows the current server's address.\n" <<
        "With one parameter, stores the new server address.\n" <<
        "The address can be an IP or host name (i.e. hosts file DNS).\n";
    }
    if ( string(topic) == "test"   ) {
        printf("Usage: %s test\n\n", executable);
        printf("Tests the servers availability and user's permissions.\n");
    }
    if ( string(topic) == "list"   ) {
        printf("Usage: %s list\n\n", executable);
        printf("Lists the applications installed, their first Thin port number, number of servers used and URL.\n");
    }
    if ( string(topic) == "nginx" ||
         string(topic) == "-n"     ) {
        printf("Usage: %s <nginx|-n> <start|stop|restart> \n", executable);
    }
    if ( string(topic) == "thin"  ||
         string(topic) == "-t"     ) {
        printf("Usage: %s <thin|-t> <start|stop|restart> \n", executable);
    }
    if ( string(topic) == "app"   ||
         string(topic) == "-a"    ||
         string(topic) == "."      ) {
        printf("Usage: %s <app|-a|.> <action> [set options]\n\n", executable);
        printf("These are the primary options:\n\n");
        printf("  start   #  serves application\n");
        printf("  stop    #  stops serving application\n");
        printf("  restart #  restarts application\n");
        printf("  enable  #  enables application's availability in Nginx\n");
        printf("  disable #  stops serving and disables application's availability in Nginx\n");
        printf("  destroy #  destroys application (application must be disabled)\n");
        printf("  set     #  sets a value of <name>, <url> and <ports> parameters\n");
        //start|stop|restart|enable|disable|destroy|set
    }
    if ( string(topic) == "add"   ||
         string(topic) == "+"      ) {
        printf("Usage: %s <add|+> <parameters>\n\n", executable);
        printf("Creates an application in the server.\n");
        printf("These are the primary parameters:\n\n");
        printf("  -a --app     #  compulsory: application's name.\n");
        printf("  -u --url     #  compulsory: application's url address.\n");
        printf("  -p --ports   #  optional: number of thin server's instances to be used.\n");
        printf("                  If no number of ports is specified, it is assumed to be 1.\n\n");
        printf("Parameters can be used in a different order.\n");
        printf("Shorthand command:\n");
        printf("%s add <app> <url> [ports]\n", executable);
        printf("Examples: %s create myapp myapp.co.uk 3\n", executable);
        printf("          %s create -a myapp -u myapp.co.uk -s 3\n", executable);
        
    }
    cout << ncl << endl;
}