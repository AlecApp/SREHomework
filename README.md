# SREHomework
This repo contains the modified todo-api Dockerfile, the modified docker-compose.yml, and the Terraform files.

##### General note: Encountered several problems with my dev environment. Spent a couple hours partitioning extra HDD space, installing CLI tools, etc.

##### General note 2: This readme is wordier than usual, since I'm not just covering the practical stuff but also my rational and failures.

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
* Ran `docker-compose up`, expecting errors. Got error message about named volume in service "db" not being declared in volumes. Researched error.
* Looked at file. Reasoned that **`db/postgres`** was probably a typo of **`db:/postgres`**. Hard to know without being more familiar with Postgres and what's supposed to happen here.
* Added **`db/postres-init.sql:`** in **`volumes:`** anyway. Expected this to not work. Was correct, got regex error.
* Made edits: Changed **`db/postgres-init.sql:`** to **`db:/postgres-init.sql/`** and added **`db:`** to volumes. Since this is two changes and the readme said there were two bugs, I'm moving forward under the assumption that I've found them. Waiting for further errors to confirm/deny.
* Ran `docker-compose up` again. Images built successfully. However, encountered port binding error. **Port 0.0.0.0:80 already in use.**
* Downloaded netstat tools, determined that apache was starting at launch and binding to that port. Stopped apache.
* Ran `docker-compose up` again. Images built successfully. However, errors encountered when running. The console kept spitting out an error from api_1 when starting the NEST application: **ERROR: connect ECONNREFUSED 0.0.0.0:5432**
* After spitting out the same error dozens of times, **sre_homework_api_1 exited with code 1**.
* Researched error. Research suggested it was due to the database (5432 is Postgres' port) not being properly linked to the api. Research also suggested the error was related to running multiple Docker containers on the same system.
* Looked at file again. Reasoned that **`postgres-init.sql/docker-entrypoint-initdb.d/postgres-init.sql`** might possibly be a distortion of **`/docker-entrypoint-initdb.d/postgres-init.sql`** on the basis of "postgres-init.sql" being repeated twice, and it seemed odd that the file would be in a directory with an identical name.
* Also noted that there was no POSTGRES_USER field to go with the POSTGRES_PASSWORD field. Noted that this might be a problem.
* Made the **`posgres-init.sql`** change suggested above. Ran `docker-compose up` again. No change, same **ECONNREFUSED** error.
* Connected to 127.0.0.1 via Chrome just to see if this error could be ignored. Site came up, but its functions didn't work.
* Since I'm now uncertain whether this error is related to my local Docker setup, a mistake in the todo-api Dockerfile, or some mistake in the docker-compose.yml, I'm putting this on hold and moving on to the Terraform files while I wait for assistance.

### Process for Terraform
* Decided to use modules to be more professional. Found a lot on GitHub: https://github.com/terraform-aws-modules
* Mistakenly cloned a module repo to local system, thinking I needed the source. Quickly learned that wasn't how it worked.
* Took ten minutes to research modules on Terraform's site, gaining familiarity.
* Planned out the infrastructure based on 3-tier design.
* Successfully imported vpc module into a fresh config.tf and began gathering other modules and planning infrastructure layout.
* Realized that the module syntax for properties (e.g. id) wasn't the same as standard Terraform. Spent more time reading through the individual module references.
* Wrote config for a VPC to hold everything. 1 public subnet and 3 private subnets (1 for the EC2 instance, 2 for the DB instance across multiple AZ).
* Ran **`terraform plan`** and **`terraform apply`**. No problems.
* Continued to expand config, adding security groups, ingress/egress rules. Added ELB to the public subnet, created listeners on port 80, attached to EC2 instance.
* Ran **`terraform plan/apply`** again. No major issues.
* Added DB module to code. Had trouble configuring it for postgres (the default example was mysql). Succeeded after some Googling + trial and error.
* Noticed security groups were missing egress rules. Fixed that.
* Ran **`terraform plan/apply`** again. No further issues.
#### **THE TERRAFORM CODE IS STILL NOT FINISHED**.  
It lacks the CloudWatch/SNS chain to notify admins of ELB health alerts. Planning to implement that next. It also lacks variable abstraction (except for my AWS account keys, of course) and logging. Finally, the security groups have no port restrictions (except for the ELB). They **are** configured to block traffic that isn't from the correct source, however (as requested in the readme). I just don't know which ports to close for the internal connections.

#### **Futher Considerations**
I'm wondering if it might be better to create IAM roles instead of creating security groups to filter traffic. If I use IAM roles, I could still access the instances myself if needed while also restricting traffic to the required sources. Something to consider?

## Current State of Project  
The Dockerfile seems to be ready.  
The docker-compose.yml is returning errors that may or may not be related to it.  
The Terraform config is 90% done. It lacks polishing and the CloudWatch/SNS hooks. Also needs a final, clean test run.
