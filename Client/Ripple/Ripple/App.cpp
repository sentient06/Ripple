//
//  App.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#include <string>
#include "App.h"
#include "Data.h"
#include "Pigeon.h"

using namespace std;

App::App() {
    name  = "";
    url   = "";
    ports = 0;
}

string App::add(int argc, const char * argv[]) {
    for (int i = 0; i < argc; i++) {
        if (   string(argv[i]) == "-a"
            || string(argv[i]) == "--app"
            || string(argv[i]) == "--application"
            || string(argv[i]) == "--name"
            ) {
            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
                cout << "Error name" << endl;
            } else {
                if (name.empty()) {
                    name = argv[i+1];
                } else {
                    o.error("<name> parameter is duplicated");
                    return "err0";
                }
            }
        }
        if (   string(argv[i]) == "-u"
            || string(argv[i]) == "--url"
            || string(argv[i]) == "--addr"
            || string(argv[i]) == "--address"
            ) {
            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
                cout << "Error url" << endl;
            } else {
                if (url.empty()) {
                    url = argv[i+1];
                } else {
                    o.error("<url> parameter is duplicated");
                    return "err0";
                }
            }
        }
        if (   string(argv[i]) == "-p"
            || string(argv[i]) == "--ports"
            || string(argv[i]) == "--port"
            ) {
            if (argv[i+1] == NULL || string(argv[i+1]).substr(0,1) == "-") {
                cout << "Error ports" << endl;
            } else {
                if (ports == 0) {
                    ports = (int)strtoul(argv[i+1], 0, 0);
                } else {
                    o.error("<ports> parameter is duplicated");
                    return "err0";
                }
            }
        }
    }
    
    // Try shorthand
    if (name.empty() && url.empty()) {
        if (!(string(argv[0]).empty()))
            name = string(argv[0]);
        if (!(string(argv[1]).empty()))
            url = string(argv[1]);
    }

    if (ports == 0)
        if (argc > 2)
            if (!(string(argv[2]).empty()))
                ports = (int)strtoul(argv[2], 0, 0);
    
    // If something is still missing, throw error:
    if (name.empty())
        o.error("Missing a name for the application");
    if (url.empty())
        o.error("Missing an URL for the application");
    if (name.empty() || url.empty())
        return "err2";
    
    if (ports > 0) {
        snprintf(cmd, 512, "add %s %s %d", name.c_str(), url.c_str(), ports);
    } else {
        snprintf(cmd, 512, "add %s %s", name.c_str(), url.c_str());
    }
    
    return string(cmd);
}

string App::parseActions(int argc, const char * argv[], bool debug) {

    if ( string(argv[1]) == "set"      ) return set(argc, argv);
    if ( string(argv[1]) == "db"      ||
         string(argv[1]) == "database" ) return database(argc, argv, debug);

    if ( string(argv[1]) == "status"   ) return status(argv[0]);
    if ( string(argv[1]) == "start"    ) return start(argv[0]);
    if ( string(argv[1]) == "stop"     ) return stop(argv[0]);
    if ( string(argv[1]) == "restart"  ) return restart(argv[0]);
    if ( string(argv[1]) == "enable"   ) return enable(argv[0]);
    if ( string(argv[1]) == "disable"  ) return disable(argv[0]);
    if ( string(argv[1]) == "avail"    ) return avail(argv[0]);
    if ( string(argv[1]) == "deploy"   ) return deploy(argv[0]);
    if ( string(argv[1]) == "hinder"   ) return hinder(argv[0]);
    if ( string(argv[1]) == "remove"   ) return remove(argv[0]);
    if ( string(argv[1]) == "destroy"  ) return destroy(argv[0]);

    return "err1";
}

string App::set(int argc, const char * argv[]) {
    char cmd[512];
    snprintf(cmd, 512, "set %s", argv[0]);
    for (int i = 2; i < argc; ++i) {
        long col = string(argv[i]).find_first_of( ":" );
        if (col == -1) {
            return "err3";
        } else {
            if (i == 2)
                snprintf(cmd, 512, "%s %s", cmd, argv[i]);
            else
                snprintf(cmd, 512, "%s,%s", cmd, argv[i]);
        }
        // cout << string(argv[i]) << " - " << col << endl;
    }
    return string(cmd);
}
string App::database(int argc, const char * argv[], bool debug) {
    char cmd[512];
    char remoteFile[512];
    Pigeon p;

    if (argc == 3) {
        // Server-only actions
        if ( string(argv[2]) == "backup" ) {
            // Plain backup
            snprintf(cmd, 512, "databaseBackup %s", argv[0]);
            return string(cmd);
        }
    } else if (argc == 4) {
        // Server-only actions
        if ( string(argv[2]) == "backup" ) {
            if ( string(argv[3]) == "delete" ) {
                snprintf(cmd, 512, "databaseDelete %s", argv[0]);
                return string(cmd);
            } else if ( string(argv[3]) == "restore" ) {
                snprintf(cmd, 512, "databaseRestore %s", argv[0]);
                return string(cmd);
            } else if ( string(argv[3]) == "copy" ) {
                snprintf(remoteFile, 512, "/ripple/backup/%s.gz", argv[0]);                
                snprintf(cmd, 512, "databaseBackup %s", argv[0]);
                p.post(cmd, debug);
                p.downloadFile(remoteFile, "~/Desktop/", debug);
                return "skip";
            }
        }
    } else if (argc > 4) {
        // Server+client actions
        if ( string(argv[2]) == "backup" ) {
            snprintf(remoteFile, 512, "/ripple/backup/%s.gz", argv[0]);                
            if ( string(argv[3]) == "copy" ) {
                snprintf(cmd, 512, "databaseBackup %s", argv[0]);
                p.post(cmd, debug);
                p.downloadFile(remoteFile, argv[4], debug);
                return "skip";
            } else if ( string(argv[3]) == "restore" ) {
                p.uploadFile(argv[4], remoteFile, debug);
                snprintf(cmd, 512, "databaseRestore %s", argv[0]);
                return string(cmd);
            }
        }
    }
    return "err1";
}
string App::status(const char app[]) {
    snprintf(cmd, 512, "status %s", app);
    return string(cmd);
}
string App::start(const char app[]) {
    snprintf(cmd, 512, "start %s", app);
    return string(cmd);
}
string App::stop(const char app[]) {
    snprintf(cmd, 512, "stop %s", app);
    return string(cmd);
}
string App::restart(const char app[]) {
    snprintf(cmd, 512, "restart %s", app);
    return string(cmd);
}
string App::enable(const char app[]) {
    snprintf(cmd, 512, "enable %s", app);
    return string(cmd);
}
string App::disable(const char app[]) {
    snprintf(cmd, 512, "disable %s", app);
    return string(cmd);
}
string App::avail(const char app[]) {
    snprintf(cmd, 512, "avail %s", app);
    return string(cmd);
}
string App::deploy(const char app[]) {
    snprintf(cmd, 512, "deploy %s", app);
    return string(cmd);
}
string App::hinder(const char app[]) {
    snprintf(cmd, 512, "hinder %s", app);
    return string(cmd);
}
string App::remove(const char app[]) {
    snprintf(cmd, 512, "remove %s", app);
    return string(cmd);
}
string App::destroy(const char app[]) {
    snprintf(cmd, 512, "destroy %s", app);
    return string(cmd);
}

string App::allApps(const char action[]) {
    if (string(action) == "stop"    ||
        string(action) == "start"   ||
        string(action) == "restart" ||
        string(action) == "update"   ) {
        snprintf(cmd, 512, "allApplications %s", action);
        return string(cmd);
    } else {
        return "err1";
    }
}
