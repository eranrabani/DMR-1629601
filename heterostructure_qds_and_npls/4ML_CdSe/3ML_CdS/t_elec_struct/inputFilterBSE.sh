#!/bin/bash

# Defining the necessary path
cwd=$(pwd)

# Common input parameters to both filter.x and bse.x
gridPointsX="176"
gridPointsY="176"
gridPointsZ="96"
nThreads="$1"

# Input parameters specific to the filter-diagonalization technique
nStatesPerFilter="20"
nFilters="128"
newtonIntLength="4096"
holeTargetEnergy="-0.225"
elecTargetEnergy="-0.135"

# Input parameters specific to the bethe-salpeter equation
epsilon="6.00 6.00 6.00"
bseDeltaEe="0.2"
bseDeltaEh="0.1"
maxElecStates="50"
maxHoleStates="50"
sigmaCutoff="0.01"

# Print an input.par file for a filter-diagonalization calculation
cat > $cwd/filter_input.par << EOF
$gridPointsX
$gridPointsY
$gridPointsZ
$nStatesPerFilter
$nFilters
$newtonIntLength
$holeTargetEnergy
$elecTargetEnergy
$nThreads
EOF

# Print an input.par file for a bethe-salpeter equation calculation 
cat > $cwd/bse_input.par << EOF
$gridPointsX
$gridPointsY
$gridPointsZ
$epsilon
$bseDeltaEe $bseDeltaEh $sigmaCutoff
$maxElecStates $maxHoleStates
$nThreads
EOF

