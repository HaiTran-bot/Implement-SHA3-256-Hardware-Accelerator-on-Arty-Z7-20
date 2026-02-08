#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include "sha3-256.h" 
#define SHA3_256_MD_LEN 32 // Độ dài đầu ra (256 bit = 32 byte)
#define MAX_INPUT_SIZE 1024 
#define BENCHMARK_ITERATIONS 100000 
int main() {
    char input[MAX_INPUT_SIZE];
    printf("Enter the input string (max %d characters): ", MAX_INPUT_SIZE - 1);
    if (fgets(input, sizeof(input), stdin) == NULL) {
        fprintf(stderr, "Error: Failed to read input.\n");
        return 1;
    }
    size_t input_length = strlen(input); 
    if (input[input_length - 1] == '\n') {
        input[input_length - 1] = '\0';
        input_length--;
    }
  
    uint8_t data[input_length];
    memcpy(data, input, input_length);

    printf("Input string: %s\n", input);
    printf("Input length: %llu bytes\n", (unsigned long long)input_length);

    uint8_t hash[SHA3_256_MD_LEN] = { 0 };
    
    printf("\nRunning benchmark (%d iterations)...\n", BENCHMARK_ITERATIONS);
    
    clock_t start_time = clock(); 

    for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
        sha3_256_digest(data, input_length, hash); 
    }

    clock_t end_time = clock(); 

    double total_time_sec = (double)(end_time - start_time) / CLOCKS_PER_SEC;
    
    double total_time_us = total_time_sec * 1000000.0;
    double time_per_hash_us = total_time_us / BENCHMARK_ITERATIONS;

    printf("Hashed output (SHA3-256): ");
    for (int i = 0; i < SHA3_256_MD_LEN; i++) {
        printf("%02x", hash[i]);
    }
    printf("\n");

    printf("\n================ BENCHMARK RESULT (Microseconds) ================\n");
    printf("Total time for %d hashes: %.2f us\n", BENCHMARK_ITERATIONS, total_time_us);
    printf(">> AVERAGE TIME PER HASH:  %.4f us <<\n", time_per_hash_us);
    printf("=================================================================\n");

    return 0;
}
