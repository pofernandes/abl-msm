#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --partition=test
#SBATCH --ntasks-per-node=64
#SBATCH --nodes=1
#SBATCH --mail-type=END # uncomment to get mail

# Loading necessary modules
module purge
module load gromacs-env

# Download ions.mdp and minim.mdp PME electrostatics
URLI="https://raw.githubusercontent.com/pofernandes/abl-msm/refs/heads/main/ions.mdp"
srun wget "$URLI"

URLM="https://raw.githubusercontent.com/pofernandes/abl-msm/refs/heads/main/minim.mdp"
srun wget "$URLM"
# Preparing MD commands 

srun gmx_mpi editconf \
        -f protein_processed.gro \
        -o protein_newbox.gro \
        -c \
        -d 1.5 \
        -bt cubic

srun gmx_mpi solvate \
        -cp protein_newbox.gro \
        -cs spc216.gro \
        -p topol.top \
        -o protein_solv.gro

srun gmx grompp \
        -f ions.mdp \
        -c protein_solv.gro \
        -p topol.top \
        -o ions.tpr

srun gmx genion \
        -s ions.tpr \
        -o protein_solv_ions.gro \
        -p topol.top \
        -pname NA \
        -nname CL \
        -neutral \
<<-EOF
	13
EOF

srun gmx_mpi grompp \
        -f minim.mdp \
        -c protein_solv_ions.gro \
        -p topol.top \
        -o em.tpr

srun gmx_mpi mdrun \
        -deffnm em \
        -g log_em
