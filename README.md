# slurm-hpc-lab

Cluster HPC opérationnel déployé en trois environnements progressifs.

## Ce que ce repo couvre

| Module | Environnement | Statut |
|---|---|---|
| Slurm — architecture, scheduling, QOS | Docker | ✅ |
| Troubleshooting — OOM, TIMEOUT, échecs silencieux | Docker | ✅ |
| AWS ParallelCluster — Slurm + Lustre FSx + EFA | AWS | ✅ |
| Monitoring — Prometheus + Alertmanager + Grafana | Docker | ✅ |
| War Games — incidents provoqués et documentés | AWS | 🔄 |

## Lancer le cluster Docker
```bash
git clone https://github.com/Kaido-Borsalino/slurm-hpc-lab
cd slurm-hpc-lab
docker-compose up -d
docker exec -it slurmctld bash
sinfo
```

## Déployer sur AWS
```bash
cd aws-parallelcluster
pcluster create-cluster \
  --cluster-configuration cluster-config.yaml \
  --cluster-name hpc-lab \
  --region us-east-1
```

**Coût estimé :** ~1.85$/heure (t3.micro + c5n.large x2 + Lustre FSx 1.2TB)

**Cleanup obligatoire après session :**
```bash
pcluster delete-cluster --cluster-name hpc-lab --region us-east-1
# Vérifier NAT Gateways et VPC orphelins
```

## Stack technique

- **Scheduler** : Slurm 25.11.2
- **Storage** : Lustre FSx (AWS) 
- **Réseau HPC** : EFA / RDMA (AWS)
- **Monitoring** : Prometheus + Alertmanager + Grafana + node_exporter
- **OS** : Rocky Linux 9 / Amazon Linux 2023

## Architecture Docker
```
slurmctld   → scheduler (slurmctld + Prometheus + Grafana)
slurmdbd    → comptabilité
mysql       → base de données
c1, c2      → nœuds de calcul (slurmd + node_exporter)
```

## Preuves d'exécution

- [`docs/screenshots/alert_firing.png`](docs/screenshots/alert_firing.png) — alerte MemoryLow firing
- [`docs/screenshots/prometheus_targets.json`](docs/screenshots/prometheus_targets.json) — c1 et c2 health:up
- [`docs/screenshots/alertmanager_active.json`](docs/screenshots/alertmanager_active.json) — alerte reçue par Alertmanager
