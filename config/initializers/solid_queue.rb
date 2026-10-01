# frozen_string_literal: true

# Running jobs get this long to finish when the worker stops (deploys, memory guard). Covers an EPUB build
# (about 30 s) and stays under App Platform's 120 s termination grace period.
SolidQueue.shutdown_timeout = 60.seconds

# Runs in the bin/jobs supervisor only; web processes never start Solid Queue.
SolidQueue.on_start { Workers::MemoryGuard.start }
