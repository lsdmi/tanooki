# frozen_string_literal: true

# Running jobs get this long to finish when the worker stops (deploys, memory guard). Covers the longest EPUB
# build seen (72 s) and must stay under the worker's termination.grace_period_seconds in the app spec (120 s),
# or App Platform kills the process mid-job.
SolidQueue.shutdown_timeout = 90.seconds

# Runs in the bin/jobs supervisor only; web processes never start Solid Queue.
SolidQueue.on_start { Workers::MemoryGuard.start }
