#include<iostream>
#include<string>

#ifndef DICTIONARY_H_INCLUDE_
#define DICTIONARY_H_INCLUDE_


typedef std::string keyType;
typedef int         valType;

class Dictionary{

private:

   struct Node{
      keyType key;
      valType val;
      Node* parent;
      Node* left;
      Node* right;
      int color;
      Node(keyType k, valType v);
   };

   Node* nil;
   Node* root;
   Node* current;
   int   num_pairs;

   void inOrderString(std::string& s, Node* R) const;

   void preOrderString(std::string& s, Node* R) const;

   void preOrderCopy(Node* R, Node* N);

   void postOrderDelete(Node* R);

   Node* search(Node* R, keyType k) const;

   Node* findMin(Node* R);

   Node* findMax(Node* R);

   Node* findNext(Node* N);

   Node* findPrev(Node* N);

   void transplant(Node* u, Node* v);

   void LeftRotate(Node* N);

   void RightRotate(Node* N);

   void RB_InsertFixUp(Node* N);

   void RB_Transplant(Node* u, Node* v);

   void RB_DeleteFixUp(Node* N);

   void RB_Delete(Node* N);


public:

   Dictionary();

   Dictionary(const Dictionary& D);

   ~Dictionary();


   int size() const;

   bool contains(keyType k) const;

   valType& getValue(keyType k) const;

   bool hasCurrent() const;

   keyType currentKey() const;

   valType& currentVal() const;


   void clear();

   void setValue(keyType k, valType v);

   void remove(keyType k);

   void begin();

   void end();

   void next();

   void prev();


   std::string to_string() const;

   std::string pre_string() const;

   bool equals(const Dictionary& D) const;


   friend std::ostream& operator<<( std::ostream& stream, Dictionary& D );

   friend bool operator==( const Dictionary& A, const Dictionary& B );

   Dictionary& operator=( const Dictionary& D );

};


#endif
