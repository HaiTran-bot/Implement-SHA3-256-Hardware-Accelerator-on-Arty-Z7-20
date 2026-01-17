#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "sha3-256.h" 
#define SHA3_256_MD_LEN 32 // Độ dài đầu ra (256 bit = 32 byte)
#define MAX_INPUT_SIZE 1024 
int main() {
    char input[MAX_INPUT_SIZE];
    printf("Enter the input string (max %d characters): ", MAX_INPUT_SIZE - 1);
    if (fgets(input, sizeof(input), stdin) == NULL) {
        fprintf(stderr, "Error: Failed to read input.\n");
        return 1;
    }
    size_t input_length = strlen(input); // input_length = 1024
    if (input[input_length - 1] == '\n') {
        input[input_length - 1] = '\0';
        input_length--;
    }

  
    uint8_t data[input_length];
    memcpy(data, input, input_length);


    printf("Input string: %s\n", input);
    printf("Input length: %llu bytes\n", input_length);

    uint8_t hash[SHA3_256_MD_LEN] = { 0 };

    sha3_256_digest(data, input_length, hash); // data[n] la mot mang gom n phan tu, mot phan tu tu 0 ->255 bieu dien index ki tu trong bang ascii

    printf("Hashed output (SHA3-256): ");
    for (int i = 0; i < SHA3_256_MD_LEN; i++) {
        printf("%02x", hash[i]);
    }
    printf("\n");

    return 0;
}