//  main.c
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

#include <stdio.h>
#include <string.h>

int main (int argc, const char * argv[]) {

    char temp[512];
    string str = "testing";



    // rdh list   name url
    // rdh test   name url --
    // rdh create name --- --
    // rdh delete name --- --

    // rdh create  name url
    // rdh enable  name url --
    // rdh disable name --- --
    // rdh delete  name --- --

    // printf("%d params\n", argc);
    // printf("param num 0 = %s \n", argv[0]);
    // printf("param num 1 = %s \n", argv[1]);
    // printf("%d\n", strcmp(argv[1], "create") );

    // gcc main.c -o rdh
    // ./rdh create teste www.teste.com
    
    if ( argc > 1 ) {
        
        if ( strcmp(argv[1], "list") == 0 ) {

            printf("List: %s\n", str);

            // snprintf(temp, 512, "ssh bot@ubuntuRails \"sh \\$HOME/scripts/createApp.sh %s %s\"", argv[3], argv[2]);
        
        } else if ( strcmp(argv[1], "create") == 0 ) {
            
            // Create action:
            
            if ( argc < 4 ) {
                printf("Use: rdh create <name> <url>\n");
                return -1;
            }

            printf("Creating application %s...\n", argv[2]);

            
            // snprintf(temp, 512, "ssh rdh@rdh << 'ENDSSH' echo %s > %s ENDSSH", argv[3], argv[2]);
            snprintf(temp, 512, "ssh bot@ubuntuRails \"sh \\$HOME/scripts/createApp.sh %s %s\"", argv[3], argv[2]);
            // ssh rdh@rdh "echo \$HOME"
            // ssh rdh@rdh "sh createApp.sh %s %s"
            // snprintf(temp, 512, "echo %s - %s", argv[3], argv[2]);
            
        } else if ( strcmp(argv[1], "enable") == 0 ) {
            
            printf("Later...\n");
            return -2;

            // Disable action:
            
            if ( argc < 3 ) {
                printf("Use: rdh enable <name>\n");
                return -1;
            }

            printf("Disabling application %s...\n", argv[2]);
            snprintf(temp, 512, "ssh gian@ubuntuRails \"sh \\$HOME/enableApp.sh %s\"", argv[2]);
            
        } else if ( strcmp(argv[1], "disable") == 0 ) {
            
            printf("Later...\n");
            return -2;

            // Disable action:
            
            if ( argc < 3 ) {
                printf("Use: rdh disable <name>\n");
                return -1;
            }

            printf("Disabling application %s...\n", argv[2]);
            snprintf(temp, 512, "ssh gian@ubuntuRails \"sh \\$HOME/disableApp.sh %s\"", argv[2]);
            
        } else if ( strcmp(argv[1], "delete") == 0 ) {
            
            printf("Later...\n");
            return -2;

            // Delete action:
            
            if ( argc < 3 ) {
                printf("Use: rdh delete <name>\n");
                return -1;
            }

            printf("Deleting application %s...\n", argv[2]);
            snprintf(temp, 512, "ssh gian@ubuntuRails \"sh \\$HOME/deleteApp.sh %s\"", argv[2]);
            
        }

        system((char *)temp);
        
    } else {
        printf("Use: rdh <action>\n");
        printf("      -  list\n");
        printf("      -  create\n");
        printf("      -  delete\n");
    }
    
    return 0;
}

