# Checklists de troubleshooting Slurm

## 🔴 Job bloqué en PENDING

```
□ squeue → identifier le Reason
□ scontrol show job <JOBID> → détails complets
□ sinfo -N -l → état des nœuds
```

| Reason | Action |
|--------|--------|
| `Resources` | Vérifier CPUs/RAM demandés vs disponibles |
| `Nodes required... DRAINED` | Vérifier qui a drainé et pourquoi |
| `PartitionTimeLimit` | Réduire --time ou changer de partition |
| `QOSMaxJobsPerUserLimit` | Attendre fin d'un job ou augmenter la limite |
| `DependencyNeverSatisfied` | Vérifier le job parent avec sacct |
| `Priority` | Normal — attendre |

---

## 🔴 Job terminé mais pas de résultats

```
□ sacct -j <JOBID> --format=JobID,State,ExitCode → vérifier State et ExitCode
□ cat <fichier_output> → lire les erreurs
□ Vérifier si set -e est présent dans le script
□ docker exec c1 tail -20 /var/log/slurm/slurmd.log → vérifier job_rc
```

| ExitCode | Signification |
|----------|--------------|
| `0:0` | Succès apparent — vérifier si set -e manque |
| `127:0` | Commande introuvable |
| `1:0` | Erreur dans le script |
| `0:9` | Tué par Slurm (OOM ou timeout) |

---

## 🔴 Job refusé à la soumission

```
□ Lire le message d'erreur sbatch exactement
□ Vérifier --mem vs RealMemory des nœuds (sinfo -N -l)
□ Vérifier --partition existe (sinfo)
□ Vérifier --time vs MaxTime de la partition
□ Vérifier les droits de l'utilisateur (sacctmgr show user <user> withassoc)
```

---

## 🔴 Nœud ne répond plus

```
□ sinfo -N -l → confirmer état DOWN
□ ping <nœud> → tester connectivité réseau
□ ssh <nœud> → tenter connexion
□ ssh <nœud> systemctl status slurmd → vérifier le service
□ ssh <nœud> systemctl restart slurmd → redémarrer si tombé
□ scontrol update NodeName=<nœud> State=resume → réintégrer
□ Si pas de réponse réseau → intervention physique (iLO/iDRAC)
```

---

## 🔴 Cluster vide mais jobs ne démarrent pas

```
□ scontrol show job <JOBID> → vérifier MinCPUsNode, MinMemoryNode
□ sinfo -N -l → vérifier FREE_MEM et CPUS disponibles
□ sacctmgr show user <user> withassoc → vérifier limites QOS
□ Vérifier la partition demandée existe et a des nœuds
```

---

## 🔴 Utilisateur ne peut pas soumettre

```
□ Vérifier compte Linux : id <user>
□ Vérifier compte Slurm : sacctmgr show user <user>
□ Vérifier QOS assignée : sacctmgr show user <user> withassoc
□ Vérifier permissions sur /data/<user> : ls -la /data/
```

---

## 🔴 Pipeline de jobs bloqué

```
□ sacct --format=JobID,JobName,State,ExitCode → identifier quel job a échoué
□ cat <output_job_parent> → lire l'erreur du job parent
□ scancel les jobs DependencyNeverSatisfied
□ Corriger le script du job parent
□ Resoumettre le pipeline
```

---

## 📋 Commandes de diagnostic rapide

```bash
# Vue globale du cluster
sinfo -N -l

# Jobs en cours et en attente
squeue

# Détail d'un job
scontrol show job <JOBID>

# Historique des jobs
sacct -j <JOBID> --format=JobID,JobName,State,ExitCode,Elapsed

# Priorités
sprio -l

# Logs en temps réel
tail -f /var/log/slurm/slurmctld.log

# Logs d'un nœud
docker exec c1 tail -20 /var/log/slurm/slurmd.log

# Consommation d'un job actif
sstat -j <JOBID> --format=JobID,AveCPU,AveRSS,AveVMSize
```
