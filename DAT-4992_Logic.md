### Problems:
1. Devs should be able to pull a pre-built image with the specified tag instead of building locally.
2. Devs should still be able to build locally if they want to.

### Things I know/tried:
1. `docker-compose` has no `-e` or `--env` flag. That option is exclusive to `docker`. See: https://github.com/docker/compose/issues/6170
2. The `--build` flag for `docker-compose` does NOT allow you to specify an image or build directory. (As I understand it) It's a Boolean that forces the already-defined images in the .yml file to all be built before any are deployed to containers.
3. The `--no-build` option cannot be used if the .yml file contains a build directory e.g. `build: .`

### My Solution:
1. Modify the main Compose .yml so that it [A] Defaults to pulling the staging image and [B] lets Devs define an image to pull.
> This is accomplished by changing `image: ` to accept a variable. This variable must be passed on the command line (e.g. `KEY=VALUE docker-compose up`). There's no way to pass the variable to the command as an option/parameter.
2. Modify the main Compose .yml to remove the `build: .` statement, to stop the (now unnecessary) building and potential errors.
3. Create a second .yml file, an override file that contains only the `build: .` statement and the local image name `image: liquibase-hub`.
> This will be merged over the main file (using `-f`) to reinsert the original local build logic if desired.
4. (OPTIONAL) Created a shell script because typing `docker-compose -f docker-compose-build-local.yml up` is tedious. The shell script reduces this to `sh run.sh -b`. This is OPTIONAL not required. It's possible that including it would be unnecessarily complicating things.

### Other Things:
I looked into using a .env file to set environment variables like the image tag. But the problem with that is as follows:
1. It doesn't reduce file count. We still need to add a new file (either the .env or the override .yml)
2. It doesn't solve the problem of re-adding the `build: .` command, etc. to allow devs to continue building locally.
3. It would require manually editing the tag variable whenever a dev wanted a different image. And the point of this ticket is to get AWAY from manual edits.

### OTHER Other Things:
An .env file would still be a great addition for 1 reason: Currently, our COMPOSE_PROJECT_NAME is undefined. So, it defaults to the directory name: liquibase-hub.
This is fine, but it does introduce a potential error because if our directory is NOT named liquibase-hub, then the application fails to build. (I know, I tried.) Adding a .env file that defines COMPOSE_PROJECT_NAME as liquibase-hub is a simple safeguard.

### Final Word:
There might be other ways of accomplishing these things. But I honestly think this is the simplest.
