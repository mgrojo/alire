"""
A test that a bad lockfile is recovered from (losing pins)
"""

from drivers.alr import run_alr, alr_lockfile

import os
import re

# Create a new crate
run_alr('init', '--bin', 'xxx')

# And muck its lockfile
os.chdir('xxx')

BADLINE = "SHOULND'T BE HERE"

with open(alr_lockfile(), "a") as myfile:
    myfile.write(BADLINE)

# Run a command that requires the lockfile
p = run_alr('show')

# Now the lockfile should be recreated and proper, so check no bad line:
with open(alr_lockfile(), 'r') as myfile:
        for line in myfile:
            assert line != BADLINE, "Unexpected line found in file"

print('SUCCESS')
