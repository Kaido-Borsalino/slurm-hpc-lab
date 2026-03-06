# Slurm HPC Lab

Cluster HPC complet monté sur Docker pour apprendre l'administration Slurm.

## Contexte

Après 2 ans en support N3 sur le datacenter HPC du CNRS (HPE), j'ai décidé 
de monter en compétences sur l'administration Slurm — passer du côté matériel 
au côté orchestration.

## Ce que ce projet couvre

- Déploiement d'un cluster Slurm complet (slurmctld, slurmdbd, 2 nœuds de calcul)
- Configuration des partitions et limites de temps
- Gestion des utilisateurs et des comptes Slurm
- Système de priorités multifactor et QOS
- Chaînage de jobs et automatisation
- Monitoring et troubleshooting

## Stack technique

- Docker + Docker Compose
- Slurm 25.11.2
- MariaDB
- Rocky Linux
- Environment Modules

## Architecture

\`\`\`
slurmctld  (scheduler + nœud de login)
slurmdbd   (comptabilité)
mysql      (base de données)
c1, c2     (nœuds de calcul)
slurmrestd (API REST)
\`\`\`

## Lancer le cluster

\`\`\`bash
git clone https://github.com/Kaido-Borsalino/slurm-hpc-lab
cd slurm-hpc-lab
docker compose up -d
docker exec -it slurmctld bash
\`\`\`
