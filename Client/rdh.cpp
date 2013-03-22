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

int main (int argc, const char * argv[]) {

  // Basic stuff:

  char command[512];
  char user[16]    = "bot";
  char server[64]  = "ubuntu12";
  char action[32]  = "sh";
  char trigger[64] = "\\$HOME/trigger.sh"; 

  char red[16] = "\033[0;31m";
  char gre[16] = "\033[0;32m";
  char yel[16] = "\033[0;33m";
  char blu[16] = "\033[0;34m";
  char pur[16] = "\033[0;35m";
  char cya[16] = "\033[0;36m";
  char ncl[16] = "\033[0m"; //No colour

  // Variables variables?
  string appName = "";
  string appAddr = "";
  string servers = "";

  cout << endl << cya;
  printf("Server: %s\n", server);
  cout << ncl;

  // Check arguments

  // Check arguments number
  if ( argc == 1 ) {
    cout << cya << endl;
    printf("Usage: %s COMMAND [--app APP] [command-specific-options]\n\n", argv[0]);
    printf("Primary help topics, type \"%s help TOPIC\" for more details:\n\n", argv[0]);
    printf("  list      #  list installed applications\n");
    printf("  apps      #  manage apps (create, destroy)\n");
    cout << ncl << endl;
    return 1;
  }

  //----------------------------------------------------------------------------
  // Parsing commands

  for (int i = 1; i < argc; i++) {

    // printf("%d: %s\n", i, argv[i]);
    // printf("%d: %s\n", i+1, argv[i+1]);

    // if (i + 1 != argc) // Check that we haven't finished parsing already
      if (string(argv[i]) == "-a" || string(argv[i]) == "--app") {

        if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-" ) { // || string(argv[i+1]).find("-") > 0) {
          cout << red << "Please define a name for the application." << ncl << endl << endl;
          return 1;
        }
        appName = argv[i + 1];

      } else if (string(argv[i]) == "-u" || string(argv[i]) == "--url") {

        if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
          cout << red << "Please define the URL." << ncl << endl << endl;
          return 1;
        }
        appAddr = argv[i + 1];

      } else if (string(argv[i]) == "-s" || string(argv[i]) == "--servers") {

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

  if ( appName.empty() )
    if ( argv[2] ) appName = argv[2];
  if ( appAddr.empty() )
    if ( argv[3] ) appAddr = argv[3];
  if ( servers.empty() )
    if ( argv[4] ) servers = argv[4];

  //----------------------------------------------------------------------------
  // Assembling command

  if ( strcmp(argv[1], "help") == 0 ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Help
 
      cout << "Help unfinished" << endl;


  } else if ( strcmp(argv[1], "restart") == 0 ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Restart thin / nginx
 
    if (appName.empty()){
      cout << "Restarting all apps...\n" << endl;
      snprintf(command, 512, "ssh %s@%s \"%s %s restart\"", user, server, action, trigger);
    } else {
      printf("Restarting %s...\n", appName.c_str());
      snprintf(command, 512, "ssh %s@%s \"%s %s restart %s\"", user, server, action, trigger, appName.c_str() );
    }

  } else if ( strcmp(argv[1], "list") == 0 ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // List

    snprintf(command, 512, "ssh %s@%s \"%s %s list\"", user, server, action, trigger);

  } else if ( strcmp(argv[1], "create") == 0 ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Create

    if ( servers.empty() )
      snprintf(command, 512, "ssh %s@%s \"%s %s create %s %s\"", user, server, action, trigger, appName.c_str(), appAddr.c_str());
    else
      snprintf(command, 512, "ssh %s@%s \"%s %s create %s %s %s\"", user, server, action, trigger, appName.c_str(), appAddr.c_str(), servers.c_str());

  } else if ( strcmp(argv[1], "check") == 0 ){
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Check

    snprintf(command, 512, "ssh %s@%s \"%s %s check %s\"", user, server, action, trigger, appName.c_str());
  
  }

  //----------------------------------------------------------------------------
  // Executing
  cout << endl << pur;
  printf("%s", command);
  cout << ncl << endl;

  system((char *)command);

  return 0;
}