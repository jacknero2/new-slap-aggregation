#!/bin/bash
# Force locale to allow thousands separators (commas) in awk printf
export LC_ALL=en_US.UTF-8

OUTPUT_FILE="full_tables.tex"
DATA_DIR="slap_data"
TMP_8="table8_rows.tmp"
TMP_9="table9_rows.tmp"
USERS=1000
ITERS=100

# Create the data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Clear out any old temporary files
> "$TMP_8"
> "$TMP_9"

echo "Running SLAP benchmarks, saving raw data, and generating LaTeX tables..."

# Array of configurations matching the 4 active rows
configs=(
    "32 1 2048 NS Noise-Scaled"
    "32 1 4096 MS Message-Scaled"
    "64 2 2048 NS Noise-Scaled"
    "64 2 4096 MS Message-Scaled"
)

# Run the benchmarks ONCE per config
for config in "${configs[@]}"; do
    read -r t k N code name <<< "$config"
    
    # Define a clean filename for this specific configuration's raw data
    RAW_FILE="$DATA_DIR/raw_t${t}_k${k}_N${N}_${code}.txt"
    
    echo "  -> Benchmarking $name (t=$t, k'=$k, N=$N)... Saving to $RAW_FILE"
    
    # 1. Run the C++ program and save ALL output into the raw text file
    ./slap -r -p -t "$t" -k "$k" -N "$N" -n "$USERS" -c "$code" -i "$ITERS" > "$RAW_FILE"
    
    # 2. Read that raw text file with awk to do the math and build the LaTeX rows
    awk -v name="$name" -v t="$t" -v k="$k" -v N="$N" -v tmp8="$TMP_8" -v tmp9="$TMP_9" '
    BEGIN {
        enc_sum = 0; enc_count = 0;
        dec_sum = 0; dec_count = 0;
        plain_sum = 0; plain_count = 0;
        log_q = 64; # Default fallback
    }
    /^# \|q\|/          { log_q = $3 }
    /^rns_enc_overall:/ { enc_sum += $2; enc_count++ }
    /^rns_dec:/         { dec_sum += $2; dec_count++ }
    /^plain_agg /       { plain_sum += $2; plain_count++ }
    
    END {
        # Averages in ms
        avg_enc_ms = (enc_count > 0) ? (enc_sum / enc_count / 1000000) : 0
        avg_dec_ms = (dec_count > 0) ? (dec_sum / dec_count / 1000000) : 0
        avg_plain_ms = (plain_count > 0) ? (plain_sum / plain_count / 1000000) : 0
        
        # Slowdown vs. Plain calculation
        slowdown = 0
        if ((avg_enc_ms + avg_dec_ms) > 0) {
            slowdown = avg_plain_ms / (avg_enc_ms + avg_dec_ms)
        }
        
        # Ciphertext Size
        ctext_bits = N * log_q
        
        # --- 5 Mbps Math ---
        bw_5 = 5000000
        upload_s_5 = ctext_bits / bw_5
        upload_ms_5 = upload_s_5 * 1000
        up_per_sec_5 = (upload_s_5 > 0) ? (1 / upload_s_5) : 0
        throughput_5 = up_per_sec_5 * N * k
        
        # --- 25 Mbps Math ---
        bw_25 = 25000000
        upload_s_25 = ctext_bits / bw_25
        upload_ms_25 = upload_s_25 * 1000
        up_per_sec_25 = (upload_s_25 > 0) ? (1 / upload_s_25) : 0
        throughput_25 = up_per_sec_25 * N * k
        
        # Write Table 8 Row (10 columns)
        printf "       %s & %s & %s & %'\''d & %.2f & %.2f & %.2f & %.2f & %'\''d & %.2f \\\\ \n", name, t, k, N, avg_enc_ms, avg_dec_ms, upload_ms_5, up_per_sec_5, throughput_5, slowdown >> tmp8
        
        # Write Table 9 Row (8 columns)
        printf "       %s & %s & %s & %'\''d & %.2f & %.2f & %'\''d & %.2f \\\\ \n", name, t, k, N, upload_ms_25, up_per_sec_25, throughput_25, slowdown >> tmp9
    }' "$RAW_FILE"
done

# ==========================================
# ASSEMBLE TABLE 8 (5 Mbps)
# ==========================================
cat << 'EOF' > "$OUTPUT_FILE"
\begin{table*}\scriptsize
  \begin{center}
    \caption{Throughput of full-RNS \ours with 1000 users and 16-bit messages with 5 Mbps upload speed}
    \label{tab:plain-throughput-5mbps}
    \resizebox{\linewidth}{!}{
    \begin{tabular}{|r|r|r|r||r|r|r||r|r|r|}
    \hline
       Variant & $ \mid t \mid$ & $k'$ & $N$ & $NoisyEnc$ & $Agg$ & Upload Time (ms) & Ciphertext & \ours Throughput & Slowdown  \\
       & & & &(ms) & (ms) & at 5 Mbps & Uploads/s & (aggs/s) & vs. Plain \\
       \hline
EOF

cat "$TMP_8" >> "$OUTPUT_FILE"

cat << 'EOF' >> "$OUTPUT_FILE"
       \iffalse
       Noise-Scaled & 128 & 4 & 8,192 & 14.67 & 53.72 & 314.57 & 3.18 & 104,167 & 2.75 \\
       Message-Scaled & 128 & 4 & 16,384 & 52.46 & 188.19 & 754.96 & 1.32 & 104,167 & 3.31 \\ 
       
       Noise-Scaled & 192 & 7 & 8,192 & 15.31 & 54.54 & 419.43 & 2.38 & 136,718 & 1.20 \\
       Message-Scaled & 192 & 7 & 16,384 & 54.74 & 201.90 & 1468.01 & 0.68 & 78,124 & 2.10 \\ 
       \fi
       \hline
    \end{tabular}
    }
  \end{center}
\end{table*}

\vspace{1em}

EOF

# ==========================================
# ASSEMBLE TABLE 9 (25 Mbps)
# ==========================================
cat << 'EOF' >> "$OUTPUT_FILE"
\begin{table*}\scriptsize
  \begin{center}
    \caption{Throughput of full-RNS \ours with 1000 users and 16-bit messages with 25 Mbps upload speed} \color{red}
    \label{tab:plain-throughput-25mbps}
    \resizebox{\linewidth}{!}{
    \begin{tabular}{|r|r|r|r||r||r|r|r|}
    \hline
       Variant & $ \mid t \mid$ & $k'$ & $N$ & Upload Time (ms) & Ciphertext & SLAP Throughput & Slowdown vs. Plain \\
       & & & & at 25 Mbps & Uploads/s & (aggs/s) & \\
       \hline
EOF

cat "$TMP_9" >> "$OUTPUT_FILE"

cat << 'EOF' >> "$OUTPUT_FILE"
       \iffalse
       Noise-Scaled & 128 & 4 & 8,192 & 62.91 & 15.89 & 130,208 & 2.75 \\
       Message-Scaled & 128 & 4 & 16,384 & 150.99 & 6.62 & 108,506 & 3.31 \\ 
       
       Noise-Scaled & 192 & 7 & 8,192 & 83.89 & 11.92 & 170,897 & 1.20 \\
       Message-Scaled & 192 & 7 & 16,384 & 293.60 & 3.41 & 390,622 & 2.10 \\ 
       \fi
       \hline
    \end{tabular}
    }
  \end{center}
\end{table*}
EOF

# Clean up temporary files
rm "$TMP_8" "$TMP_9"

echo "Done! Raw data saved in ./$DATA_DIR/ and tables written to $OUTPUT_FILE."