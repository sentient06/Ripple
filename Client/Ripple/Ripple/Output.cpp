//
//  Output.cpp
//  Ripple
//
//  Created by Giancarlo Mariot on 26/06/2014.
//  Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
//

#include <string>
#include "Output.h"

using namespace std;

const char Output::red[11] = "\033[0;31m";
const char Output::gre[11] = "\033[0;32m";
const char Output::yel[11] = "\033[0;33m";
const char Output::blu[11] = "\033[0;34m";
const char Output::pur[11] = "\033[0;35m";
const char Output::cya[11] = "\033[0;36m";
const char Output::ncl[11] = "\033[0m"; //No colour
    
void Output::puts(const char msg[]) {
    cout << msg << endl;
}
void Output::error(const char msg[]) {
    cout << red << msg << ncl << endl;
}
void Output::warning(const char msg[]) {
    cout << yel << msg << ncl << endl;
}
void Output::success(const char msg[]) {
    cout << gre << msg << ncl << endl;
}
void Output::print(const char msg[]) {
    cout << cya << msg << ncl << endl;
}
void Output::comment(const char msg[]) {
    cout << blu << msg << ncl << endl;
}
void Output::debug(const char msg[]) {
    cout << pur << msg << ncl << endl;
}