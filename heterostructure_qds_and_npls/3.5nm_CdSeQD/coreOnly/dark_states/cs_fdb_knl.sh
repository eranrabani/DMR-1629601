#!/bin/bash 

#SBATCH -q regular 
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -L SCRATCH
#SBATCH -J cs_fb_knl
#SBATCH -C knl,quad,cache
#SBATCH --mail-user=jphilbin@berkeley.edu
#SBATCH --mail-type=ALL

# Define the necessary paths to executables and 
# pseudopotential files
cwd=$(pwd)
pseudoDir="/global/homes/j/jphilbin/Pseudopotentials/new_sf_pp"
executableBaseDir="/global/homes/j/jphilbin/programs/semi_empirical_pseudopotentials"
filterXDir="$executableBaseDir/filter"
bseXDir="$executableBaseDir/bse"
scratchDir="${cwd/homes\/j/cscratch1\/sd}"

# Determine unique directory number index for this calculation
for i in {1..50}; do
	if [ ! -d "$cwd/"$i"_filter" ]; then
		dirNum="$i"
		break
	fi
done

# OpenMP settings
export OMP_NUM_THREADS=64
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

# Compile filter and bse executables
cd $filterXDir
module unload cray-libsci
module load cray-fftw
cc *.c -o filter.x -qopenmp -mkl 
cd $bseXDir
cc *.c -o bse.x -qopenmp -mkl 

# Make necessary home and scratch directories
sFilterDir="$scratchDir/"$dirNum"_filter"
hFilterDir="$cwd/"$dirNum"_filter"
sBSEDir="$scratchDir/"$dirNum"_bse"
hBSEDir="$cwd/"$dirNum"_bse"
mkdir -p $sFilterDir $sBSEDir 
mkdir -p $hFilterDir $hBSEDir

# Make input.par files
cd $cwd
bash inputFilterDarkBSE.sh $OMP_NUM_THREADS

# Copy all required input and executable files into the scratch directories
cp $cwd/filter_input.par $sFilterDir/input.par
cp $cwd/filter_input.par $hFilterDir/input.par
cp $cwd/bse_input.par $sBSEDir/input.par
cp $cwd/bse_input.par $hBSEDir/input.par
cp $cwd/bse_optionalInput.par $sBSEDir/optionalInput.par
cp $cwd/bse_optionalInput.par $hBSEDir/optionalInput.par
rm $cwd/*_*nput.par
cp $pseudoDir/pot*.par $sFilterDir/
cp $pseudoDir/pot*.par $sBSEDir/
cp $cwd/conf.par $sFilterDir/
cp $cwd/conf.par $sBSEDir/
cp $filterXDir/filter.x $sFilterDir/
cp $bseXDir/bse.x $sBSEDir/

# Run the filter executable on a single node with parallel openMP threads
cd $sFilterDir
srun -N 1 -n 1 -c $OMP_NUM_THREADS --cpu_bind=cores ./filter.x > run.dat & 
wait

# Move filter results to home directory and scratch BSE directory 
cp run.dat 'eval'.dat conf.par input.par $hFilterDir/
mv psi.dat $sBSEDir/psi.par
cp 'eval'.dat $sBSEDir/'eval'.par

# Run the BSE executable on a single node with parallel openMP threads
cd $sBSEDir/
srun -N 1 -n 1 -c $OMP_NUM_THREADS --cpu_bind=cores ./bse.x > run.dat &
wait

# Move BSE results to filter and BSE home directories 
sort -k 2 OS0.dat > sorted_OS0.dat
sort -k 2 M0.dat > sorted_M0.dat
sort -k 1 rs.dat > sorted_rs.dat
cp run.dat exciton.dat OS.dat p*z*-*.dat sorted*.dat BSEeval.par conf.par input.par $hBSEDir/ 
cp pz*.dat BSEeval.par sorted*.dat $hFilterDir/

# Clean up scratch directory
rm -r $sFilterDir  
rm -r $sBSEDir
#cd $sBSEDir
#rm *.cub pot* p*z*.dat sing* tes* bse.x 
