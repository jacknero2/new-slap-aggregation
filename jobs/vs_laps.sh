#!/bin/bash

#$ -M jtakeshi@nd.edu
#$ -m abe
#$ -q *@@jung
#$ -pe smp 1
#$ -N vs_laps
#

SCHEMES=("NS", "MS")
BACKENDS="-g -r -p"
#Run from root directory
EXECUTABLE=./slap
PLAIN_SIZE=32
MESSAGE_SIZE=16
NUM_USERS=1000
ITERATIONS=100


SUBFOLDER=laps_comparison_final_32_16_final

mkdir -p ./results/${SUBFOLDER}/
module load gcc/9.1.0

time $EXECUTABLE -t $PLAIN_SIZE -w $MESSAGE_SIZE -n $NUM_USERS -i $ITERATIONS $BACKENDS -c NS > ./results/${SUBFOLDER}/laps_vs_NS.txt
time $EXECUTABLE -t $PLAIN_SIZE -w $MESSAGE_SIZE -n $NUM_USERS -i $ITERATIONS $BACKENDS -c MS > ./results/${SUBFOLDER}/laps_vs_MS.txt

python stats.py ./results/${SUBFOLDER}/*.txt > ./results/${SUBFOLDER}/laps.rep