# Fiches de révision — Automatisation et Scripting Admin
### Session du 02-03 mars 2026

---

## 1. Le chaînage de jobs — `--dependency`

Permet de soumettre un pipeline complet en une fois — chaque job attend que le précédent réussisse avant de démarrer.

| Option | Signification |
|--------|--------------|
| `afterok:<JOBID>` | Démarre seulement si le job précédent a réussi (ExitCode 0) |
| `afternotok:<JOBID>` | Démarre seulement si le job précédent a échoué |
| `afterany:<JOBID>` | Démarre peu importe le résultat |
| `after:<JOBID>` | Démarre dès que le job précédent a commencé |

**Raison dans squeue quand la dépendance est bloquée :**
- `Dependency` — attend que le job précédent se termine
- `DependencyNeverSatisfied` — le job précédent a échoué, la dépendance ne sera jamais satisfaite → annuler manuellement

---

## 2. Récupérer le Job ID automatiquement

`sbatch` retourne toujours : `Submitted batch job 42`

Pour capturer le job ID dans une variable :
```bash
JOB1=$(sbatch /data/etape1.sh | awk '{print $4}')
```

- `$()` — exécute la commande et met le résultat dans la variable
- `awk '{print $4}'` — prend le 4ème mot de la ligne (`Submitted=1, batch=2, job=3, ID=4`)

---

## 3. Soumettre un pipeline en chaîne

```bash
JOB1=$(sbatch /data/etape1.sh | awk '{print $4}')
JOB2=$(sbatch --dependency=afterok:$JOB1 /data/etape2.sh | awk '{print $4}')
JOB3=$(sbatch --dependency=afterok:$JOB2 /data/etape3.sh | awk '{print $4}')
echo "Pipeline : $JOB1 -> $JOB2 -> $JOB3"
```

---

## 4. Scripts de jobs vs Scripts d'administration

| | Script de job | Script d'admin |
|--|--------------|----------------|
| **Directives** | `#SBATCH` | Aucune |
| **Lancé avec** | `sbatch` | `bash` |
| **S'exécute sur** | Nœuds de calcul | Nœud de login |
| **Rôle** | Faire le calcul | Orchestrer les jobs |

---

## 5. Les variables et fonctions Bash

**Variable :**
```bash
NOM="alice"
echo $NOM           # → alice

RESULTAT=$(date)    # stocker le résultat d'une commande
echo $RESULTAT
```

**Fonction :**
```bash
ma_fonction() {
    local argument=$1    # $1 = premier argument
    echo "Bonjour $argument"
}

ma_fonction alice    # → Bonjour alice
```

- `local` — la variable n'existe que dans la fonction
- `$1`, `$2` — arguments passés à la fonction
- `[ -z "$variable" ]` — vérifie si la variable est vide

---

## 6. Lire un fichier ligne par ligne

```bash
while read utilisateur; do
    echo "Traitement de : $utilisateur"
done < /data/liste.txt
```

Lit le fichier ligne par ligne et met chaque ligne dans la variable `utilisateur`.

---

## 7. Script de création d'utilisateurs en masse

```bash
#!/bin/bash

while read utilisateur; do
    echo "Traitement de : $utilisateur"
    
    # Utilisateur Linux
    useradd -m $utilisateur

    # Répertoire de travail
    mkdir -p /data/$utilisateur
    chown $utilisateur:$utilisateur /data/$utilisateur

    # Compte Slurm
    sacctmgr -i add account $utilisateur description="Compte $utilisateur"
    sacctmgr -i add user $utilisateur account=$utilisateur defaultaccount=$utilisateur

    # QOS
    sacctmgr -i modify user $utilisateur set qos=chercheur defaultqos=chercheur

    echo "Utilisateur $utilisateur configuré"
done < /data/nouveaux_users.txt
```

**`-i` dans sacctmgr** — `--immediate`, exécute sans demander de confirmation. Indispensable dans les scripts automatisés sinon le script se bloque en attendant une réponse.

---

## 8. Générer un fichier de liste automatiquement

```bash
for i in $(seq 1 50); do
    echo "user$i"
done > /data/liste.txt
```

Génère `user1`, `user2`, ... `user50`.

---

## 9. Rapports de consommation

**Par utilisateur :**
```bash
sreport cluster AccountUtilizationByUser start=2026-01-01 end=2026-12-31
```

**Utilisation globale du cluster :**
```bash
sreport cluster utilization start=2026-01-01 end=2026-12-31
```

**Colonnes importantes de `sreport cluster utilization` :**

| Colonne | Signification |
|---------|--------------|
| `Allocate` | CPU-minutes utilisées pour des jobs |
| `Down` | CPU-minutes perdues car nœuds down |
| `Idle` | CPU-minutes disponibles mais inutilisées |
| `Reported` | Total CPU-minutes sur la période |

**Taux d'utilisation = Allocate / Reported × 100**
- Objectif en production : **70-90%**
- En dessous de 50% : cluster sous-exploité

---

## 10. Historique détaillé avec sacct

```bash
# Tous les utilisateurs depuis une date
sacct --allusers --format=User,JobID,JobName,Partition,AllocCPUS,Elapsed,State --starttime=2026-01-01

# Un utilisateur spécifique
sacct -u chercheur1 --format=JobID,JobName,State,Elapsed,AllocCPUS,ExitCode
```

---

## 11. exit 1 vs exit 0

Dans un script ou un job :
- `exit 0` — succès, Slurm marque le job `COMPLETED`
- `exit 1` — échec, Slurm marque le job `FAILED`

C'est ce code que `afterok` vérifie pour décider si la dépendance est satisfaite.

---

## Récapitulatif des 4 sessions

| Session | Thème |
|---------|-------|
| 1 | Utilisation — srun, sbatch, squeue, scancel, sacct |
| 2 | Configuration — slurm.conf, partitions, limites, permissions |
| 3 | Administration — états nœuds, priorités, fairshare, QOS |
| 4 | Automatisation — chaînage de jobs, scripts admin, rapports |

**Prochaine session :** Stockage et environnement — NFS, Environment Modules, gestion des logiciels
