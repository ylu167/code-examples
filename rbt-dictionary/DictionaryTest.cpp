#include<iostream>
#include<string>
#include<stdexcept>
#include"Dictionary.h"

using namespace std;

int main(){

   string S[] =   {
                     "University",
                     "of",
                     "California",
                     "Santa",
                     "Cruz",
                     "Berkeley",
                     "Los",
                     "Angeles",
                     "San",
                     "Diego",
                     "Irvine",
                     "Merced",
                     "Riverside",
                     "Long",
                     "Beach",
                     "Jack",
                     "Baskin",
                     "School",
                     "of",
                     "engineering",
                     "computer",
                     "science",
                     "bachelor",
                     "of",
                     "science"
                  };
   string T[] =   {
                     "Berkeley",
                     "Los",
                     "Angeles",
                     "San",
                     "Diego",
                     "Irvine",
                     "Merced",
                     "Riverside",
                     "Long",
                     "Beach",   
                  };

   Dictionary A;
   Dictionary B;

   cout << endl;

   for(int i=0; i<25; i++){
      A.setValue(S[i], i+1);
   }
   
   B == A;
   B = A;
   B.equals(A);
   B.to_string();
   A.pre_string();

   cout << "A.size() = " << A.size() << endl  << A << endl;
   cout << "B.size() = " << B.size() << endl  << B << endl;

   B.setValue("Berkeley", 101);
   B.setValue("Los", 102);
   B.setValue("Angeles", 103);
   B.setValue("San", 104);
   B.setValue("Diego", 105);
   B.setValue("Irvine", 105);
   B.setValue("Merced", 106);
   B.setValue("Long", 107);
   B.setValue("Beach", 108);

   B.end();
   B.next();
   B.begin();

   Dictionary C = B;

   cout << "B.size() = " << B.size() << endl  << B << endl;
   cout << "C.size() = " << C.size() << endl  << C << endl;

   cout << "A==B is " << (A==B?"true":"false") << endl;
   cout << "B==C is " << (B==C?"true":"false") << endl;
   cout << "C==A is " << (C==A?"true":"false") << endl << endl;

   cout << A.getValue("Irvine") << endl;
   A.getValue("Irvine") *= 10;
   cout << A.getValue("Irvine") << endl << endl;

   cout << "A.size() = " << A.size() << endl  << A << endl;
   cout << "A pre-order: " << endl << A.pre_string() << endl;

   for(int i=0; i<10; i++){ 
      A.remove(T[i]);
   }

   cout << "A.size() = " << A.size() << endl  << A << endl;
   cout << "A pre-order: " << endl << A.pre_string() << endl;

   cout << "forward iteration on B, changing values:" << endl;
   for(B.begin(); B.hasCurrent(); B.next()){
      cout << "("+B.currentKey()+", " << B.currentVal() << ") ";
      B.currentVal()++;
      cout << "("+B.currentKey()+", " << B.currentVal() << ")\n";
   }
   cout << endl;
   B.begin();

   cout << "reverse iteration on C, changing values" << endl;
   for(C.end(); C.hasCurrent(); C.prev()){
      cout << "("+C.currentKey()+", " << C.currentVal() << ") ";
      C.currentVal()++;
      cout << "("+C.currentKey()+", " << C.currentVal() << ")\n";
   }
   cout << endl;
   
   cout << "test pre-condition errors:" << endl;
   try{
      A.getValue("engineering");
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }
   try{
      A.remove("Jack");
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }
   try{
      B.currentKey();
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }
   try{
      B.currentVal();
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }  
   try{
      B.next();
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }
   try{
      B.prev();
   }catch(logic_error& e){
      cout << e.what() << endl;
      cout << "   continuing without interruption" << endl;
   }
   cout << endl;  

   A.clear();
   B.clear();
   C.clear();

   return( EXIT_SUCCESS );
}
