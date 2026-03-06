#!/bin/bash

# Soumission du pipeline en 3 etapes

JOB1=$(sbatch /data/etape1.sh | awk '{print $4}')
echo "Etape 1 soumise - Job ID : $JOB1"

JOB2=$(sbatch --dependency=afterok:$JOB1 /data/etape2.sh | awk '{print $4}')
echo "Etape 2 soumise - Job ID : $JOB2 (attend $JOB1)"

JOB3=$(sbatch --dependency=afterok:$JOB2 /data/etape3.sh | awk '{print $4}')
echo "Etape 3 soumise - Job ID : $JOB3 (attend $JOB2)"

echo ""
echo "Pipeline complet : $JOB1 -> $JOB2 -> $JOB3"
echo "Suivre avec : squeue"
