# Checkpoint/Restore RQ1

All three conditions passed in 3 modified-kernel boot(s).
DMTCP PathTranslator and namei_ext both changed the same
remembered pathname from generation A to generation B after a real
DMTCP restart. Withdrawing the namei_ext mapping failed closed as
expected. The lower objects were unchanged, and no BPF program
remained attached after a boot.

This is formal W5 RQ1 evidence.
Durations are diagnostic and do not support a performance claim.
