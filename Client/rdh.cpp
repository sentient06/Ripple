//  main.cpp
//  Ruby Deployment for Humans
//
//  Created by Giancarlo Mariot on 02/01/2013.
//  Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
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

// g++ rdh.cpp
// ./a.out list
// http://www.cplusplus.com/forum/articles/13355/

#include <iostream>
#include <string>

using namespace std;

char red[11] = "\033[0;31m";
char gre[11] = "\033[0;32m";
char yel[11] = "\033[0;33m";
char blu[11] = "\033[0;34m";
char pur[11] = "\033[0;35m";
char cya[11] = "\033[0;36m";
char ncl[11] = "\033[0m"; //No colour

void errorAppName(){
    cout << red << "Please define a name for the application." << ncl << endl << endl;
}

void errorAppAddr(){
    cout << red << "Please define the URL." << ncl << endl << endl;
}

void errorAppAddrAndServer(){
    cout << red << "Please define the URL and/or the number of ports." << ncl << endl << endl;
}

int displayHelp(int argc, const char * argv[]){

    if (argc > 1 && argv[2] != NULL){

        if (string(argv[2]) == "list") {
            cout << cya << endl;
            printf("Usage: %s list\n\n", argv[0]);
            printf("Lists the applications installed, their first Thin port number, number of servers used and URL.\n");
            cout << ncl << endl;
            return 0;
        } else
        
        if (string(argv[2]) == "status") {
            cout << cya << endl;
            printf("Usage: %s status [application name | [-a|--app] application name]\n\n", argv[0]);
            printf("Lists the details of the given application, namely:\n");
            printf("  - URL\n");
            printf("  - Ports\n");
            printf("  - First port\n");
            printf("  - Repository\n");
            printf("  - Thin config\n");
            printf("  - Nginx available\n");
            printf("  - Nginx enabled\n");
            printf("  - Database\n");
            printf("  - Online\n\n");
            printf("Example: %s status [appname]\n", argv[0]);
            printf("         %s status -a [appname]\n", argv[0]);
            cout << ncl << endl;
            return 0;
        } else

        if (string(argv[2]) == "create") {
            cout << cya << endl;
            printf("Usage: %s create [ name url servers | <parameters> ]\n\n", argv[0]);
            printf("Creates an application in the server.\n");
            printf("The parameters are:\n\n");
            printf("  -a --app     #  compulsory: application's name.\n");
            printf("  -u --url     #  compulsory: application's url address.\n");
            printf("  -s --servers #  optional: number of thin server's instances to be used.\n");
            printf("                  If no number of servers is specified, it is assumed to be 1.\n\n");
            printf("Parameters can be used in a different order.\n");
            printf("Examples: %s create myapp myapp.co.uk 3\n", argv[0]);
            printf("          %s create -a myapp -u myapp.co.uk -s 3\n", argv[0]);
            cout << ncl << endl;
            return 0;
        } else

        if (string(argv[2]) == "set") {
            cout << cya << endl;
            printf("Usage: %s set [ name detail value | <parameters> ]\n\n", argv[0]);
            printf("Changes a given detail of a given application.\n");
            printf("The parameters are:\n\n");
            printf("  -a --app     #  compulsory: application's name.\n");
            printf("  -u --url     #  application's url address.\n");
            printf("  -s --servers #  number of thin server's instances to be used.\n\n");
            printf("Several details can be changed at the same time. At least one must be specified.\n");
            printf("Examples: %s set myapp -s 3\n", argv[0]);
            printf("          %s set -a myapp -u myapp.co.uk -s 3\n", argv[0]);
            cout << ncl << endl;
            return 0;
        }

        // else
        // if (string(argv[2]) == "apps") {
        //     cout << cya << endl;
        //     printf("Application actions:\n\n", argv[0]);
        //     printf("  - status\n");
        //     printf("  - create\n");
        //     printf("  - set [ url / servers ]\n");

        //     cout << ncl << endl;
        //     return 0;
        // }

    }

    cout << cya << endl;
    printf("Usage: %s COMMAND [--app APP] [command-specific-options]\n\n", argv[0]);
    printf("Primary help topics, type \"%s help TOPIC\" for more details:\n\n", argv[0]);
    printf("  list      #  list installed applications\n");
    printf("  status    #  display information about an application\n");
    printf("  create    #  creates a new application's repository and config files\n");
    printf("  set       #  changes an application's data\n");
    cout << ncl << endl;
    return 0;

}

int main (int argc, const char * argv[]) {

    //----------------------------------------------------------------------------
    // Basic stuff:

    int debugging = 0;

    char shellCmd[512];
    char fullCmd[512];

    char user[16]    = "bot";
    char server[11]  = "ubuntu12";
    char action[8]  = "sh";
    char trigger[64] = "\\$HOME/trigger.sh";

    // Variables variables?
    string command   = "";
    string shellCmd2 = "";
    string appName   = "";
    string appAddr   = "";
    string servers   = "";

    // Check arguments number and display help if necessary

    if ( argc == 1 || string(argv[1]) == "help" ) {
        displayHelp(argc, argv);
        return 0;
    } else {
        command = argv[1];
    }

    //----------------------------------------------------------------------------
    // Parsing commands

    for (int i = 1; i < argc; i++) {

        // if (i + 1 != argc) // Check that we haven't finished parsing already
        if (
               string(argv[i]) == "-a"
            || string(argv[i]) == "--app"
            || string(argv[i]) == "--application"
            || string(argv[i]) == "--name"
        ) {

            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-" ) {
                errorAppName();
                return 1;
            }
            appName = argv[i + 1];

        } else if (
               string(argv[i]) == "-u"
            || string(argv[i]) == "--url"
            || string(argv[i]) == "--addr"
            || string(argv[i]) == "--address"
        ) {

            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
                errorAppAddr();
                return 1;
            }
            appAddr = argv[i + 1];

        } else if (
               string(argv[i]) == "-s"
            || string(argv[i]) == "--servers"
            || string(argv[i]) == "--server"
            || string(argv[i]) == "-p"
            || string(argv[i]) == "--ports"
            || string(argv[i]) == "--port"
        ) {

            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
                cout << yel << "No number of servers, assuming 1." << ncl << endl << endl;
                servers = "1";
            } else {
                servers = argv[i + 1];
            }

        } else if (
               string(argv[i]) == "-dbg"
            || string(argv[i]) == "--debug"
        ) {
            debugging = 1;
            cout << red << "Debugging..." << ncl << endl << endl;
            for (int u = 1; u < argc; u++) {
                cout << pur;
                printf("%d: %s", u, argv[u]);
                cout << ncl << endl;
            }
        }
            
    }

    //----------------------------------------------------------------------------
    // Second parsing

    // Must check the counting, or else the variables get messed up with different
    // information.

    if ( appName.empty() && argc > 1 )
        if ( argv[2] ) appName = argv[2];

    if (debugging == 1){
        cout << endl << cya;
        printf("Server: %s\nArgc: %d\n", server, argc);
        cout << ncl;
    }

    //----------------------------------------------------------------------------
    // Assembling command

    if ( command == "help" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Help
        // this help [topic]

        displayHelp(argc, argv);
        return 0;

    } else {
        if ( appName.empty() && argc > 1 )
            if ( argv[2] ) appName = argv[2];
    }

    if ( command == "restart" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Restart thin / nginx
        // this restart app
 
        if (appName.empty()){
            cout << "Restarting all apps...\n" << endl;
            snprintf(shellCmd, 512, "restart");
        } else {
            printf("Restarting %s...\n", appName.c_str() );
            snprintf(shellCmd, 512, "restart %s", appName.c_str() );
        }

    } else if ( command == "list" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // List
        // this list

        snprintf(shellCmd, 512, "list", user, server, action, trigger);

    } else if ( command == "status" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Status
        // this status app

        if ( appName.empty() ) {
            errorAppName();
            return 1;
        }

        snprintf(shellCmd, 512, "status %s", appName.c_str());

    } else if ( command == "create" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Create
        // this create app app.com [2]

        if ( appName.empty() ) {
            errorAppName();
            return 1;
        }

        if ( appAddr.empty() ) {
            errorAppAddr();
            return 1;
        }

        if ( servers.empty() )
            snprintf(shellCmd, 512, "create %s %s", appName.c_str(), appAddr.c_str());
        else
            snprintf(shellCmd, 512, "create %s %s %s", appName.c_str(), appAddr.c_str(), servers.c_str());

    } else if ( command == "set" ){
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        // Set [ url | ports ]
        // this set app -u app.com
        // this set app -p 3
        // this set app -u app.com -p 3

        if ( appName.empty() ) {
            errorAppName();
            return 1;
        }

        if ( appAddr.empty() && servers.empty() ){
            errorAppAddrAndServer();
            return 1;
        }

        if ( !appAddr.empty() )
            shellCmd2 += "url:" + appAddr;

        if ( !appAddr.empty() && !servers.empty() )
            shellCmd2 += ",";

        if ( !servers.empty() )
            shellCmd2 += "ports:" + servers;

        snprintf(shellCmd, 512, "set %s %s", appName.c_str(), shellCmd2.c_str());

    }

    snprintf(fullCmd, 512, "ssh %s@%s \"%s %s %s\"", user, server, action, trigger, shellCmd);

    //----------------------------------------------------------------------------
    // Executing
    if (debugging == 1){
        cout << endl << pur;
        printf("cmd: [%s]", fullCmd);
        cout << ncl << endl;
    } else {
        // system((char *)fullCmd);
    }

    return 0;
}