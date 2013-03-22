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

char red[16] = "\033[0;31m";
char gre[16] = "\033[0;32m";
char yel[16] = "\033[0;33m";
char blu[16] = "\033[0;34m";
char pur[16] = "\033[0;35m";
char cya[16] = "\033[0;36m";
char ncl[16] = "\033[0m"; //No colour

void errorAppName(){
  cout << red << "Please define a name for the application." << ncl << endl << endl;
}

void errorAppAddr(){
  cout << red << "Please define the URL." << ncl << endl << endl;
}

void errorAppAddrAndServer(){
  cout << red << "Please define the URL and/or the number of ports." << ncl << endl << endl;
}

void displayHelp(const char * argv[]){
  cout << cya << endl;
  printf("Usage: %s COMMAND [--app APP] [command-specific-options]\n\n", argv[0]);
  printf("Primary help topics, type \"%s help TOPIC\" for more details:\n\n", argv[0]);
  printf("  list      #  list installed applications\n");
  printf("  status    #  display information about an application\n");
  printf("  apps      #  manage apps (create, destroy)\n");
  cout << ncl << endl;
}



int main (int argc, const char * argv[]) {

  // Basic stuff:
  char shellCmd[512];
  char fullCmd[512];

  char user[16]    = "bot";
  char server[64]  = "ubuntu12";
  char action[32]  = "sh";
  char trigger[64] = "\\$HOME/trigger.sh"; 

  // Variables variables?
  string command = argv[1]; //.c_str();
  string shellCmd2 = "";
  string appName = "";
  string appAddr = "";
  string servers = "";

  cout << endl << cya;
  printf("Server: %s\n", server);
  cout << ncl;

  // Check arguments number
  if ( argc == 1 ) {
    displayHelp(argv);
    return 1;
  }

  //----------------------------------------------------------------------------
  // Parsing commands

  for (int i = 1; i < argc; i++) {

    cout << pur;
    printf("%d: %s", i, argv[i]);
    cout << ncl << endl;
    // printf("%d: %s\n", i+1, argv[i+1]);

    // if (i + 1 != argc) // Check that we haven't finished parsing already
      if (string(argv[i]) == "-a" || string(argv[i]) == "--app") {

        if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-" ) { // || string(argv[i+1]).find("-") > 0) {
          errorAppName();
          return 1;
        }
        appName = argv[i + 1];

      } else if (
           string(argv[i]) == "-u"
        || string(argv[i]) == "--url"
        || string(argv[i]) == "--addr"
      ) {

        if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
          errorAppAddr();
          return 1;
        }
        appAddr = argv[i + 1];

      } else if (
           string(argv[i]) == "-s"
        || string(argv[i]) == "--servers"
        || string(argv[i]) == "-p"
        || string(argv[i]) == "--ports"
      ) {

        if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
          cout << yel << "No number of servers, assuming 1." << ncl << endl << endl;
          servers = "1";
        } else {
          servers = argv[i + 1];
        }

      }
      
  }

  //----------------------------------------------------------------------------
  // Second parsing

  // Must check the counting, or else the variables get messed up with different
  // information.

  if ( appName.empty() && argc > 1 )
    if ( argv[2] ) appName = argv[2];
  // if ( appAddr.empty() && argc > 2 )
  //   if ( argv[3] ) appAddr = argv[3];
  // if ( servers.empty() && argc > 3 )
  //   if ( argv[4] ) servers = argv[4];

  // cout << endl << pur;
  // printf("appName: [%s] appAddr: [%s] servers: [%s]", appName.c_str(), appAddr.c_str(), servers.c_str());
  // cout << ncl << endl;

  //----------------------------------------------------------------------------
  // Assembling command

  if ( command == "help" ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Help
    // this help
 
      cout << "Help unfinished" << endl;


  } else if ( command == "restart" ){
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

    // if ( servers.empty() )
    //   snprintf(shellCmd, 512, "create %s %s", appName.c_str(), appAddr.c_str());
    // else
    //   snprintf(shellCmd, 512, "create %s %s %s", appName.c_str(), appAddr.c_str(), servers.c_str());

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
    }

    if ( !appAddr.empty() ) {
      // cout << "url = " << appAddr.c_str() << endl;
      shellCmd2 += "url:" + appAddr;
    }

    if ( !appAddr.empty() && !servers.empty() ) {
      shellCmd2 += ",";
    }

    if ( !servers.empty() ) {
      // cout << "pts = " << servers.c_str() << endl;
      shellCmd2 += "ports:" + servers;
    }

    snprintf(shellCmd, 512, "set %s %s", appName.c_str(), shellCmd2.c_str());

    // if ( servers.empty() )
    //   snprintf(shellCmd, 512, "create %s %s", appName.c_str(), appAddr.c_str());
    // else
    //   snprintf(shellCmd, 512, "create %s %s %s", appName.c_str(), appAddr.c_str(), servers.c_str());

  }

  snprintf(fullCmd, 512, "ssh %s@%s \"%s %s %s\"", user, server, action, trigger, shellCmd);

  //----------------------------------------------------------------------------
  // Executing
  cout << endl << pur;
  printf("cmd: [%s]", fullCmd);
  cout << ncl << endl;

  system((char *)fullCmd);

  return 0;
}