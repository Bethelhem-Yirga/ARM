#include <stdio.h>
#include <stdlib.h>

void hello() {
    printf("You redirected execution!\n");
    exit(0);
}

int main() {
    char buffer[8];
    gets(buffer);
    printf("Normal return.\n");
    return 0;
}