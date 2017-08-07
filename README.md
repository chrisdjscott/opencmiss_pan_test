# Automated test for OpenCMISS

Scripts to run a test of the OpenCMISS code as a cron job, e.g. by adding
something like this to your crontab. For example type `crontab -e` and
add the following:

```
0 23 * * 4 /path/to/opencmiss_test/opencmiss_test.sh > /dev/null 2>&1
```

and copying the config file to your home directory, e.g.

```
cp /path/to/opencmiss_test/opencmiss_test.conf ~/.opencmiss_test.conf
```

and editing it as required.
