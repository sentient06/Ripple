//
//  Data.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#include <iostream>
#include <string>
#include <fstream>
#include <sys/stat.h>
#include "Data.h"

using namespace std;

const char Data::cya[11] = "\033[0;36m";
const char Data::ncl[11] = "\033[0m"; //No colour

string Data::configDir() {
    string userName = exec(const_cast<char *>("whoami"));
    return "/Users/" + userName.substr(0,userName.length()-1)  + "/Library/Application Support/Ripple/";
}

string Data::configFile() {
    return configDir() + "config";
}

/**
 * Executes Unix command.
 * @see http://stackoverflow.com/questions/478898/how-to-execute-a-command-and-get-output-of-command-within-c
 * @see http://stackoverflow.com/questions/7468286/warning-deprecated-conversion-from-string-constant-to-char
 */
string Data::exec(char* cmd) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return "ERROR";
    char buffer[128];
    std::string result = "";
    while(!feof(pipe)) {
        if(fgets(buffer, 128, pipe) != NULL)
            result += buffer;
    }
    pclose(pipe);
    return result;
}

string Data::getServerName() {
    string serverAddr = readConfig(const_cast<char *>(configFile().c_str()));
    return serverAddr;
}

/**
 * Shows current server in use.
 */
void Data::showServerName(const char executable[]) {
    string serverAddr = getServerName();
    if ( serverAddr == "" ) {
        cout << cya << endl;
        printf("No server is defined.\nDefine a server address using '%s server <server>'.\n", executable);
        cout << ncl << endl;
    } else {
        cout << cya << endl;
        cout << "Server: " << serverAddr.c_str() << endl;
        cout << ncl << endl;
    }
}

/**
 * Reads configuration file.
 */
string Data::readConfig(char* file) {
    string line = "";
    ifstream myfile(file);
    if (myfile.is_open()){
        while ( myfile.good() ){
            getline (myfile,line);
            // cout << line << endl;
        }
        myfile.close();
    }
    return line;
}

/**
 * Saves the configuration file.
 */
int Data::saveConfig(const char* server) {
    string dir  = configDir();
    string file = configFile();
    // cout << "Dir:    " << dir << endl;
    // cout << "File:   " << file.c_str() << endl;
    cout << cya << "Server: " << server << ncl << endl << endl;
    
    mkdir(dir.c_str(), 0755); // 755 = (d) rwx r-x r-x
    
    ofstream myfile;
    myfile.open(file.c_str());
    myfile << server;
    myfile.close();
    return 0;
}