# LiveStack Local Patches

## 1.2.1 database-pool recovery

Source target:

/srv/oracle-ai-work/livestack/utilities/backend/config/database.js

This patch corrects recovery after Oracle Database becomes temporarily
unavailable while LiveStack remains running.

Changes:

- Treat NJS-530 as a reconnectable error.
- Validate every newly created Oracle connection pool with a real connection
  and ping before publishing the pool for application use.
- Close and discard candidate pools that fail validation.
- Clear the cached pool promise after failed creation or validation.

Apply from the LiveStack source root:

cd /srv/oracle-ai-work/livestack/utilities
patch -p0 < /srv/oracle-ai/patches/livestack/1.2.1-database-pool-recovery.patch

Built image:

oracle-ai/livestack-utilities:1.2.1

Rollback image:

oracle-ai/livestack-utilities:1.2.0
