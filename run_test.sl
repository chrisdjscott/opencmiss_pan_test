#!/bin/bash -l
#SBATCH -J opencmiss
#SBATCH -A nesi99999          # Project Account
#SBATCH --time=5:00:00        # Walltime HH:MM:SS
#SBATCH --mem-per-cpu=8G     # Memory
#SBATCH --ntasks=1            # number of tasks
#SBATCH --cpus-per-task=1     # number of threads

# load modules
module load CMake/3.6.1
module load gimkl/2017a
module load Python/2.7.13-gimkl-2017a

# change to scratch dir
LOGDIR=$(pwd)
echo "Working in: $SCRATCH_DIR"
cd $SCRATCH_DIR

# create directories and clone setup repo
echo "Clone repo..."
if ! srun git clone https://github.com/OpenCMISS/setup.git; then
    echo "Clone failed!"
    exit 1
fi
mkdir opencmiss
mkdir setup-build
cd setup-build

# configure and build
echo "Configure..."
export CC=gcc
export CXX=g++
if ! srun --output=${LOGDIR}/slurm-configure.out cmake -DOPENCMISS_ROOT=../opencmiss ../setup; then
    echo "Configure failed!"
    exit 1
fi
echo "Build..."
if ! srun --output=${LOGDIR}/slurm-build.out make; then
    echo "Build failed!"
    exit 1
fi

# run the tests
echo "Test..."
cd ../opencmiss/build/iron/release/tests
srun --output=${LOGDIR}/test_ClassicalField_Laplace.out ./ClassicalField/Laplace
srun --output=${LOGDIR}/test_ClassicalField_AnalyticLaplace.out ./ClassicalField/AnalyticLaplace
srun --output=${LOGDIR}/test_ClassicalField_AnalyticNonlinearPoisson.out ./ClassicalField/AnalyticNonlinearPoisson
srun --output=${LOGDIR}/test_FieldML_StaticAdvectionDiffusion_FieldML.out ./FieldML/StaticAdvectionDiffusion_FieldML
srun --output=${LOGDIR}/test_FiniteElasticity_Cantilever.out ./FiniteElasticity/Cantilever
srun --output=${LOGDIR}/test_FiniteElasticity_SimpleShear.out ./FiniteElasticity/SimpleShear
srun --output=${LOGDIR}/test_LinearElasticity_Extension.out ./LinearElasticity/Extension
srun --output=${LOGDIR}/test_LinearElasticity_CantileverBeam.out ./LinearElasticity/CantileverBeam

# write status
echo "Finished"
