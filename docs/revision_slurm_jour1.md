# Fiches de révision — Slurm & HPC
### Session du 26 février 2026

---

## 1. C'est quoi le HPC ?

Le **High Performance Computing** c'est l'utilisation de clusters de machines pour résoudre des problèmes complexes qui nécessitent une grande puissance de calcul — simulations, IA, bioinformatique, météo, finance.

Un cluster c'est un ensemble de machines connectées entre elles qui travaillent ensemble comme une seule entité.

---

## 2. Architecture d'un cluster Slurm

| Composant | Rôle | Analogie K8s |
|-----------|------|--------------|
| **slurmctld** | Cerveau du cluster — schedule et contrôle | kube-scheduler + controller-manager |
| **slurmd** | Tourne sur chaque nœud de calcul, exécute les jobs | kubelet |
| **slurmdbd** | Intermédiaire entre Slurm et la base de données | — |
| **MySQL/MariaDB** | Stocke l'historique et la comptabilité des jobs | ≠ etcd (comptabilité seulement, pas état du cluster) |
| **slurmrestd** | Expose Slurm en API HTTP | kube-apiserver |

> **Différence clé avec K8s** : Si MySQL tombe, le cluster Slurm continue de tourner. Dans K8s, si etcd tombe, tout s'arrête. MySQL dans Slurm c'est de la comptabilité, pas de l'état.

---

## 3. Pourquoi MariaDB et pas MySQL ?

MariaDB est un **fork open source de MySQL** créé en 2010 quand Oracle a racheté MySQL. Ils sont **100% compatibles** — même commandes, même syntaxe. Sur la plupart des distributions Linux (Rocky, RHEL, CentOS), installer "mysql" donne MariaDB.

---

## 4. Les commandes essentielles

### `sinfo` — État du cluster
```bash
sinfo
```
```
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up   infinite      2   idle c[1-2]
```
- `*` = partition par défaut
- `idle` = nœuds disponibles
- `alloc` = nœuds occupés
- `down` = nœuds hors service

---

### `squeue` — File d'attente
```bash
squeue
```
```
JOBID PARTITION  NAME  USER ST  TIME  NODES NODELIST(REASON)
  11    normal  job_long root  R  0:10    2  c[1-2]
   7    normal  test     root PD  0:00    2  (Resources)
   8    normal  test     root PD  0:00    2  (Priority)
```
**États (ST) :**
- `R` = Running (en cours)
- `PD` = Pending (en attente)
- `CG` = Completing (en train de se terminer)

**Raisons en attente :**
- `Resources` = prochain dans la file, attend que les ressources se libèrent
- `Priority` = attend derrière un job qui a déjà la priorité sur les ressources

---

### `srun` — Exécution interactive (tu attends le résultat)
```bash
srun -N1 hostname          # Exécute hostname sur 1 nœud
srun -N2 hostname          # Exécute hostname sur 2 nœuds en parallèle
srun -N2 -l hostname       # Même chose avec le numéro de tâche (task ID)
```
- `-N` = nombre de nœuds
- `-l` = affiche le task ID devant chaque ligne de résultat
- Tu restes **bloqué** devant ton terminal jusqu'à la fin

---

### `sbatch` — Soumission différée (tu n'attends pas)
```bash
sbatch mon_script.sh
# → Submitted batch job 4
```
- Tu soumets un script, Slurm le met en file d'attente
- Le terminal te rend la main **immédiatement**
- Le résultat s'écrit dans un fichier

---

### `scancel` — Annuler un job
```bash
scancel 11          # Annule le job ID 11
scancel -u root     # Annule tous les jobs de l'utilisateur root
```

---

### `sacct` — Historique et comptabilité
```bash
sacct                                                          # Tout l'historique
sacct -j 4                                                     # Un job spécifique
sacct -j 4 --format=JobID,JobName,State,Elapsed,AllocCPUS,ExitCode
```
**États possibles :**
- `COMPLETED` = terminé normalement
- `CANCELLED` = annulé manuellement
- `FAILED` = terminé en erreur

**ExitCode** : `0:0` = succès, autre valeur = erreur

**La notation des job steps :**
- `4` = le job parent (le script)
- `4.batch` = initialisation du script
- `4.0` = premier `srun` dans le script
- `4.1` = deuxième `srun` dans le script

---

## 5. Écrire un script sbatch

```bash
#!/bin/bash
#SBATCH --job-name=mon_calcul       # Nom du job
#SBATCH --nodes=2                   # Nombre de nœuds
#SBATCH --output=/data/resultat_%j.txt  # Fichier de sortie

srun -l hostname
srun -l date
```

**Les variables `%` dans `--output` :**
| Variable | Remplacée par |
|----------|--------------|
| `%j` | Job ID |
| `%u` | Nom de l'utilisateur |
| `%x` | Nom du job (`--job-name`) |
| `%N` | Nom du nœud |

> **Piège classique** : sans `%j`, tous les jobs écrasent le même fichier de sortie.

---

## 6. Créer un fichier sans éditeur (heredoc)

```bash
cat > /data/mon_script.sh << 'EOF'
#!/bin/bash
echo "bonjour"
EOF
```
- `cat >` : crée le fichier (écrase s'il existe déjà)
- `<< 'EOF'` : tout ce qui suit jusqu'au mot `EOF` est écrit dans le fichier

---

## 7. Différence `srun` vs `sbatch`

| | `srun` | `sbatch` |
|--|--------|----------|
| **Tu attends ?** | Oui, bloqué | Non, main immédiate |
| **Résultat** | Dans le terminal | Dans un fichier |
| **Usage** | Tests rapides, interactif | Calculs longs, production |
| **Typique** | "je veux voir le résultat maintenant" | "je reviens demain voir le résultat" |

---

## 8. Le flux complet d'un job

```
Tu soumets avec sbatch
        ↓
slurmctld reçoit la demande
        ↓
Il vérifie les nœuds disponibles (via slurmd sur chaque nœud)
        ↓
Il place le job en file d'attente si pas de ressources dispo
        ↓
Dès que les ressources sont libres → assigne le job à un/des nœuds
        ↓
slurmd sur le(s) nœud(s) exécute le job
        ↓
Le résultat s'écrit dans ton fichier de sortie
        ↓
slurmdbd enregistre tout dans MariaDB (comptabilité)
```

---

## 9. L'infrastructure Docker montée aujourd'hui

```
ton Mac
  └── Docker
        ├── mysql          (MariaDB — comptabilité)
        ├── slurmdbd       (intermédiaire Slurm ↔ DB)
        ├── slurmctld      (cerveau du cluster)
        ├── slurmrestd     (API REST — port 6820 exposé)
        ├── c1             (nœud de calcul 1)
        └── c2             (nœud de calcul 2)
```

**Ports exposés vers ton Mac :**
- `6820` → slurmrestd (API REST)
- `3022` → SSH vers slurmctld

**Ports internes uniquement :**
- `6817` → slurmctld
- `6819` → slurmdbd
- `6818` → slurmd (c1, c2)
- `3306` → MariaDB

---

## 10. Commandes Docker utiles

```bash
docker compose up -d        # Démarrer le cluster en arrière-plan
docker compose down         # Arrêter le cluster
docker compose ps           # État des conteneurs
docker exec -it slurmctld bash   # Entrer dans le cluster
```

---

## À retenir pour la prochaine session

La prochaine étape : **configuration de Slurm** — modifier `slurm.conf`, créer des partitions, définir des limites par utilisateur. C'est là qu'on passe vraiment du rôle d'utilisateur à celui d'ingénieur.
