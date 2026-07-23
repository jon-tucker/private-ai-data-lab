# Oracle REST Data Services stack

This stack pins Oracle REST Data Services 26.2.0 and separates database installation
from normal runtime startup.

`ords-install` is a one-time Compose profile. It reads the SYS and generated
`ORDS_PUBLIC_USER` passwords from standard input, installs ORDS metadata in `FREEPDB1`,
and writes persistent configuration.

`ords` is the long-running service. It receives no SYS credential and starts from the
configuration stored under `/srv/oracle-ai-data/ords`.
