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
wget "$URLI"

URLM="https://raw.githubusercontent.com/pofernandes/abl-msm/refs/heads/main/minim.mdp"
wget "$URLM"
# Preparing MD commands 

gmx_mpi editconf \
        -f protein_processed.gro \
        -o protein_newbox.gro \
        -c \
        -d 1.5 \
        -bt cubic

gmx_mpi solvate \
        -cp protein_newbox.gro \
        -cs spc216.gro \
        -p topol.top \
        -o protein_solv.gro

gmx grompp \
        -f ions.mdp \
        -c protein_solv.gro \
        -p topol.top \
        -o ions.tpr

gmx genion \
        -s ions.tpr \
        -o protein_solv_ions.gro \
        -p topol.top \
        -pname NA \
        -nname CL \
        -neutral \
<<-EOF
	13
EOF

gmx_mpi grompp \
        -f minim.mdp \
        -c protein_solv_ions.gro \
        -p topol.top \
        -o em.tpr

gmx_mpi mdrun \
        -deffnm em \
        -g log_em
