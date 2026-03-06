# Fiches de révision — Slurm Administration
### Session du 28 février 2026

---

## 1. Le fichier `slurm.conf`

C'est le **fichier central de Slurm** — il définit tout le comportement du cluster. Il se trouve sur tous les nœuds à `/etc/slurm/slurm.conf`.

Sections importantes :

| Section | Ce qu'elle contrôle |
|---------|-------------------|
| Paramètres généraux | Nom du cluster, ports, chemins des logs |
| Scheduling | Type de scheduler, algorithme de sélection |
| Timers | Timeouts, délais de kill |
| Logging | Niveau de debug, fichiers de log |
| Nœuds | Déclaration des nœuds et leurs ressources |
| Partitions | Groupes de nœuds et leurs règles |

---

## 2. Déclarer des nœuds

```
NodeName=c1 CPUs=2 RealMemory=1000 State=UNKNOWN
NodeName=c2 CPUs=2 RealMemory=1000 State=UNKNOWN
```

- `CPUs` — nombre de cœurs
- `RealMemory` — RAM en MB
- `State=UNKNOWN` — bonne pratique : Slurm interroge le nœud au démarrage plutôt que de supposer son état

> **Pourquoi UNKNOWN et pas IDLE ?** Si tu mets IDLE et que le nœud a crashé pendant la nuit, Slurm croirait au redémarrage qu'il est disponible alors qu'il ne l'est pas. UNKNOWN force une vérification réelle.

---

## 3. Les partitions

Une partition c'est un **groupe de nœuds avec des règles communes** — pas le nom du cluster. C'est l'équivalent d'une file d'attente spécialisée.

```
PartitionName=normal Nodes=c1,c2 Default=YES MaxTime=60 State=UP
PartitionName=long   Nodes=c1,c2 Default=NO  MaxTime=1440 State=UP AllowGroups=hpc_long
```

| Paramètre | Signification |
|-----------|--------------|
| `Default=YES` | Partition utilisée si l'utilisateur n'en spécifie pas |
| `MaxTime=60` | Limite en minutes (60 = 1h, 1440 = 24h) |
| `State=UP` | Partition active |
| `AllowGroups=hpc_long` | Seuls les membres du groupe Linux `hpc_long` peuvent soumettre |

**Exemple de partitions dans un vrai cluster :**
- `short` — jobs < 1h, priorité haute
- `normal` — jobs < 24h, usage général
- `long` — jobs < 7 jours, accès restreint
- `highmem` — nœuds avec beaucoup de RAM
- `gpu` — nœuds avec GPU

---

## 4. Appliquer une modification de config

Modifier `slurm.conf` ne suffit pas — il faut dire à Slurm de relire le fichier :

```bash
scontrol reconfigure
```

Puis vérifier que le changement est pris en compte :

```bash
scontrol show partition normal
scontrol show partition long
```

---

## 5. Diagnostiquer un job bloqué

```bash
squeue                          # voir l'état et la raison
scontrol show job <ID>          # détails complets du job
sacct -j <ID> --format=JobID,JobName,State,Elapsed,ExitCode
```

**Raisons courantes dans squeue :**

| Raison | Cause |
|--------|-------|
| `PartitionTimeLimit` | Job demande plus de temps que la limite de la partition |
| `Resources` | Prochain dans la file, attend que les ressources se libèrent |
| `Priority` | Attend derrière un job prioritaire |
| `Nodes required... DOWN` | Nœuds indisponibles ou permissions insuffisantes |

---

## 6. Restreindre l'accès à une partition

**Étape 1 — Créer un groupe Linux**
```bash
groupadd hpc_long
```

**Étape 2 — Ajouter un utilisateur au groupe**
```bash
useradd -m chercheur1
usermod -aG hpc_long chercheur1
```

**Étape 3 — Vérifier**
```bash
id chercheur1
# → uid=1000(chercheur1) gid=1000(chercheur1) groups=1000(chercheur1),1001(hpc_long)
```

**Étape 4 — Modifier slurm.conf**
```
PartitionName=long ... AllowGroups=hpc_long
```

**Étape 5 — Reconfigurer**
```bash
scontrol reconfigure
```

---

## 7. Les permissions Linux

```
drwxr-xr-x 2 root root 4096 /data
```

Décomposition :

```
d   rwx   r-x   r-x
↑    ↑     ↑     ↑
|  proprio groupe autres
type
```

- `r` = read (lire)
- `w` = write (écrire)
- `x` = execute/navigate (exécuter/naviguer dans un dossier)
- `-` = permission absente

**Pour `/data` appartenant à root :**
- root → `rwx` → peut tout faire
- groupe root → `r-x` → peut lire, pas écrire
- chercheur1 (autres) → `r-x` → peut lire, **pas écrire** → job FAILED

---

## 8. Changer le propriétaire d'un fichier

```bash
chown propriétaire:groupe fichier_ou_dossier
```

**Exemples :**
```bash
chown chercheur1:chercheur1 /data/chercheur1    # dossier appartient à chercheur1
chown root:root /etc/slurm/slurm.conf           # revenir à root
```

**Workflow typique pour un nouvel utilisateur :**
```bash
useradd -m chercheur1                           # créer l'utilisateur
mkdir /data/chercheur1                          # créer son espace de travail
chown chercheur1:chercheur1 /data/chercheur1    # lui donner les droits
```

---

## 9. L'état des nœuds — les astérisques

```bash
sinfo -N -l    # vue détaillée par nœud
```

**Deux astérisques différents :**

| Astérisque | Où | Signification |
|-----------|-----|--------------|
| `normal*` | Colonne PARTITION | Partition par défaut |
| `idle*` | Colonne STATE | Nœud idle mais ne répond pas (problème de communication) |

Si tu vois `idle*` sur tes nœuds :
```bash
# Depuis ton Mac, hors du conteneur
docker restart c1 c2
```

---

## 10. Le système de fichiers partagé

**Concept fondamental du HPC :**

Tous les nœuds voient le **même système de fichiers**. Un fichier créé sur le nœud de login est immédiatement visible sur tous les nœuds de calcul.

- Dans notre cluster Docker → volume Docker partagé sur `/data`
- Dans un vrai cluster → NFS, Lustre, ou GPFS monté sur tous les nœuds

**Sans système de fichiers partagé :**
```
error: couldn't chdir to `/home/chercheur1': No such file or directory
```
Les nœuds de calcul ne trouvent pas le home de l'utilisateur — exactement ce qu'on a vu.

**Bonne pratique :** Toujours écrire les résultats dans un répertoire accessible depuis tous les nœuds, pas dans le home local.

---

## 11. ExitCode dans sacct

Format : `code_retour:signal`

| ExitCode | Signification |
|---------|--------------|
| `0:0` | Succès |
| `0:53` | Problème infrastructure Slurm (permissions, répertoire manquant) |
| `1:0` | Le programme a retourné une erreur |

---

## Ce qu'on a accompli en 2 sessions

**Session 1 :** Utilisation de Slurm (srun, sbatch, squeue, scancel, sacct)
**Session 2 :** Administration de Slurm (slurm.conf, partitions, limites, permissions, gestion utilisateurs)

**Prochaine session :** Gestion avancée — priorités, fairshare, limites par compte, QOS (Quality of Service)
