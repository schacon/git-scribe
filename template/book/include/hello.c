#include <stdio.h>

main()
{
  char hex[] = "599955586da1c3ad514f3e65f1081d2012ec862d";
  git_oid oid;

  git_oid_mkstr(&oid, hex);
  printf("Raw 20 bytes: [%s]\n", (&oid)->id);
}
