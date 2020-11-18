# SREHomework
This repo contains the modified todo-api Dockerfile, the modified docker-compose.yml, and the Terraform files.

##### General note: Encountered several problems with my dev environment. Spent a couple hours partitioning extra HDD space, installing CLI tools, etc.

### Process for todo-api Dockerfile
* Built todo-api image to see initial filesize and watch how everything built. Image size: 1.21gb
* Read https://docs.docker.com/develop/develop-images/multistage-build/ and other resources
* Being unfamiliar with npm, reviewed npm docs and looked at package.json to better understand what the Dockerfile is actually doing.
* Noticed that the base image was node:12 instead of node:12-alpine, which is smaller.
* Attempted to split build process into stages, copying only the necessary dependencies from each stage instead of the full image. Image size: 1.13gb
* Reasoned that either I wasn't seeing a way to further break down the build process or the base image was too large.
* Switched image to node:12-alpine. Image size: 300MB. Assumed that was the correct answer. Hard to know without testing.
* Remembered after the fact that I could use the todo-client's Dockerfile as an example, checked it out and found that alpine WAS being used. So, I guess my answer was correct.

### Process for docker-compose.yml
* Ran docker-compose.yml through yaml linter to check for basic syntax errors like extra whitespace.
* Ran `docker-compose up`, expecting errors. Got error message about named volume in service "**db**" not being declared in volumes. Researched error via Google.
* Looked at file. Reasoned that "**db/postgres**" was probably a typo of "**db:/postgres**". Hard to know without being more familiar with Postgres and what's supposed to happen here.
* Added "**db/postres-init.sql:**" in volumes anyway. Expected this to not work. Was correct, got regex error.
* Made edits: Changed "**db/postgres-init.sql:**" to "**db:/postgres-init.sql/**" and added **db:** to volumes. Since this is two changes and the readme said there were two bugs, I'm moving forward under the assumption that I've found them. Waiting for further errors to confirm/deny.
* Ran `docker-compose up` again. Image built successfully. However, encountered port binding error. **Port 0.0.0.0:80 already in use.**
* Downloaded netstat tools, determined that apache was starting at launch and binding to that port. Stopped apache.
* Ran `docker-compose up` again. Image built successfully. However, todo-api kept spitting out an error message: 
* However, errors encountered when running. The console kept spitting out an error from api_1 when starting the NEST application: **ERROR: connect ECONNREFUSED 0.0.0.0:5432**
* Researched error. Research suggested it was due to the database (5432 is Postgres' port) not being properly linked to the api.
* Looked at file again. Reasoned that "`postgres-init.sql/docker-entrypoint-initdb.d/postgres-init.sql`" might possibly be a distortion of "`/docker-entrypoint-initdb.d/postgres-init.sql`" on the basis of "postgres-init.sql" being repeated twice, and it seemed odd that the file would be in a directory with an identical name.
* Made the change suggested above. Ran `docker-compose up` again. No change, same **ECONNREFUSED** error.
* Connected to 127.0.0.1 via Chrome just to see if this error could be ignored. Site came up, but its functions didn't work.
* Since I'm now uncertain whether this error is related to my local Docker setup, a mistake in the todo-api Dockerfile, or some mistake in the docker-compose.yml, I'm putting this on hold and moving on to the Terraform files while I wait for assistance.

##### Side Note: While building the images a warning appeared: `karma-jasmine-html-reporter@1.5.4 has incorrect peer dependency "jasmine-core@>=3.5"`
Noting it here just in case it becomes relevant to future problems.


