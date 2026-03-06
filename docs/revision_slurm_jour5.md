# Fiches de révision — Stockage et Environment Modules
### Session du 04 mars 2026

---

## 1. NFS — Network File System

### Le problème sans NFS
Chaque nœud a son propre disque. Un fichier créé sur slurmctld n'existe pas sur c1 ou c2 :
```
error: couldn't chdir to `/home/chercheur1': No such file or directory
```

### La solution NFS
NFS permet à une machine de **partager son système de fichiers sur le réseau**. Les autres machines le montent comme un disque local — tout le monde voit les mêmes fichiers.

### Configuration NFS (côté serveur)

**1. Installer NFS :**
```bash
dnf install -y nfs-utils          # Rocky Linux / RHEL
apt-get install -y nfs-kernel-server nfs-common   # Debian / Ubuntu
```

**2. Déclarer le partage dans `/etc/exports` :**
```bash
/home 172.0.0.0/8(rw,sync,no_subtree_check,no_root_squash)
```

| Option | Signification |
|--------|--------------|
| `rw` | Read + Write |
| `sync` | Écrit sur disque avant de confirmer — plus sûr |
| `no_subtree_check` | Désactive une vérification qui cause des problèmes de perf |
| `no_root_squash` | root du client reste root sur le partage |

**3. Démarrer et activer :**
```bash
rpcbind          # démarre le service de communication réseau
exportfs -a      # active tous les partages déclarés dans /etc/exports
exportfs -v      # vérifie les partages actifs
```

### Configuration NFS (côté client — les nœuds)
```bash
mount slurmctld:/home /home
```

### NFS vs Lustre

| | NFS | Lustre |
|--|-----|--------|
| **Usage** | Petits/moyens clusters | Grands clusters (100+ nœuds) |
| **Performance** | Correcte | Très haute |
| **Complexité** | Simple | Complexe |
| **Limite** | Ne scale pas au delà de quelques centaines de nœuds | Conçu pour des milliers de nœuds |

---

## 2. Environment Modules

### Le problème sans modules
Plusieurs versions d'un même logiciel se marchent dessus dans le PATH. Python 3.11 écrase Python 3.9.

### La solution
Chaque logiciel est isolé dans un module. On charge et décharge les versions à la demande — le PATH est modifié automatiquement.

### Installation
```bash
dnf install -y environment-modules
source /etc/profile.d/modules.sh    # activer la commande module dans le shell
```

> `source` exécute le script dans le shell actuel — les fonctions définies restent disponibles. Sans `source`, la commande `module` n'existe pas.

### Commandes essentielles

```bash
module avail                        # voir tous les modules disponibles
module list                         # voir les modules chargés en ce moment
module load python/3.9              # charger un module
module unload python/3.9            # décharger un module
module switch python/3.9 python/3.11  # échanger deux versions
module purge                        # décharger tous les modules
```

### Le mécanisme — le PATH

```bash
echo $PATH
# → /usr/bin:/bin

module load python/3.9
echo $PATH
# → /usr/local/python3.9/bin:/usr/bin:/bin
#   ↑ ajouté en tête

module unload python/3.9
echo $PATH
# → /usr/bin:/bin   (retour à l'état initial, propre)
```

`module unload` sait exactement défaire ce qu'il a fait — pas de résidus.

---

## 3. Créer un modulefile

Les modulefiles sont des fichiers texte dans `/usr/share/Modules/modulefiles/`.

**Structure d'un répertoire de modules :**
```
/usr/share/Modules/modulefiles/
├── python/
│   ├── 3.9
│   └── 3.11
├── gcc/
│   ├── 11
│   └── 13
└── openmpi/
    └── 4.1
```

**Exemple de modulefile `python/3.9` :**
```tcl
#%Module1.0

proc ModulesHelp { } {
    puts stderr "Python 3.9 - langage de programmation"
}

module-whatis "Python 3.9"

prepend-path PATH /usr/local/python3.9/bin
prepend-path LD_LIBRARY_PATH /usr/local/python3.9/lib
setenv PYTHON_VERSION 3.9
```

| Directive | Signification |
|-----------|--------------|
| `prepend-path PATH` | Ajoute en tête du PATH |
| `prepend-path LD_LIBRARY_PATH` | Ajoute les librairies |
| `setenv` | Définit une variable d'environnement |

---

## 4. Modules dans un script Slurm

```bash
#!/bin/bash
#SBATCH --job-name=calcul
#SBATCH --nodes=1
#SBATCH --output=/data/resultat_%j.txt

source /etc/profile.d/modules.sh    # indispensable sur les nœuds
module purge                         # partir d'un environnement propre
module load python/3.11              # charger ce dont on a besoin

python mon_calcul.py
```

**Deux règles systématiques :**
1. Toujours `source /etc/profile.d/modules.sh` — les nœuds ne l'ont pas forcément dans leur environnement
2. Toujours `module purge` avant de charger — évite les conflits avec ce qui était déjà chargé

---

## 5. Le rôle de l'ingénieur HPC côté logiciels

Pour chaque logiciel demandé par un chercheur :

1. **Installer** le logiciel dans un répertoire dédié (`/usr/local/python3.9/`)
2. **Créer le modulefile** qui pointe vers ce répertoire
3. **Tester** que `module load` fonctionne correctement
4. **Documenter** le module pour les utilisateurs

Le chercheur n'a plus qu'à faire `module load python/3.9` — il ne sait pas où Python est installé et n't as pas besoin de le savoir.

---

## 6. NFS + Modules — pourquoi ils vont ensemble

Dans un vrai cluster :
- `environment-modules` doit être **installé sur tous les nœuds**
- Les modulefiles doivent être sur le **système de fichiers partagé (NFS)**

Sans NFS, les modulefiles n'existent que sur le nœud de login — les nœuds de calcul ne peuvent pas faire `module load`.

```
slurmctld (nœud login)
    └── /home (exporté via NFS)
    └── /software/modulefiles (exporté via NFS)
            ↓
c1, c2, c3... (nœuds de calcul)
    └── /home (monté via NFS)
    └── /software/modulefiles (monté via NFS)
```

---

## Récapitulatif des 5 sessions

| Session | Thème |
|---------|-------|
| 1 | Utilisation — srun, sbatch, squeue, scancel, sacct |
| 2 | Configuration — slurm.conf, partitions, limites, permissions |
| 3 | Administration — états nœuds, priorités, fairshare, QOS |
| 4 | Automatisation — chaînage de jobs, scripts admin, rapports |
| 5 | Stockage et environnement — NFS, Environment Modules |

**Prochaine session :** Monitoring et troubleshooting — logs Slurm, diagnostics, scénarios de pannes
