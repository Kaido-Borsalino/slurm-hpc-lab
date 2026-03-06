#!/bin/bash

# Pipeline robuste avec gestion des erreurs

soumettre_job() {
    local script=$1
    local dependance=$2
    local jobid

    if [ -z "$dependance" ]; then
        jobid=$(sbatch $script | awk '{print $4}')
    else
        jobid=$(sbatch --dependency=afterok:$dependance $script | awk '{print $4}')
    fi

    if [ -z "$jobid" ]; then
        echo "ERREUR : impossible de soumettre $script"
        exit 1
    fi

    echo $jobid
}

JOB1=$(soumettre_job /data/etape1.sh)
echo "Etape 1 soumise - Job ID : $JOB1"

JOB2=$(soumettre_job /data/etape2.sh $JOB1)
echo "Etape 2 soumise - Job ID : $JOB2"

JOB3=$(soumettre_job /data/etape3.sh $JOB2)
echo "Etape 3 soumise - Job ID : $JOB3"

echo ""
echo "Pipeline : $JOB1 -> $JOB2 -> $JOB3"
