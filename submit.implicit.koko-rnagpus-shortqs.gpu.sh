#!/bin/bash
#SBATCH -J igb_mbondi3
#SBATCH -N 1
#SBATCH -n 2
##SBATCH --exclusive
#SBATCH --gres=gpu
#SBATCH -p shortq7-gpu
##SBATCH -p longq7-rna
##SBATCH -p mediumq7,longq7,longq7-rna 
##SBATCH --exclude=nodeamd[039-041],nodegpu[002-003]
#SBATCH --mail-type=NONE
##SBATCH -t infinite

hostname
date
sleep 1
echo $SLURM_SUBMIT_DIR
echo "CUDA VISIBLE DEVICES = "$CUDA_VISIBLE_DEVICES
cd $SLURM_SUBMIT_DIR
#
# Load the modules
#
#module load gcc-9.2.0-gcc-8.3.0-ebpgkrt
source /mnt/rna/home/programs/amber22/amber.sh
#
# Create the temp directories
#
mkdir -p /tmp/$USER
sleep 1
mkdir -p /tmp/$USER/$SLURM_JOBID
sleep 1
#
# Copy the files
#
if [[ ! -f md_1.rst ]]
then
  cp ./min.rst ./prmtop.new /tmp/$USER/$SLURM_JOBID
  cd /tmp/$USER/$SLURM_JOBID

#  mpirun -np $SLURM_NPROCS pmemd.MPI -O -i md.in -p prmtop -c init.rst -o md_1.out -r md_1.rst -x md_1.mdcrd

  cat << EOF > md.gpu.in
Pseudorotation Protocol, 20 ns
 &cntrl
  imin=0, irest=0, ntx=1,
  ntpr=10000, ntwr=10000, ntwx=10000,
  ntb=0, cut=999.0, ntr=0,
  tempi=310.15, temp0=310.15, ntt=3, gamma_ln=1, nstlim=10000000, dt=0.002,
  igb=8, saltcon=0.3, ig=-1,
  pencut=-0.001, nmropt=0, ioutfm=1,
 /
EOF
###

  pmemd.cuda -O -i md.gpu.in -p prmtop.new -c min.rst -o md_1.out -r md_1.rst -x md_1.mdcrd 
  cp md_1.* $SLURM_SUBMIT_DIR
   
else

  val1=`ls -l md_*.rst | awk '{split(\$9,a,"."); split(a[1],b,"_"); print b[2]"\t"\$9}'  | sort -k1,1n  | tail -1  | awk '{print \$1}'`
  cp md_$val1\.rst ./prmtop.new /tmp/$USER/$SLURM_JOBID

  cd /tmp/$USER/$SLURM_JOBID
  val2=`expr $val1 + 1`
 
#  mpirun -np $SLURM_NPROCS pmemd.MPI -O -i md.in -p prmtop -c md_$val1\.rst -o md_$val2\.out -r md_$val2\.rst -x md_$val2\.mdcrd

  cat << EOF > md.gpu.in
Pseudorotation Protocol, 20 ns
 &cntrl
  imin=0, irest=1, ntx=5,
  ntpr=10000, ntwr=10000, ntwx=10000,
  ntb=0, cut=999.0, ntr=0,
  tempi=310.15, temp0=310.15, ntt=3, gamma_ln=1, nstlim=10000000, dt=0.002,
  igb=8, saltcon=0.3, ig=-1,
  pencut=-0.001, nmropt=0, ioutfm=1,
 /
EOF
  pmemd.cuda -O -i md.gpu.in -p prmtop.new -c md_$val1\.rst -o md_$val2\.out -r md_$val2\.rst -x md_$val2\.mdcrd
  cp md_$val2\.* $SLURM_SUBMIT_DIR
fi
#
cd $SLURM_SUBMIT_DIR
rm -dvfr /tmp/$USER/$SLURM_JOBID
#
echo "Done with the job. Re-submit if not reached the limit"
date
if [[ ! -f md_500.rst ]]
then
  sbatch submit.implicit.koko-rnagpus-shortqs.gpu.sh
fi







