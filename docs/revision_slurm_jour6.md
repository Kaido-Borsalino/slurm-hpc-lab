# Fiches de révision — Monitoring et Troubleshooting
### Session du 05 mars 2026

---

## 1. Les fichiers de log Slurm

```bash
grep -i logfile /etc/slurm/slurm.conf
# → SlurmctldLogFile=/var/log/slurm/slurmctld.log
# → SlurmdLogFile=/var/log/slurm/slurmd.log
```

| Fichier | Contenu |
|---------|---------|
| `slurmctld.log` | Décisions du scheduler, allocations, erreurs de config |
| `slurmd.log` | Exécution des jobs sur les nœuds, erreurs matérielles |

---

## 2. Niveaux de log

| Niveau | Signification |
|--------|--------------|
| `debug2` | Très verbeux — activité normale banale |
| `debug` | Activité normale importante |
| `info` | Événements importants |
| `warning` | À surveiller |
| `error` | Action requise |

Configurable dans `slurm.conf` :
```
SlurmctldDebug=info    # ne logge que info et au dessus
```

---

## 3. Commandes de monitoring essentielles

**Lire les dernières lignes d'un log :**
```bash
tail -20 /var/log/slurm/slurmctld.log
```

**Suivre un log en temps réel :**
```bash
tail -f /var/log/slurm/slurmctld.log
```
`Ctrl+C` pour arrêter.

**Filtrer uniquement les erreurs et warnings :**
```bash
grep -E "warning|error" /var/log/slurm/slurmctld.log | tail -20
```

**Lire les logs d'un nœud depuis le serveur :**
```bash
docker exec c1 tail -20 /var/log/slurm/slurmd.log
# En production :
ssh c1 tail -20 /var/log/slurm/slurmd.log
```

---

## 4. Procédure de diagnostic — job bloqué

Ordre des commandes du général au particulier :

```bash
# 1. Identifier le symptôme
squeue

# 2. Détails complets du job
scontrol show job <JOBID>

# 3. État de l'infrastructure
sinfo -N -l
```

**Raisons courantes dans squeue :**

| Raison | Cause | Action |
|--------|-------|--------|
| `Nodes required... DRAINED` | Nœuds drainés | Vérifier qui a drainé et pourquoi |
| `PartitionTimeLimit` | Job trop long pour la partition | Orienter vers partition `long` |
| `Resources` | Attend que des ressources se libèrent | Normal, attendre |
| `Priority` | Attend derrière un job prioritaire | Normal, attendre |
| `DependencyNeverSatisfied` | Job parent a échoué | Annuler et corriger le pipeline |

---

## 5. Lire les logs d'un job dans slurmd.log

La ligne clé à chercher :
```
JobId=62 completed with slurm_rc = 0, job_rc = 0
```

| Valeur | Signification |
|--------|--------------|
| `slurm_rc = 0` | Slurm a géré le job sans erreur |
| `job_rc = 0` | Le job s'est terminé avec succès |
| `slurm_rc ≠ 0` | Problème infrastructure |
| `job_rc ≠ 0` | Problème dans le code du chercheur |

---

## 6. `set -e` dans les scripts

Sans `set -e` — bash continue après une erreur :
```bash
echo "Debut"
commande_inexistante    # erreur ignorée
echo "Fin"              # s'affiche quand même
# → State: COMPLETED, ExitCode: 0:0  ← faux succès
```

Avec `set -e` — bash s'arrête à la première erreur :
```bash
set -e
echo "Debut"
commande_inexistante    # bash s'arrête ici
echo "Fin"              # ne s'affiche jamais
# → State: FAILED, ExitCode: 127:0  ← échec détecté
```

**ExitCode 127** = commande introuvable (code Linux standard)

**Règle** : toujours mettre `set -e` dans les scripts de production.

---

## 7. Gestion de la mémoire

**Déclarer la mémoire dans un script :**
```bash
#SBATCH --mem=500M     # 500 MB
#SBATCH --mem=2G       # 2 GB
```

**Ce qui se passe si tu demandes trop :**
```
sbatch: error: Memory specification can not be satisfied
sbatch: error: Batch job submission failed
```
Slurm refuse immédiatement à la soumission — le job n'entre même pas dans la queue.

**Surveiller la consommation mémoire en temps réel :**
```bash
sstat -j <JOBID> --format=JobID,AveCPU,AveRSS,AveVMSize
```

| Champ | Signification |
|-------|--------------|
| `AveCPU` | Temps CPU moyen consommé |
| `AveRSS` | RAM réellement utilisée |
| `AveVMSize` | Mémoire virtuelle réservée |

**RSS vs Mémoire virtuelle :**
- **Mémoire virtuelle** = ce que le programme réserve
- **RSS** = ce qu'il utilise vraiment
- En HPC on surveille la **RSS** — si elle dépasse la RAM physique → OOM Killer tue le job

---

## 8. Pourquoi pas de swap en HPC

- Le swap utilise le disque — 100 000x plus lent que la RAM
- Un job qui swapper devient inutilisablement lent (**thrashing**)
- Sur un nœud partagé, le swap d'un job dégrade tous les autres
- Sans swap, les problèmes mémoire sont détectés immédiatement

**Règle HPC** : pas de swap. Si besoin de plus de RAM → nœud `highmem` ou optimisation du code.

---

## 9. Scénarios de troubleshooting courants

**Scénario 1 — Job bloqué (nœuds drainés)**
```
squeue → PD, Nodes required... DRAINED
sinfo -N -l → nœuds drained avec raison
Action → vérifier avec collègues, scontrol update State=resume
```

**Scénario 2 — Job qui plante silencieusement**
```
sacct → COMPLETED ExitCode 0:0 mais pas de résultats
Fichier de sortie → erreur visible mais script a continué
Action → ajouter set -e dans le script
```

**Scénario 3 — Job refusé pour mémoire**
```
sbatch → Memory specification can not be satisfied
Action → réduire --mem ou orienter vers nœud highmem
```

---

## 10. Récapitulatif des 6 sessions

| Session | Thème |
|---------|-------|
| 1 | Utilisation — srun, sbatch, squeue, scancel, sacct |
| 2 | Configuration — slurm.conf, partitions, limites, permissions |
| 3 | Administration — états nœuds, priorités, fairshare, QOS |
| 4 | Automatisation — chaînage de jobs, scripts admin, rapports |
| 5 | Stockage et environnement — NFS, Environment Modules |
| 6 | Monitoring et troubleshooting — logs, diagnostics, pannes |

**Prochaine session :** Projet intégrateur — monter un cluster from scratch, documenter sur GitHub, préparer l'entretien
