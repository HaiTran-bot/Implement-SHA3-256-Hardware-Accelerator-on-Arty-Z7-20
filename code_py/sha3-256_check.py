# ==============================================================================
# TOOL TẠO INTERNAL STATE SHA3-256 (Format Little Endian cho Testbench)
# ==============================================================================
import time

def run_keccak_tool(input_string):
    # 1. Cấu hình hằng số Keccak (Round Constants)
    RC = [
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
        0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
        0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
        0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
        0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008
    ]

    # Hàm xoay bit trái 64-bit
    def rol64(a, n):
        return ((a >> (64 - (n % 64))) + (a << (n % 64))) % (1 << 64)

    # Hàm hoán vị Keccak-f[1600]
    def keccak_f1600(lanes):
        R = 1
        for round_idx in range(24):
            # Theta
            C = [lanes[x][0] ^ lanes[x][1] ^ lanes[x][2] ^ lanes[x][3] ^ lanes[x][4] for x in range(5)]
            D = [C[(x - 1) % 5] ^ rol64(C[(x + 1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    lanes[x][y] ^= D[x]

            # Rho & Pi
            x, y = 1, 0
            current = lanes[1][0]
            for t in range(24):
                x, y = y, (2 * x + 3 * y) % 5
                current, lanes[x][y] = lanes[x][y], rol64(current, (t + 1) * (t + 2) // 2)

            # Chi
            for y in range(5):
                T = [lanes[x][y] for x in range(5)]
                for x in range(5):
                    lanes[x][y] = T[x] ^ ((~T[(x + 1) % 5]) & T[(x + 2) % 5])

            # Iota
            lanes[0][0] ^= RC[round_idx]
        return lanes

    # --- BẮT ĐẦU ĐO THỜI GIAN ---
    start_time = time.perf_counter()

    # 2. Xử lý Input & Padding (SHA3-256)
    # Rate = 1088 bits = 136 bytes
    rate_bytes = 136
    input_bytes = input_string.encode('utf-8')
    
    # Padding rule: 0x06 ... 0x80
    padded = bytearray(input_bytes)
    padded.append(0x06) # Domain separation for SHA3
    while len(padded) % rate_bytes != (rate_bytes - 1):
        padded.append(0x00)
    padded.append(0x80)

    # 3. Chuyển đổi thành State 5x5 (Format 64-bit lanes)
    state = [[0] * 5 for _ in range(5)]
    
    # Absorb (XOR input vào state)
    # Chia thành các block 136 byte (1088 bit)
    for i in range(0, len(padded), rate_bytes):
        block = padded[i:i+rate_bytes]
        # Chuyển block thành các từ 64-bit và XOR vào state
        for j in range(0, len(block), 8):
            word_bytes = block[j:j+8]
            # Input là byte array, chuyển thành int 64-bit (Little Endian khi đọc vào)
            word_val = int.from_bytes(word_bytes, 'little')
            
            x = (j // 8) % 5
            y = (j // 8) // 5
            state[x][y] ^= word_val
        
        # Sau khi XOR xong 1 block thì chạy Keccak-f
        state = keccak_f1600(state)
        
    # --- KẾT THÚC ĐO THỜI GIAN ---
    end_time = time.perf_counter()
    execution_time = end_time - start_time
    
    # Tính ra nanoseconds (1 giây = 1,000,000,000 ns)
    execution_time_ns = execution_time * 1_000_000_000

    # 4. Xuất kết quả format Little Endian (như file text của bạn)
    print(f"\n---> INPUT STRING: \"{input_string}\"")
    print(f"---> KẾT QUẢ (400 ký tự Hex):")
    
    result_str = ""
    for y in range(5):
        for x in range(5):
            val = state[x][y]
            hex_bytes = val.to_bytes(8, 'little')
            result_str += hex_bytes.hex()
            
    print(result_str)
    print("-" * 50)
    
    # IN RA CẢ GIÂY VÀ NANOSECONDS
    print(f"\033[1;36m[Time Info] SHA3 calculation executed in: {execution_time:.9f} seconds ({execution_time_ns:.0f} ns)\033[0;1m")

# ==============================================================================
# NHẬP STRING CỦA BẠN VÀO ĐÂY VÀ CHẠY
# ==============================================================================

# Testcase 1
run_keccak_tool("Pham Kieu Nhat Anh")



# Testcase 2 (Bạn có thể bỏ comment để chạy thử)

run_keccak_tool("Tran Tan Hai")

run_keccak_tool("Dong Nguyen Khanh Duy")

run_keccak_tool("Le Ngoc Uy Phong")

print(f"case 1: faster {374400/1820:.2f} times")
print(f"case 2: faster {886900/1740:.2f} ")
print(f"case 3: faster {357900/1810:.2f} ")
print(f"case 4: faster {357900/1780:.2f} ")