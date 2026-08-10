# PERF-002 main CI retrigger

PR #200 squash-merged as `5298d70218d8e33d766a54813d423bd7de090d16` after final-head Flutter CI #852 passed. The squash message inherited historical `[skip ci]` text from intermediate commits, so GitHub did not start the normal `main` push workflow for that merge SHA.

This docs-only checkpoint intentionally changes no runtime behavior. Its purpose is to run the complete normal Flutter CI on the merged PERF-002 runtime tree, then create a non-skipped `main` commit so exact-main verification and the normal latest-verified promotion pipeline can execute.

PERF-002 remains `IN PROGRESS` until that evidence is reconciled. Physical-device process RSS/GPU residency is not claimed by this checkpoint.
