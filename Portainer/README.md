# Container stack templates

These are Compose/Portainer stack definitions. Review a private local copy,
configure paths/credentials/image versions, and deploy through your own Portainer
stack UI or `docker compose -f Portainer/<file> up -d`. Requires a Docker host,
image registry access, available ports, and writable persistent directories.
No stacks were deployed for this documentation.

## [pihole.yml](pihole.yml)

Runs `pihole/pihole:latest` with DNS TCP/UDP 53, DHCP UDP 67, and HTTP 80 published,
bind-mounting Synology-style paths to `/etc/pihole` and `/etc/dnsmasq.d`. It sets
the timezone, adds NET_ADMIN, and restarts unless stopped. Port conflicts with
other DNS/web services must be resolved before deployment. Review current image
configuration conventions: the password setting in this example is commented
out and image versions are not pinned. DHCP networking and privileges require
host-specific configuration; publishing UDP 67 alone does not establish working
DHCP across your network. Persistent directories can contain sensitive DNS/admin data.

## [redmine.yml](redmine.yml)

Starts MariaDB 11.4 and Redmine, with database/data/assets/themes bound to
Synology paths, a configured user ID/group, and Redmine port 3000 published on
host 3434. Database credentials are literal example values in the YAML; replace
them privately before deployment. The services must agree on database credentials
and filesystem ownership. `depends_on` waits only for service start, not database
readiness. A Redmine wget health check is configured; image/tool availability
must be checked for your chosen version. Restart is limited to five failures,
and removing containers does not remove bind-mounted data. Back up the database
and uploaded files together before upgrades.
