---
description: Update the docker containers in this repository with their latest versions.
agent: build
---

Update the docker containers defined in this repository in modules/container-images/default.nix.

To do this follow these steps for each docker container. Use subagents to fan out sourcing information in parallel if that is helpful.

1. Use github releases and skopeo to resolve the latest container version.
2. Update the definition in the container-images/default.nix file.
3. Then resolve the changed containers to their hosts and one by one deploy each host.
4. Use our monitoring tools and wait a bit to make sure the services are still running.

# Special case immich
Immich is a special snowflake and they all but require you to run the specific pinned version of
the postgres container they define in their release docker compose files per release version.
To check if we need a new database version for immich do the following after resolving if
immich needs to update in the first place. If not you can skip the rest of this.

1. In the immich repository find the commit the release is tagged to.
2. In that git tag fetch the file `docker/docker-compose.prod.yml`
3. That file should tell you the specific docker image hash to use for the database.
4. Update our definition to use that hash.
