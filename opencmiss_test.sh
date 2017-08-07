#!/bin/bash -l

# source parameters
if [ -f "${HOME}/.opencmiss_test.conf" ]; then
    source ${HOME}/.opencmiss_test.conf
fi

# check parameters are set, otherwise use defaults
if [ -z "${mailto}" ]; then
    mailto=""
fi
if [ -z "${testrundir}" ]; then
    testrundir="${HOME}/.cache/opencmiss_test"
fi

# path to slurm submit script
scriptdir=$(cd "${BASH_SOURCE%/*}" > /dev/null; pwd)
slurmscript="${scriptdir}/run_test.sl"
echo "Path to slurm script: '${slurmscript}'"
if [ ! -f "${slurmscript}" ]; then
    >&2 echo "Error: path to slurm script wrong: '${slurmscript}'!"
    exit 1
fi

# create/clear test directory and make sure we have the absolute path
mkdir -p "${testrundir}"
rm "${testrundir}"/*
rundir=$(cd "${testrundir}" > /dev/null; pwd)

# echo some settings
echo "Email recipients: '${mailto}'"
echo "Test run directory: '${rundir}'"

# change to run dir
echo "Changing to run dir"
cd "${rundir}"

# submit test script
echo "Submitting batch job..."
jobid=$(sbatch "${slurmscript}" | awk '{print $4}')
echo "Job ID is ${jobid}"

# wait for job to complete
echo "Waiting for job ${jobid} to complete..."
sleep 10
while squeue -u ${USER} | grep ${jobid}; do sleep 600; done

# prepare for results
slurmfile="slurm-${jobid}.out"
resultfn="test_results.txt"
rm -f ${resultfn}
touch ${resultfn}
outcome="Success"

# was the clone successful
if grep "Clone succeeded" $slurmfile; then
    echo "Outcome of clone: Success" >> $resultfn
else
    echo "Outcome of clone: Failure" >> $resultfn
    outcome="Failure"
fi

if [ "$outcome" == "Success" ]; then
    # was the configure successful
    if grep "Configure succeeded" $slurmfile; then
        echo "Outcome of configure: Success" >> $resultfn
    else
        echo "Outcome of configure: Failure" >> $resultfn
        outcome="Failure"
    fi

    if [ "$outcome" == "Success" ]; then
        # was the build successful
        if grep "Build succeded" $slurmfile; then
            echo "Outcome of build: Success" >> $resultfn
        else
            echo "Outcome of build: Failure" >> $resultfn
            outcome="Failure"
        fi

        if [ "$outcome" == "Success" ]; then
            # check results
            echo "" >> $resultfn
            testfiles=$(ls test_*.out)
            outcome="Success"
            for fn in ${testfiles}; do
                testname="${fn%.*}"
                if grep "Program successfully completed" ${fn}; then
                    echo "${testname}: Success" >> $resultfn
                else
                    echo "${testname}: Failure" >> $resultfn
                    outcome="Failure"
                fi
            done
        fi
    fi
fi

# the outcome
echo "Outcome is ${outcome}"
echo "" >> $resultfn
echo "Outcome: ${outcome}" >> $resultfn

# send email if required
if [ -z "${mailto}" ]; then
    exit 0
fi

echo "Sending email..."
resultstr="$(cat $resultfn)"
cat <<EOF | mail -t -a slurm-configure.out -a slurm-build.out
To: ${mailto}
Subject: Test of OpenCMISS on Pan: ${outcome}

Test completed at: $(date)

$resultstr

EOF
