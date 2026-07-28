# Service Configuration Rotation V2 Implementation Review

## Scope

Two independent read-only reviewers examined the V2 runner, analyzer, Make
suite, shared multi-boot contract, and approved experiment plan. One focused on
C/nginx lifecycle correctness; the other focused on evidence integrity and
false acceptance.

## Round 1

Verdict: blocked.

The lifecycle reviewer found:

1. the `0700` runtime root could not be traversed by nginx's default worker;
2. static GETs did not prove worker access to service temporary paths; and
3. the failed-shutdown path ignored `SIGKILL` and `waitpid` results before
   deleting runtime state and detaching policy.

The evidence reviewer found:

1. the completed formal report target did not revalidate raw evidence;
2. daemon and physical `nginx -t` logs were outside required files and hashes;
3. shared boot validation accepted directories and external symlinks;
4. the analyzer accepted missing `pass`, altered timeout, wrong suite, and dirty
   run metadata; and
5. the same `0700` runtime permission defect.

## Repairs

- The runtime root is `0711`.
- A 64 KiB request passes through nginx's proxy path with
  `client_body_in_file_only on`; the retained temp file must have the expected
  size and the default worker's effective UID.
- Graceful and forced shutdown check kill/wait results and establish reap
  before log capture or runtime deletion.
- All nginx logs and direct boot evidence are regular non-symlink files covered
  by `evidence.sha256`.
- The formal report target revalidates input, artifact, boot, output, and
  evidence hashes, reconstructs combined observations from direct boot
  directories, reruns the analyzer, and byte-compares all analysis outputs.
- The analyzer requires exact event types/counts, `pass == true`, V2 protocol,
  fixed timeout, suite/source/result identity, clean commits, and matching
  kernel identity.
- Shared multi-boot validation and its negative tests reject directory,
  symlink, nested, moved, and missing evidence.

## Round 2

The evidence reviewer returned GO after verifying all five repairs.

The lifecycle reviewer found one new blocker: the worker temp-I/O probe had
been placed before nginx spawn and worker discovery. It therefore could only
fail and was not testing a worker.

## Round 3

The probe was moved after the current state establishes the nginx master,
worker PID, served body, and logical/physical configuration identity. The
lifecycle reviewer then returned GO, confirming:

- the worker can traverse the runtime boundary;
- the actual worker creates the retained request-body file;
- graceful and checked forced shutdown establish reap; and
- log capture and runtime deletion occur only after reap.

Final verdict: GO for a clean-commit real KVM dependency preflight.
