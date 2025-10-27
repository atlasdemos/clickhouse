# ClickHouse Schema Management with Atlas Demo

This repository contains the code shown in our [ClickHouse Schema Management with Atlas demo video](https://youtu.be/6DMO0LeuG3Y).
To set up with your own ClickHouse instance, follow the instructions below.

For more about using ClickHouse with Atlas, check out our [ClickHouse guide](https://atlasgo.io/guides/clickhouse/automatic-migrations).

## What's inside?
* [Quick Start with Docker](#quick-start-with-docker)
* [Setting up](#prerequisites)
* [Local declarative workflow](#declarative-migrations)
* [Local versioned workflow](#versioned-migrations)
* [Using Atlas in CI/CD](#automating-migrations-with-github-actions)
  * [Setting up](#prerequisites-1)
  * [CI/CD for declarative migrations](#declarative-workflow-in-cicd)
  * [CI/CD for versioned migrations](#versioned-workflow-in-cicd)

## Prerequisites

1. ClickHouse instance:
- A running ClickHouse server (local or cloud)
- Database credentials for authentication
2. Atlas installed on your machine:
```
curl -sSf https://atlasgo.sh | sh
```
3. An Atlas Pro account. To create or log in to an account, run:
```
atlas login
```

## Quick Start with Docker

The easiest way to get started is using the provided Docker Compose setup:

1. **Start the ClickHouse cluster:**
```shell
./setup-docker.sh
```

This will:
- Start a ClickHouse instance with two databases (main and dev database)
- Create the necessary databases
- Set up environment variables
- Verify connectivity

2. **Alternative: Manual Docker setup:**
```shell
# Start the cluster
docker compose up -d

# Wait for ClickHouse to be ready
sleep 10

# Set environment variables
export CLICKHOUSE_URL="clickhouse://default:@localhost:9000/demo"
export CLICKHOUSE_DEV_URL="clickhouse://default:@localhost:9001/dev"
```

3. **Stop the cluster when done:**
```shell
docker compose down
```

### Docker Setup Details

The Docker Compose configuration includes:
- **ClickHouse instance** on ports 8123 (HTTP) and 9000 (Native)
- Persistent data volumes for both instances
- Health checks to ensure services are ready
- Custom configuration for development use

### Environment Variables

The setup script will automatically copy `.env.dist` to `.env` if it doesn't exist. You can then edit the `.env` file to customize your configuration:

```shell
# The setup script handles this automatically, or you can do it manually:
cp .env.dist .env
# Edit .env with your preferred settings
```

The `.env` file contains these environment variables:
- `CLICKHOUSE_HOST`, `CLICKHOUSE_PORT`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, `CLICKHOUSE_DATABASE` - Instance connection settings
- `CLICKHOUSE_DATABASE` - Name of the main database
- `CLICKHOUSE_DEV_DATABASE` - Name of the dev database settings
- `CLICKHOUSE_URL`, `CLICKHOUSE_DEV_URL` - Pre-constructed connection URLs (using variable substitution)
- `ATLAS_CLOUD_TOKEN` - Your Atlas Cloud authentication token

## Setting up ClickHouse authentication

### Environment setup

Set your ClickHouse credentials as environment variables:

```shell
source .env
```

The connection URLs (`CLICKHOUSE_URL` and `CLICKHOUSE_DEV_URL`) are automatically constructed from the individual settings using variable substitution in the `.env` file.

#### Create a dev database

Atlas's automatic migrations flow uses a secondary [dev database](https://atlasgo.io/concepts/dev-database) 
to simulate the schema changes.

The dev database connection URL (`CLICKHOUSE_DEV_URL`) is automatically constructed from the dev database settings in the `.env` file.

#### Configuration file (optional)

This repository includes an `atlas.hcl` configuration file containing an environment called _demo_. It consists of 
the variables needed to run most Atlas commands, so you can add the flag `--env demo` to your commands instead of 
each individual variable flag (e.g., `-u`, `--dev-url`, etc.).

The guided steps below will include each variable flag in the commands, but you may use the `--env` flag if you 
prefer. The [declarative workflow CI/CD section](#declarative-workflow) will use this environment in the workflow 
file rather than writing out each variable.

## Inspecting your target database

To begin defining our desired state as code, we need to retrieve the current schema definition to use as the 
base for our changes. We call this [_inspecting our database_](https://atlasgo.io/inspect).

To inspect our ClickHouse schema and store it in SQL format, run:

```shell
atlas schema inspect --env demo --format '{{ sql . }}' > schema.sql
```

`schema.sql` is the file we will alter to define the desired state we want to migrate our target database to.

## Declarative migrations

Atlas supports a workflow called [_declarative schema migrations_](https://atlasgo.io/declarative/apply). In this 
workflow, you first define the desired state of your database schema. Then, Atlas calculates the diff between the 
desired state and the actual state of your database, and generates the SQL commands that will bring your database 
to the desired state.

To use declarative migrations on your ClickHouse database:

1. Push your desired schema to Atlas Cloud by running:
```shell
atlas schema push --env demo
```
_Replace `clickhouse-demo` with your desired Atlas Cloud repository name._

2. Update your desired schema definition by adding, removing, and/or altering the SQL statements.
3. Run the following command to create a migration plan for approval:
```shell
atlas schema apply --env demo
```
4. Select `Approve and apply` to apply the migration to your target database.
5. Run the `atlas schema push` command again to update the Atlas Cloud repository.

## Versioned migrations

Atlas also supports a workflow called [_versioned schema migrations_](https://atlasgo.io/versioned/intro). In this 
workflow, the "current state" of your database is defined by a directory of migration files. When you make changes
to the desired state of your database schema, Atlas writes a new file to the migrations directory that takes the 
"current state" to the desired state.

Head to our docs to read more about [Declarative vs Versioned Migrations](https://atlasgo.io/concepts/declarative-vs-versioned).

> [!IMPORTANT]  
> For this demo, we are beginning with an **empty database**. If your database and `schema.sql` file are already 
> populated with objects beyond the default schema, start by creating a [baseline migration](https://atlasgo.io/versioned/apply#existing-databases),
> then proceed to Step 2.

To use versioned migrations on your ClickHouse database:

1. Create a migrations directory by running the following command:
```shell
atlas migrate new init --edit
```
Exit by typing `:q` and hitting _Enter_.

2. Push the migration directory to Atlas Cloud by running:
```shell
atlas migrate push --env demo
```
_Replace `clickhouse-demo` with your desired Atlas Cloud repository name._

3. Update your desired schema definition by adding, removing, and/or altering the SQL statements.
4. Run the following command to create a migration file:
```shell
atlas migrate diff --env demo
```
5. Run the following command to apply the migration file to your target database:
```shell
atlas migrate apply --env demo
```
6. Run the `atlas migrate push` command again to update the Atlas Cloud repository.

> [!NOTE]
> Atlas automatically creates a directory called `migrations` for the migration files. If you'd like to use a different 
> directory for migrations, add `--dir "file://<path/to/dir>"` to all of the above commands.

## Automating migrations with GitHub Actions

Atlas offers AtlasAction tasks that can be used to automate the migration creation process based on our 
[database CI/CD principles](https://atlasgo.io/guides/modern-database-ci-cd) just by opening and merging 
pull requests on GitHub.

### Prerequisites

1. A GitHub repository containing your Atlas code setup and the Actions workflow file (in following steps)
2. An Atlas Cloud bot token stored as a GitHub repository secret
3. The connection URLs stored as GitHub repository secrets

#### Create an Atlas Cloud bot token

Atlas Cloud uses a bot token to connect with your CI/CD pipeline for reporting CI runs to Atlas Cloud and pushing updated 
schemas or migration directories to Atlas Cloud repositories.

Follow [these instructions](https://atlasgo.io/cloud/bots) to create a bot token. 

Then, store it as a secret in your GitHub repository by running:
```shell
gh secret set ATLAS_CLOUD_TOKEN
```

#### Store connection URLs as secrets

Get your connection URLs as strings by running `printenv` for both `CLICKHOUSE_URL` and `CLICKHOUSE_DEV_URL`.

For example:
```shell
printenv CLICKHOUSE_URL

clickhouse://default:@localhost:9000/default
```

Store them as secrets by running
```shell
gh secret set CLICKHOUSE_URL
```
and
```shell
gh secret set CLICKHOUSE_DEV_URL
```

## Declarative workflow in CI/CD

First, set up an Atlas Cloud repository by running:

```shell
atlas schema push --env cloud
```

_Replace `clickhouse-demo` with your Atlas Cloud repository name._

When you update the desired schema file, push it to a new branch in your GitHub repository and make a pull 
request. This will trigger the workflow file.

### Workflow file

Copy the `.github/workflows/ci-atlas-declarative.yaml` file into your repository, replacing `clickhouse-demo` 
with your Atlas Cloud repository name.

Let's go over the jobs.

```yaml
plan:
  if: ${{ github.event_name == 'pull_request' }}
  runs-on: ubuntu-latest
  env:
    GITHUB_TOKEN: ${{ github.token }}
  steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - uses: ariga/setup-atlas@v0
      with:
        cloud-token: ${{ secrets.ATLAS_CLOUD_TOKEN }}
        version: 'beta'
    - uses: ariga/atlas-action/schema/plan@v1
      with:
        env: demo
        dev-url: '${{ secrets.CLICKHOUSE_DEV_URL }}'
```

This first `plan` section occurs when the pull request is opened.

Here, we ensure that Atlas is installed and use your Atlas Cloud token for authentication.

Then, Atlas creates the migration plan that takes our target database to the desired schema state 
defined in our "demo" environment in the `atlas.hcl` file. This plan is then linted and both the plan 
and lint report are commented on the PR, along with a link to view the plan in your Atlas Cloud repository.

```yaml
push:
  if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
  runs-on: ubuntu-latest
  env:
    GITHUB_TOKEN: ${{ github.token }}
  steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - uses: ariga/setup-atlas@v0
      with:
        cloud-token: ${{ secrets.ATLAS_CLOUD_TOKEN }}
        version: 'beta'
    - uses: ariga/atlas-action/schema/plan/approve@v1
      id: plan-approve
      with:
        env: demo
        dev-url: '${{ secrets.CLICKHOUSE_DEV_URL }}'
    - uses: ariga/atlas-action/schema/push@v1
      with:
        env: demo
        dev-url: '${{ secrets.CLICKHOUSE_DEV_URL }}'
    - uses: ariga/atlas-action/schema/apply@v1
      with:
        env: demo
        dev-url: '${{ secrets.CLICKHOUSE_DEV_URL }}'
```

This next `push` section occurs when the pull request is merged to the main branch.

We start by re-ensuring that Atlas is properly installed and Atlas Cloud is authenticated. 

Next, the migration plan is marked "approved" and the new schema pushed to the Atlas Cloud repository.

Finally, the migration plan is applied to the target database.

## Versioned workflow in CI/CD

First, set up an Atlas Cloud repository by running:

```shell
atlas migrate push clickhouse-demo --dev-url "$CLICKHOUSE_DEV_URL"
```

_Replace `clickhouse-demo` with your Atlas Cloud repository name._

When you create a new migration file locally, push the updated desired schema and migrations directory to 
a new branch in your GitHub repository and make a pull request. This will trigger the workflow file.

### Workflow file

Copy the `.github/workflows/ci-atlas-versioned.yaml` file into your repository, replacing `clickhouse-demo` 
with your Atlas Cloud repository name.

Let's go over the jobs.

```yaml
- uses: ariga/setup-atlas@v0
  with:
    cloud-token: '${{ secrets.ATLAS_CLOUD_TOKEN }}'
    version: 'beta'
```

Here, we ensure that Atlas is installed and use the Atlas Cloud token for authentication.

```yaml
- uses: ariga/atlas-action/migrate/lint@v1
  with:
    dir: 'file://migrations'
    dev-url: '${{ secrets.CLICKHOUSE_DEV_URL }}'
    dir-name: 'clickhouse-demo'
  env:
    GITHUB_TOKEN: '${{ github.token }}'
```

Next, we lint the new migration file using Atlas's analyzers and checks to ensure that the migration is safe to 
apply. The results are reported on the PR when complete and resported to Atlas Cloud.

> [!NOTE]
> You can define custom rules based on your organization's policy that the linter will also verify. 
> Read more in our [documentation](https://atlasgo.io/lint/rules).

```yaml
- uses: ariga/atlas-action/migrate/push@v1
  if: github.ref == 'refs/heads/main'
  with:
    dir: 'file://migrations'
    dev-url:  '${{ secrets.CLICKHOUSE_DEV_URL }}'
    dir-name: 'clickhouse-demo'
- uses: ariga/atlas-action/migrate/apply@v1
  if: github.ref == 'refs/heads/main'
  with:
    dir: 'file://migrations'
    url: '${{ secrets.CLICKHOUSE_URL }}'
```

When the pull request is merged to the main branch, two actions occur:
1. Atlas pushes the updated migration directory to the Atlas Cloud repository
2. Atlas applies the new migration to the target database

> [!TIP]
> It is also possible to automate the `migrate diff` command at the start, so all you have to do is push 
> the new desired schema, similar to the declarative workflow.
> 
> Go to our [GitHub Actions documentation](https://atlasgo.io/integrations/github-actions#arigaatlas-actionmigratediff) 
> to learn more.
> 
> Note that this may limit `migrate diff` variations, such as adding keywords to the migration file names.

## Next steps

If you have any further questions, feel free to ask via the Intercom button at the bottom corner of 
[our website](https://atlasgo.io), the Ask AI at the top of our [docs page](https://atlasgo.io/docs), 
or our [Discord server](https://discord.gg/zZ6sWVg6NT).

## References
* [ClickHouse with Atlas guide](https://atlasgo.io/guides/clickhouse)
* [HCL reference for ClickHouse schema definitions](https://atlasgo.io/hcl/clickhouse)
* [Atlas CI/CD on GitHub](https://atlasgo.io/guides/ci-platforms/github-actions)
* [Declarative vs Versioned Workflows article](https://atlasgo.io/concepts/declarative-vs-versioned)
* [Declarative workflow docs](https://atlasgo.io/declarative/apply)
* [Versioned workflow docs](https://atlasgo.io/versioned/intro)