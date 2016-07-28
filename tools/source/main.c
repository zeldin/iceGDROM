#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

#include "msg.h"
#include "imgfile.h"

int main(int argc, char *argv[])
{
  if (argc != 3) {
    fprintf(stderr, "Usage: %s inputfile outputfile\n", argv[0]);
    return 1;
  }
  return imgfile_create_from_source(argv[1], argv[2])? 0 : 1;
}
