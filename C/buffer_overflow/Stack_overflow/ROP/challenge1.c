#include <stdio.h>
#include <string.h>

void func1(char *input) {
    char buffer[64];
    strcpy(buffer, input);  // No bounds checking!
}

int main(int argc, char **argv) {
    func1(argv[1]);
    return 0;
}