#!/bin/bash

#$ -M jtakeshi@nd.edu
#$ -m abe
#$ -q *@@jung
#$ -pe smp 1
#$ -N tab_1_larger
#

SCHEMES=("NS", "MS")
BACKENDS="-r -g -p"
#Run from root directory
EXECUTABLE=./slap
ITERATIONS=5


SUBFOLDER=tab_1

mkdir -p ./results/${SUBFOLDER}/
module load gcc/9.1.0

PLAIN=128
USERS=10000

time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c NS > ./results/${SUBFOLDER}/${PLAIN}_${USERS}_NS.txt
time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c MS > ./results/${SUBFOLDER}/${PLAIN}_${USERS}_MS.txt
python stats.py ./results/${SUBFOLDER}/${PLAIN}_${USERS}_*.txt > ./results/${SUBFOLDER}/${PLAIN}_${USERS}.rep
echo "Finished ${PLAIN} ${USERS}"

USERS=10e15

time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c NS > ./results/${SUBFOLDER}/${PLAIN}_${USERS}_NS.txt
time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c MS > ./results/${SUBFOLDER}/{PLAIN}_${USERS}_MS.txt
python stats.py ./results/${SUBFOLDER}/${PLAIN}_${USERS}_*.txt > ./results/${SUBFOLDER}/${PLAIN}_${USERS}.rep
echo "Finished ${PLAIN} ${USERS}"

USERS=10e21

time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c NS > ./results/${SUBFOLDER}/${PLAIN}_${USERS}_NS.txt
time $EXECUTABLE -t $PLAIN -n $USERS -i $ITERATIONS $BACKENDS -c MS > ./results/${SUBFOLDER}/{PLAIN}_${USERS}_MS.txt
python stats.py ./results/${SUBFOLDER}/${PLAIN}_${USERS}_*.txt > ./results/${SUBFOLDER}/${PLAIN}_${USERS}.rep
echo "Finished ${PLAIN} ${USERS}"

