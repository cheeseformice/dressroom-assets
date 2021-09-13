#include <iostream>
#include <fstream>
#include "swflib.h"
using namespace std;

int main() {
  FILE *f = fopen("./Transformice.swf", "rb");
  if (f == nullptr) return 0;

  fseek(f, 0, SEEK_END);
  int size = ftell(f);
  rewind(f);

  uint8_t* start = (uint8_t*) malloc(sizeof(uint8_t) * size);
  uint8_t* end = start + size;

  fread(start, 1, size, f);
  fclose(f);

  auto stream = new swf::StreamReader(start, end);
  auto swf = new swf::Swf();
  swf->read(*stream);

  if (swf->abcfiles.count("frame1") == 0) {
    cout << "Game is in maintenance\n";
    return 1;
  }

  auto tag = swf->abcfiles.at("frame1");
  auto file = tag->abcfile;
  auto first_class = file->classes[0];

  for (auto trait : first_class.ctraits) {
    // Version is always the first static constant trait of the first class
    if (trait.kind == swf::abc::TraitKind::Const/* && trait.slot.kind == 6*/) {
      cout << "constant " << trait.index << "; " << trait.slot.kind;
      if (trait.slot.kind == 6)
        cout << "; " << file->cpool.doubles[trait.index];
      cout << "\n";
      // cout << "Found game version: " << file->cpool.doubles[trait.index] << "\n";
      // break;
    }
  }
  return 0;
}