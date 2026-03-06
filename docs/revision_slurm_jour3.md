# Fiches de révision — États des nœuds, Priorités, QOS
### Session du 01-02 mars 2026

---

## 1. Les états des nœuds

| État | Cause | Qui décide |
|------|-------|-----------|
| `idle` | Disponible, aucun job | Slurm automatique |
| `mixed` | Partiellement occupé (certains CPUs libres) | Slurm automatique |
| `alloc` | Tous les CPUs occupés | Slurm automatique |
| `down*` | Ne répond plus | Slurm automatique |
| `drain` | En cours de vidage, plus de nouveaux jobs | Ingénieur |
| `drained` | Vidé complètement, exclu du cluster | Ingénieur |

**Différence clé `down` vs `drained` :**
- `down` = involontaire, le nœud a crashé
- `drained` = volontaire, un ingénieur a décidé de l'exclure

---

## 2. Cycle de maintenance d'un nœud

**Drainer un nœud (maintenance planifiée) :**
```bash
scontrol update NodeName=c2 State=drain Reason="maintenance_disque"
```
- Les jobs en cours finissent normalement
- Aucun nouveau job n'est assigné
- La raison est visible dans `sinfo` — important pour les collègues

**Réintégrer un nœud après maintenance :**
```bash
scontrol update NodeName=c2 State=resume
```

**Vérifier l'état détaillé d'un nœud :**
```bash
sinfo -N -l
scontrol show node c2
```

---

## 3. ReturnToService

Dans `slurm.conf` :
```
ReturnToService=1
```
Avec cette option, un nœud qui était `down` et qui redevient joignable est **réintégré automatiquement** sans intervention humaine. Sans cette option il resterait `down` et nécessiterait un `scontrol update` manuel.

---

## 4. SlurmdTimeout

Dans `slurm.conf` :
```
SlurmdTimeout=300
```
Slurm attend **300 secondes** sans réponse d'un slurmd avant de marquer le nœud `down`. Valeur configurable — plus basse pour détecter les pannes plus vite, mais attention aux faux positifs sur réseau lent.

---

## 5. Le système de priorité multifactor

Par défaut Slurm utilise le premier arrivé, premier servi. Le **multifactor** calcule une priorité dynamique basée sur plusieurs facteurs.

Activation dans `slurm.conf` :
```
PriorityType=priority/multifactor
PriorityDecayHalfLife=7-0
PriorityWeightAge=1000
PriorityWeightFairshare=1000
PriorityWeightJobSize=100
```

**Les facteurs de priorité :**

| Facteur | Signification |
|---------|--------------|
| `Age` | Plus un job attend, plus sa priorité monte |
| `Fairshare` | Plus tu as consommé récemment, moins tu es prioritaire |
| `JobSize` | Favorise les petits ou grands jobs selon config |
| `Partition` | Certaines partitions plus prioritaires |
| `QOS` | Certaines qualités de service plus prioritaires |

Le poids de chaque facteur se règle entre 0 (ignoré) et 1000 (maximum).

**`PriorityDecayHalfLife=7-0`** — la consommation passée perd la moitié de son poids tous les 7 jours. C'est la mémoire du fairshare.

**`PriorityCalcPeriod`** — Slurm recalcule les priorités toutes les 5 minutes automatiquement.

---

## 6. Visualiser les priorités

```bash
sprio -l
```

```
JOBID PARTITION  USER  PRIORITY  AGE  FAIRSHARE  JOBSIZE  QOS
   21 normal     root      1458    0       1000      458    0
   24 long       chercheu   458    0          0      458    0
```

**Fairshare relatif** — ce n'est pas une valeur absolue. Si root est le seul utilisateur il a 1000. Si chercheur1 arrive avec un compte Slurm, root passe à 500 et chercheur1 à 1000 (car il n'a encore rien consommé).

---

## 7. Différence Fairshare vs QOS

| | Fairshare | QOS |
|--|-----------|-----|
| **Principe** | Prioriser équitablement | Limiter physiquement |
| **Cluster vide** | N'a aucun effet | Limite quand même |
| **Cluster chargé** | Gère l'ordre de passage | Bloque au delà du quota |
| **Usage** | Équité entre utilisateurs | Contrats de service par projet |

**On utilise les deux ensemble** — le fairshare pour l'équité globale, la QOS pour les garanties contractuelles.

---

## 8. Les comptes Slurm

Il y a deux niveaux distincts :
- **Utilisateur Linux** — pour se connecter au système
- **Compte Slurm** — pour la comptabilité, le fairshare, et les limites

Sans compte Slurm : `FAIRSHARE = 0`, priorité minimale, pas de limites applicables.

**Créer un compte et un utilisateur Slurm :**
```bash
sacctmgr add account chercheur1 description="Compte chercheur1"
sacctmgr add user chercheur1 account=chercheur1 defaultaccount=chercheur1
```

**Vérifier :**
```bash
sacctmgr show user chercheur1 withassoc
```

---

## 9. La QOS (Quality of Service)

La QOS définit des **limites contractuelles** par utilisateur ou par groupe.

**Voir les QOS existantes :**
```bash
sacctmgr show qos
```

**Créer une QOS :**
```bash
sacctmgr add qos chercheur
sacctmgr modify qos chercheur set MaxCPUsPerUser=4 MaxJobsPerUser=2
```

**Assigner une QOS à un utilisateur :**
```bash
sacctmgr modify user chercheur1 set qos=chercheur defaultqos=chercheur
```

**Limites courantes dans une QOS :**

| Paramètre | Signification |
|-----------|--------------|
| `MaxCPUsPerUser` | CPUs simultanés maximum |
| `MaxJobsPerUser` | Jobs en cours simultanés maximum |
| `MaxWall` | Durée maximum d'un job |
| `GrpTRES` | Limite globale pour tous les utilisateurs du groupe |

**Raison dans squeue quand la QOS bloque :**
```
QOSMaxJobsPerUserLimit
QOSMaxCpuPerUserLimit
```

---

## 10. Trouver un fichier de config

```bash
find / -name "slurm.conf" 2>/dev/null
```
- `2>/dev/null` redirige les erreurs vers la poubelle — évite les milliers de "Permission denied"

```bash
scontrol show config | grep SLURM_CONF
```
- Demande directement à Slurm où est son fichier — plus fiable

---

## Récapitulatif des 3 sessions

| Session | Thème |
|---------|-------|
| 1 | Utilisation — srun, sbatch, squeue, scancel, sacct |
| 2 | Configuration — slurm.conf, partitions, limites, permissions |
| 3 | Administration avancée — états nœuds, priorités, fairshare, QOS |

**Prochaine session :** Automatisation — scripts d'admin, monitoring, gestion des utilisateurs en masse
