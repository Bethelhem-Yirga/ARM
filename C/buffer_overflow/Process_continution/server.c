// server.c - ARM version
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

int request_ready = 0;
int total_connections = 0;

void process_request(char *input) {
    char buffer[16];
    printf("[Server] Processing request: %s\n", input);
    strcpy(buffer, input); // VULNERABLE
    printf("[Server] Request processed.\n");
}

void server_loop(int server_fd) {
     printf("[Server] Loop started on fd %d\n", server_fd);
    
     while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);

        printf("[Server] Waiting for connection...\n");
        int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) continue;

        printf("[Server] Client connected!\n");

        char input[256];
        int n = read(client_fd, input, 255);
        if (n > 0) {
            input[n] = 0;
            request_ready = 1;
            total_connections = 1;
            process_request(input);
            request_ready = 0;
            total_connections = 0;
 }

        close(client_fd);
        printf("[Server] Ready for next connection.\n\n");
     }
}

int main() {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

     struct sockaddr_in addr;
     addr.sin_family = AF_INET;
     addr.sin_addr.s_addr = INADDR_ANY;
     addr.sin_port = htons(9999);

    bind(server_fd, (struct sockaddr *)&addr, sizeof(addr));
    listen(server_fd, 5);

    printf("=== Vulnerable Server v1.0 (ARM) ===\n");
    printf("Listening on port 9999\n");

    server_loop(server_fd);
    return 0;

}