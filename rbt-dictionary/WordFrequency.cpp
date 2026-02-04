#include "Dictionary.h"
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

using namespace std;

int main(int argc, char* argv[]) {

    int line_count = 0;
    size_t begin, end, len, token_len, index;
    string line;
    string token;
    string delim = " \t\\\"\',<.>/?;:[{]}|`~!@#$%^&*()-_=+0123456789";
    Dictionary newD = Dictionary();
    ifstream in;
    ofstream out;
    if( argc != 3 ){
        cerr << "Usage: " << argv[0] << " <input file> <output file>" << endl;
        return(EXIT_FAILURE);
    }

    in.open(argv[1]);
    if( !in.is_open() ){
        cerr << "Unable to open file " << argv[1] << " for reading" << endl;
        return(EXIT_FAILURE);
    }

    out.open(argv[2]);
    if( !out.is_open() ){
        cerr << "Unable to open file " << argv[2] << " for writing" << endl;
        return(EXIT_FAILURE);
    }

    while (getline(in, line)) {
      line_count++;
      len = line.length();

      begin = min(line.find_first_not_of(delim, 0), len);
      end   = min(line.find_first_of(delim, begin), len);
      token = line.substr(begin, end-begin);

      while( token!="" ){
        token_len = token.length();
        index = 0;
        while (token_len > 0) {
          token[index] = tolower(token[index]);
          token_len--;
          index++;
        }

        if (newD.contains(token)) {
          newD.getValue(token) ++;
        } else {
          newD.setValue(token, 1);
        }
        
        begin = min(line.find_first_not_of(delim, end+1), len);
        end   = min(line.find_first_of(delim, begin), len);
        token = line.substr(begin, end-begin);
      }
    }

    out << newD << endl;

    in.close();
    out.close();

    return(EXIT_SUCCESS);
}
