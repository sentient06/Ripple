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
const char Help::pur[11] = "\033[0;35m";
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
    if ( string(topic) == "master" ) {
        printf("Available \"master\" commands:\n");
        printf("  master-update | --mupd #  Update server-side info based on last code changes.\n");
        printf("  master-debug  | --mdb  #  Show loaded information from YML and data files.\n");
        printf("  --debug       | -db    #  Debugs current action. No triggers are activated.\n");
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
        printf("Lists the applications installed. Output looks like this:\n");
        printf("[AppName] - XXp | PPPP |  FLAGS  | URL\n");
        printf("AppName . Application's name\n");
        printf("XXp ..... Number of ports served by Thin, e.g 01p or 03p\n");
        printf("PPPP .... First port served by Thin, e.g 3000, 3005\n");
        printf("URL ..... Application's DNS'\n");
        printf("These are the visible flags:\n");
        printf("R ....... Repository\n");
        printf("T ....... Thin configuration file (serving on port PPPP)\n");
        printf("A ....... Nginx config file is Available\n");
        printf("E ....... Nginx config file is Enabled (serving on port 80)\n");
        printf("D ....... There is a Database\n");
        printf("O ....... Application is online\n");
        printf("U ....... Application is updated\n");
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
        printf("  enable  #  enables application's in Nginx\n");
        printf("  avail   #  saves application config file in Nginx\n");
        printf("  restart #  restarts application\n");
        printf("  hinder  #  deletes application config file from Nginx\n");
        printf("  disable #  disables application in Nginx\n");
        printf("  stop    #  stops serving application through Thin\n");
        printf("  destroy #  destroys application directory and repository\n");
        printf("  set     #  sets name, ports and URL with values after colons.\n");
        printf("             E.g: '%s . myApp set ports:2 url:mynewurl.com'\n", executable);

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