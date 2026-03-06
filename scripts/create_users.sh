#!/bin/bash

while read utilisateur; do
    echo "Traitement de : $utilisateur"
    
    useradd -m $utilisateur
    echo "  [OK] Utilisateur Linux créé"

    mkdir -p /data/$utilisateur
    echo "  [OK] Répertoire créé"

    chown $utilisateur:$utilisateur /data/$utilisateur
    echo "  [OK] Permissions assignées"

    sacctmgr -i add account $utilisateur description="Compte $utilisateur"
    sacctmgr -i add user $utilisateur account=$utilisateur defaultaccount=$utilisateur
    echo "  [OK] Compte Slurm créé"

    sacctmgr -i modify user $utilisateur set qos=chercheur defaultqos=chercheur
    echo "  [OK] QOS assignée"

    echo "Utilisateur $utilisateur configuré avec succès"
    echo "---"

done < /data/nouveaux_users.txt
