#!/bin/bash

# Output file
OUTPUT_FILE="results.txt"

# Number of users and iterations
USERS=1000
ITERS=100

# Initialize the results file with a neat table header
echo "Generating SLAP benchmarks..."
echo "=========================================================================================" > $OUTPUT_FILE
printf "| %-15s | %-3s | %-2s | %-5s | %-13s | %-10s | %-12s | %-8s |\n" "Variant" "|t|" "k'" "N" "NoisyEnc (ms)" "Agg (ms)" "Plain (ms)" "Slowdown" >> $OUTPUT_FILE
echo "-----------------------------------------------------------------------------------------" >> $OUTPUT_FILE

# Array of configurations representing the rows in the tables
# Format: "t k_prime N Variant_Code Variant_Name"
configs=(
    "32 1 2048 NS Noise-Scaled"
    "32 1 4096 MS Message-Scaled"
    "64 2 2048 NS Noise-Scaled"
    "64 2 4096 MS Message-Scaled"
)

# Loop through each configuration
for config in "${configs[@]}"; do
    # Read variables from the config string
    read -r t k N code name <<< "$config"
    
    echo "Running: $name (|t|=$t, k'=$k, N=$N) with $ITERS iterations..."
    
    # Execute the C++ binary and pipe the standard output directly into awk for processing
    ./slap -r -p -t "$t" -k "$k" -N "$N" -n "$USERS" -c "$code" -i "$ITERS" | awk -v name="$name" -v t="$t" -v k="$k" -v N="$N" '
    BEGIN {
        enc_sum = 0; enc_count = 0;
        dec_sum = 0; dec_count = 0;
        plain_sum = 0; plain_count = 0;
    }
    /^rns_enc_overall:/ { enc_sum += $2; enc_count++ }
    /^rns_dec:/         { dec_sum += $2; dec_count++ }
    /^plain_agg /       { plain_sum += $2; plain_count++ }
    
    END {
        # Calculate averages in nanoseconds
        avg_enc_ns = (enc_count > 0) ? (enc_sum / enc_count) : 0
        avg_dec_ns = (dec_count > 0) ? (dec_sum / dec_count) : 0
        avg_plain_ns = (plain_count > 0) ? (plain_sum / plain_count) : 0
        
        # Convert to milliseconds
        avg_enc_ms = avg_enc_ns / 1000000
        avg_dec_ms = avg_dec_ns / 1000000
        avg_plain_ms = avg_plain_ns / 1000000
        
        # Calculate Slowdown: (NoisyEnc + Agg) / Plain Agg
        # Note: Adjust this formula if your paper uses a different baseline ratio!
        slowdown = 0
        if (avg_plain_ns > 0) {
            slowdown = (avg_enc_ns + avg_dec_ns) / avg_plain_ns
        }
        
        # Print the formatted row to stdout (which gets appended to the file)
        printf "| %-15s | %-3s | %-2s | %-5s | %-13.2f | %-10.2f | %-12.2f | %-8.2f |\n", name, t, k, N, avg_enc_ms, avg_dec_ms, avg_plain_ms, slowdown
    }' >> $OUTPUT_FILE

done

echo "=========================================================================================" >> $OUTPUT_FILE
echo "Done! Results saved to $OUTPUT_FILE"