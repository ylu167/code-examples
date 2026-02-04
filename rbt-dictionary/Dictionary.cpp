#include<iostream>
#include<string>
#include<stdexcept>
#include"Dictionary.h"

Dictionary::Node::Node(keyType x, valType y){
    key = x;
    val = y;
    left = NULL;
    right = NULL;
    parent = NULL;
    color = 1;
}

Dictionary::Dictionary() {
    nil = new Node("", 0);
    root = nil;
    current = nil;
    num_pairs = 0;
}

Dictionary::Dictionary(const Dictionary& D) {
    nil = new Node("", 0);
    root = nil;
    current = nil;
    num_pairs = 0;
    preOrderCopy(D.root, D.nil);
}

Dictionary::~Dictionary() {
    clear();
    delete nil;
}

void Dictionary::inOrderString(std::string& s, Node* R) const {
    if (R != nil) {
        inOrderString(s, R->left);
        s+=R->key;
		s+=" : ";
		s+=std::to_string(R->val);
		s+="\n";
        inOrderString(s, R->right);
    }
}

void Dictionary::preOrderString(std::string& s, Node* R) const {
    if (R != nil) {
        s += R->key;
        s += "\n";
        preOrderString(s, R->left);
        preOrderString(s, R->right);
    }
}

void Dictionary::preOrderCopy(Node* R, Node* N) {
    if (R != N) {
        if (R != nil) {
            setValue(R->key, R->val);
            preOrderCopy(R->left, N);
            preOrderCopy(R->right, N);
        }
    }
}

void Dictionary::postOrderDelete(Node* R) {
    if (R != nil) {
        postOrderDelete(R->left);
        postOrderDelete(R->right);
        delete R;
        num_pairs--;
    }
}

Dictionary::Node* Dictionary::search(Node* R, keyType k) const {
    if (R == nil) {
        return nil;
    }
    if (R->key == k) {
        return R;
    }
    if (R->key < k) {
        return search(R->right, k);
    } else {
        return search(R->left, k);
    }
}

Dictionary::Node* Dictionary::findMin(Node* R) {
    if (this->num_pairs != 0) {
        while (R != nil && R->left != nil) {
            R = R->left;
        }
        return R;
    }
    return nil;
}

Dictionary::Node* Dictionary::findMax(Node* R) {
    if (this->num_pairs != 0) {
        while (R != nil && R->right != nil) {
            R = R->right;
        }
        return R;
    }
    return nil;
}

Dictionary::Node* Dictionary::findNext(Node* N) {
    if (N == nil || findMax(root) == N) {
        return nil;
    }
    if (N->right != nil) {
        return findMin(N->right);
    }
    Node* y = N->parent;
    while (y != nil && N == y->right) {
        N = y;
        y = y->parent;
    }
    return y;
}

Dictionary::Node* Dictionary::findPrev(Node* N) {
    if (N == nil || findMin(root) == N){
        return nil;
    }
    if (N->left != nil) {
        return findMax(N->left);
    }
    Node* y = N->parent;
    while (y != nil && N == y->left) {
        N = y;
        y = y->parent;
    }
    return y;
}

void Dictionary::transplant(Node* u, Node* v) {
    if (u->parent == nil) {
      root = v;
    } else if (u == u->parent->left) {
      u->parent->left = v;
    } else {
      u->parent->right = v;
    }
    if (v != nil) {
      v->parent = u->parent;
    }
}

void Dictionary::LeftRotate(Node* N) {
    Node* y = N->right;
    
    N->right = y->left;
    if (y->left != nil) {
        y->left->parent = N;
    }
    
    y->parent = N->parent;
    if (N->parent == nil) {
        root = y;
    } else if (N == N->parent->left) {
        N->parent->left = y;
    } else {
        N->parent->right = y;
    }
    y->left = N;
    N->parent = y;
}

void Dictionary::RightRotate(Node* N) {
    Node* y = N->left;
    
    N->left = y->right;
    if (y->right != nil) {
        y->right->parent = N;
    }
    y->parent = N->parent;
    if (N->parent == nil) {
        root = y;
    } else if (N == N->parent->right) {
        N->parent->right = y;
    } else {
        N->parent->left = y;
    }
    y->right = N;
    N->parent = y;
}

void Dictionary::RB_InsertFixUp(Node* N) {
    while (N->parent->color == 0) {
        if (N->parent == N->parent->parent->left) {
            Node* y = N->parent->parent->right;
            if (y->color == 0) {
                N->parent->color = 1;
                y->color = 1;
                N->parent->parent->color = 0;
                N = N->parent->parent;
            } else {
                if (N == N->parent->right) {
                  N = N->parent;
                  LeftRotate(N);
                }
                N->parent->color = 1;
                N->parent->parent->color = 0;
                RightRotate(N->parent->parent);
            }
        } else {
            Node* y = N->parent->parent->left;
            if (y->color == 0) {
                N->parent->color = 1;
                y->color = 1;
                N->parent->parent->color = 0;
                N = N->parent->parent;
            } else {
                if (N == N->parent->left) {
                  N = N->parent;
                  RightRotate(N);
                }
                N->parent->color = 1;
                N->parent->parent->color = 0;
                LeftRotate(N->parent->parent);
            }
        }
    }
    root->color = 1;
}

void Dictionary::RB_Transplant(Node* u, Node* v) {
    if (u->parent == nil)
      root = v;
    else if (u == u->parent->left)
      u->parent->left = v;
    else 
      u->parent->right = v;
    v->parent = u->parent;
}

void Dictionary::RB_DeleteFixUp(Node* N) {
    while (N != root and N->color == 1) {
      if (N == N->parent->left) {
          Node* w = N->parent->right;
          if (w->color == 0) {
              w->color = 1;
              N->parent->color = 0;
              LeftRotate(N->parent);
              w = N->parent->right;
          }
          if (w->left->color == 1 and w->right->color == 1) {
              w->color = 0;
              N = N->parent;
          } else {
              if (w->right->color == 1) {
                w->left->color = 1;
                w->color = 0;
                RightRotate(w);
                w = N->parent->right;
              }
              w->color = N->parent->color;
              N->parent->color = 1;
              w->right->color = 1;
              LeftRotate(N->parent);
              N = root;
          }
      } else {
          Node* w = N->parent->left;
          if (w->color == 0) {
              w->color = 1;
              N->parent->color = 0;
              RightRotate(N->parent);
              w = N->parent->left;
          }
          if (w->right->color == 1 and w->left->color == 1) {
              w->color = 0;
              N = N->parent;
          } else {
              if (w->left->color == 1) {
                w->right->color = 1;
                w->color = 0;
                LeftRotate(w);
                w = N->parent->left;
              }
              w->color = N->parent->color;
              N->parent->color = 1;
              w->left->color = 1;
              RightRotate(N->parent);
              N = root;
          }
      }
    }
    N->color = 1;
}

void Dictionary::RB_Delete(Node* N) {
    Node* y = N;
    Node* x;
    int y_original_color = y->color;
    if (N->left == nil) {
        x = N->right;
        RB_Transplant(N, N->right);
    } else if (N->right == nil) {
        x = N->left;
        RB_Transplant(N, N->left);
    } else {
        y = findMin(N->right);
        y_original_color = y->color;
        x = y->right;
        if (y->parent == N) {
          x->parent = y;
        } else {
          RB_Transplant(y, y->right);
          y->right = N->right;
          y->right->parent = y;
        }
        RB_Transplant(N, y);
        y->left = N->left;
        y->left->parent = y;
        y->color = N->color;
    }
    if (y_original_color == 1) {
        RB_DeleteFixUp(x);
    }
}

int Dictionary::size() const {
    return num_pairs;
}

bool Dictionary::contains(keyType k) const {
    return (search(root, k) != nil);
}

valType& Dictionary::getValue(keyType k) const {
    if (contains(k)) {
        Node* N = search(root, k);
        return N -> val;
    }
    throw std::logic_error("Dictionary: getValue(): key doesn't exist");
}

bool Dictionary::hasCurrent() const {
    return current != nil;
}

keyType Dictionary::currentKey() const {
    if(hasCurrent()) {
        return current->key;
    }
    throw std::logic_error("Dictionary: currentKey(): current doesn't exist");
}

valType& Dictionary::currentVal() const {
    if(hasCurrent()) {
        return current->val;
    }
    throw std::logic_error("Dictionary: currentVal(): current doesn't exist");
}

void Dictionary::clear() {
    postOrderDelete(root);
    root = nil;
    current = nil;
    num_pairs = 0;
}

void Dictionary::setValue(keyType k, valType v) {
    Node* newN = new Node(k, v);
    Node* start = root;
    Node* temp = nil;
    if (this->num_pairs == 0) {
        root = newN;
        newN->parent = nil;
    } else {
        while(start != nil) {
            temp = start;
            if (k == start->key) {
                start->val = v;
                return;
            } else if(k < start->key) {
                newN->parent = start;
                start = start->left;
            } else {
                newN->parent = start;
                start = start->right;
            }
        }
        if (k < temp->key) {
            temp->left = newN;
        } else {
            temp->right = newN;
        }
    }
    newN->left = nil;
    newN->right = nil;
    newN->color = 0;
    RB_InsertFixUp(newN);
    num_pairs++;
}

void Dictionary::remove(keyType k) {
    if (contains(k)) {
        Node* z = search(root, k);
        if (current == z) current = nil;
        RB_Delete(z);
        num_pairs--;
    } else {
        throw std::logic_error("Dictionary: remove(): key \"" + k + "\" does not exist");
    }
}

void Dictionary::begin() {
    if (this->num_pairs > 0) {
        current = findMin(root);
    }
}

void Dictionary::end() {
    if (this->num_pairs > 0) {
        current = findMax(root);
    }
}

void Dictionary::next() {
    if(hasCurrent()) {
        if(current == findMax(root)) {
            current = nil;
        } else {
            current = findNext(current);
        }
    }
}

void Dictionary::prev() {
    if(hasCurrent()) {
        if(current == findMin(root)) {
            current = nil;
        } else {
            current = findPrev(current);
        }
    }
}

std::string Dictionary::to_string() const {
    std::string s = "";
    inOrderString(s,root);
    return s;
}

std::string Dictionary::pre_string() const {
    std::string s = "";
    preOrderString(s,root);
    return s;
}

bool Dictionary::equals(const Dictionary& D) const {
    bool eq = false;
    std::string s = D.to_string();
    std::string s_this = (*this).to_string();
    eq = (this->num_pairs == D.num_pairs);
    if (eq && s == s_this) {
        return true;
    }
    return false;
}

std::ostream& operator<<( std::ostream& stream, Dictionary& D ) {
    return stream << D.Dictionary::to_string();
}

bool operator==( const Dictionary& A, const Dictionary& B ) {
    return A.Dictionary::equals(B);
}

Dictionary& Dictionary::operator=( const Dictionary& D ) {
    if( this != &D ){
      Dictionary temp = D;

      std::swap(nil, temp.nil);
      std::swap(root, temp.root);
      std::swap(current, temp.current);
      std::swap(num_pairs, temp.num_pairs);
   }

   return *this;
}
