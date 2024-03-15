# RADIUS protocol with Microsoft Entra ID back end

## Description

This repository documents how to allow [RADIUS](https://en.wikipedia.org/wiki/RADIUS)-based clients to authenticate against a [Microsoft Entra ID](https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id) (formerly Azure AD) tenant with the help of [FreeRADIUS](https://freeradius.org/).

The configuration described here also adds support for **account lockout** based on repeatedly failed login attempts and the secure **caching** of authentication credentials (password hashes).

## Tools used

- [FreeRADIUS](https://freeradius.org/) as a RADIUS server (with the [FreeRADIUS Docker image](https://hub.docker.com/r/freeradius/freeradius-server) used as base);

- [PostgreSQL](https://www.postgresql.org/) database for automatically [locking out users](https://wiki.freeradius.org/guide/lockout) after a series of failed attempts;

- [Redis](https://redis.io/) for caching credentials (in the form of salted, secure hashes);

- [`freeradius-oauth2-perl`](https://github.com/jimdigriz/freeradius-oauth2-perl/tree/master) module for authenticating users against a Microsoft Entra ID tenant;

## Setup guide

1. Follow the official [getting started guide](https://wiki.freeradius.org/guide/Getting%20Started) to install FreeRADIUS on your server.

   You can check that the basic setup works by authenticating as an user with a hardcoded password, as described in the [Initial tests](https://wiki.freeradius.org/guide/Getting%20Started#initial-tests) section of the guide. See the [`clients.conf`](config/freeradius/clients.conf) and the [`authorize`](config/freeradius/mods-config/files/authorize) files for an example config.

   The [`test-connection.sh`](test-connection.sh) script can also be used for this purpose; it is a thin wrapper around the `radtest` command. Example uses:

   - Try to authenticate using the username `user` and the password `pass` (default credentials for the hardcoded user defined in [`authorize`](config/freeradius/mods-config/files/authorize)):

   ```shell
    ./test-connection.sh
   ```

   - Try to authenticate using the given username and password:

   ```shell
   ./test-connection.sh username password
   ```

2. Follow the instructions from the [`freeradius-oauth2-perl` repo](https://github.com/jimdigriz/freeradius-oauth2-perl/) to allow FreeRADIUS to authenticate requests against Microsoft Entra ID.

   At this point, you should be able to test that authentication works with the help of the `radtest` command or the `test-connection.sh` script:

   ```shell
   ./test-connection.sh user@tenant.onmicrosoft.com <password>
   ```

3. Install PostgreSQL and Redis on your server. Both services should be configured to start automatically (since FreeRADIUS will depend on them).

   It is imperative to [set up a firewall](https://ubuntu.com/server/docs/security-firewall) in order to block external connections to PostgreSQL or Redis.

4. You might also need to install some additional dependencies:

   - If you're using the official FreeRADIUS Docker image, it already comes bundled with all the possible modules.

   - On Ubuntu Server, you can install the packages required for PostgreSQL and Redis support using:

   ```shell
   sudo apt install freeradius-postgresql freeradius-redis
   ```

### Configure account lockout after repeatedly failed login attempts

4. Create a PostgreSQL user and database for FreeRADIUS.

   With Docker, this can be done automatically by configuring the `POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_DB` environment variables (see [`compose.yaml`](compose.yaml) for an example).

   Otherwise, you can do it easily using the command line tool [`psql`](https://www.postgresql.org/docs/current/app-psql.html). Start an interactive PostgreSQL session by using

   ```shell
   sudo -u postgres psql
   ```

   and then run

   ```sql
   CREATE USER freeradius WITH PASSWORD '<some secure password>';
   CREATE DATABASE freeradius;
   GRANT ALL PRIVILEGES ON DATABASE freeradius TO freeradius;
   ```

   to create a new user called `freeradius`, with a secure password choosen by you, with complete access to the newly created `freeradius` database.

5. Initialize the required tables in the newly-created database.

   If using Docker, you can define a database initialization script to be run when the container is first created. See the [`create-database.sh`](config/postgresql/create-database.sh) script and the corresponding lines in [`compose.yaml`](compose.yaml).

   Otherwise, connect to the database by running

   ```shell
   psql --host=localhost --dbname=freeradius --username=freeradius
   ```

   and inputting the password you've defined above, then create the `failed_logins` table by running:

   ```sql
   CREATE TABLE failed_logins (
       id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
       username text NOT NULL CHECK (username <> ''),
       time timestamptz NOT NULL
   );
   CREATE INDEX failed_logins_username_index ON failed_logins (username);
   ```

6. Enable the SQL module for FreeRADIUS, by linking the corresponding file from the `mods-available` directory to the `mods-enabled` directory (e.g. something like `ln -s /etc/freeradius/mods-available/sql /etc/freeradius/mods-enabled/`).

7. Configure the SQL module (you can use [the configuration from this repo](config/freeradius/mods-available/sql) as a guiding example).

   You'll want to set `dialect = "postgresql"`, `driver = "rlm_sql_${dialect}"` (the exact name of the driver depends on which distribution of FreeRADIUS you're using), as well as the `server`, `port`, `login`, `password` and `radius_db` attributes (use the values you've defined when setting up the PostgreSQL database).

   Since we're only interested in using PostgreSQL to track failed login attempts, we can disable other integrations by setting `read_groups = no`, `read_profiles = no` and `read_clients = no`. Also remember to comment out / remove any references to the `sql` module in your default site's config file (see [the config in this repo for an example](config/freeradius/sites-available/default)).

8. Set up the lockout policy. This is mostly based on the [official guide](https://wiki.freeradius.org/guide/lockout) for adding account lockout to FreeRADIUS.

   Copy the [`lockout`](config/freeradius/policy.d/lockout) policy file to your `/etc/freeradius/policy.d` directory and update the [default site's config](config/freeradius/sites-available/default):

   ```
   authorize {
     lockout_check
     ...
   }
   post-auth {
     Post-Auth-Type REJECT {
       lockout_incr
     }
     ...
   }
   ```

   The default lockout policy is configured to block all login attempts (even ones with correct credentials) after 5 failed attempts in the last 10 minutes. This is done to discourage brute force / password guessing attacks.

### Use Redis for persistently caching password hashes

9. It's a good idea to secure your Redis instance with a password (which is not done by default). See [this SO answer](https://stackoverflow.com/a/7548743/5723188) for instructions, or adapt the [`redis.conf`](config/redis/redis.conf) file from this repo.

10. Configure the `freeradius-oauth-perl` module to use Redis as a cache, instead of the in-memory RB tree implementation.

    This can be done by updating the `module` file (usually located at `/opt/freeradius-oauth2-perl/module` if you've followed the official installation instructions). Replace it with the [variant of the file](config/freeradius-oauth2-perl/module) from this repo, or make the changes yourself:

    ```ini
    cache oauth2_cache {
      ...

      # Use Redis instead of `rlm_cache_rbtree`
      driver = "rlm_cache_redis"

      redis {
        server = 'redis' # Use `localhost` if your Redis instance is on the same machine
        port = 6379
        query_timeout = 5
        pool = redis
      }

      ...
    }
    ```

    There is currently a [bug](https://github.com/FreeRADIUS/freeradius-server/issues/5304) with the way FreeRADIUS serializes dates stored in external caches. Until it gets fixed, you will also have to update the [`dictionary`](config/freeradius-oauth2-perl/dictionary) file:

    ```ini
    # ATTRIBUTE	OAuth2-Password-Last-Modified	3000	date # This line has been commented out...
    ATTRIBUTE	OAuth2-Password-Last-Modified	3000	string # ...with this line taking its place.
    ```

    Depending on how you've set up the `freeradius-oauth-perl` module, you might also have to update the corresponding line in the `/etc/freeradius/dictionary` file.

## Contributing

See the [contributing instructions](CONTRIBUTING.md) for information on how to set up your local development environment to work on this repo.

## License

The code and configuration files in this repo are licensed under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html), see the [license file](LICENSE.txt) for details.
