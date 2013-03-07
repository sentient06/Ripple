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

  char temp[512];
  char user[16]    = "bot";
  char server[64]  = "ubuntu12";
  char ruby[32]    = "/usr/local/rvm/bin/ruby";
  char trigger[64] = "/home/deploy/scripts/trigger.rb"; 

  char red[16] = "\033[0;31m";
  char gre[16] = "\033[0;32m";
  char yel[16] = "\033[0;33m";
  char blu[16] = "\033[0;34m";
  char pur[16] = "\033[0;35m";
  char cya[16] = "\033[0;36m";
  char ncl[16] = "\033[0m"; //No colour

  // Variables variables?
  char appName[32] = "-1";
  char appUrl [64] = "-1";
  char servers[3]  = "-1";

  cout << endl << gre;
  printf("Server: %s\n", server);
  cout << ncl;

  // Check arguments

  // Check arguments number
  if ( argc == 1 ) {
    cout << cya << endl;
    printf("Use: rdh <action>\n");
    printf("      -  list\n");
    printf("      -  create\n");
    printf("      -  delete\n");
    cout << ncl << endl;
    return 1;
  }

  // Parsing commands
  for (int i = 1; i < argc; i++) {

    if (i + 1 != argc) // Check that we haven't finished parsing already
      if (argv[i] == "-a") {
        appName = argv[i + 1];
      } else if (argv[i] == "-u") {
        appUrl = argv[i + 1];
      } else if (argv[i] == "-s") {
        servers = argv[i + 1];
      }

  }

  // Second parsing
  if ( strcmp(appName, "-1") ) appName = argv[2];

  // Assembling command
  if ( strcmp(argv[1], "list") == 0 )
    snprintf(temp, 512, "ssh %s@%s \"%s %s list\"", user, server, ruby, trigger);
  
  if ( strcmp(argv[1], "create") == 0 ){
    printf("appName: %s\n", appName);
    printf("appUrl : %s\n", appUrl); 
    printf("servers: %s\n", servers);
  }
    printf("2: %s", argv[2]);
    // snprintf(temp, 512, "ssh %s@%s \"%s %s create %s %s\"", user, server, ruby, trigger, argv[2], argv[2]);
  
  if ( strcmp(argv[1], "check") == 0 )
    printf("2: %s", argv[2]);
    // snprintf(temp, 512, "ssh %s@%s \"%s %s check %s\"", user, server, ruby, trigger, argv[2]);

  // Executing
  // system((char *)temp);

  return 0;
}