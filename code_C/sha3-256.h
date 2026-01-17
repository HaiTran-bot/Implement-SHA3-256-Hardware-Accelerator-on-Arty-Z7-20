#pragma once

#include <stdint.h>
#include <stddef.h>
#ifndef ROTL64
#define ROTL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))
#endif
#define SHA3_256_MD_LEN 32      // 256-bit digest length in bytes. (256/8)
#define SHA3_256_ROUNDS 24 //round for performing SHA3-256
#define SHA3_256_SIZE 200 // 1600-bit width in bytes. (1600/8)
#define SHA3_256_RATE 136 //b = r + c (c is 512 so r = 1600 - 512 = 1088) but this is in byte
#define SHA3_256_LANES  25      //State is an unrolled 5x5 array of 64-bit lanes.

// state context
struct sha3_256 {
    int padpoint; //point of padding
    int absorbed; 
    union {                                 // state:
        uint8_t bytes[SHA3_256_SIZE];                     // 8-bit bytes
        uint64_t words[SHA3_256_LANES];                     // 64-bit words
    } state;
};

struct sha3_256 sha3_256_new(void);

void sha3_256_update(struct sha3_256 *ctx, uint8_t *data, uint64_t n); //
void sha3_256_finalize(struct sha3_256 *ctx, uint8_t *digest); // digest goes padding
void sha3_256_digest(uint8_t *data, uint64_t n, uint8_t *digest);  //process digest


