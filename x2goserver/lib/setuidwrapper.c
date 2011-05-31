#include <unistd.h>
#include <stdio.h>

#define myfile "test.py"

main(argc, argv)
char **argv;
{
    setuid(0);
    seteuid(0);
    execv(myfile, argv);
}
