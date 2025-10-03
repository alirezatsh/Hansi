hansi
=================

**hansi** is a CLI tool for fast bootstrapping and structuring your projects.  
It helps you quickly set up frameworks like **Django, FastAPI(soon), and Node.js(soon)**, and provides a clean, local-development-ready structure out of the box.  

---

## Features  

- Quick and easy project initialization  
- Database options: **SQLite** or **PostgreSQL**  
- Built-in support for **Docker** and **Docker Compose**  

---

## Requirements  

At the moment, **hansi only works on Linux systems**.  
Before installing hansi, make sure the following are installed on your machine:  

- [Node.js](https://nodejs.org/) (v18 or higher)  
- [Docker](https://docs.docker.com/engine/install/) (latest stable version)  

---

## Guides

For every project you create with **hansi**, a `guide.txt` file is automatically generated in the root directory.  
Before doing anything else, you should read this file to get familiar with the setup process and understand how the project works.  

---

## Installation  

You can install **hansi** globally using npm:  

```bash
npm install -g hansi
```

<!-- usagestop -->
# Commands
<!-- commands -->
* [`hansi local django init`](#hansi-local-django-init)
* [`hansi local django init --db sqlite --dockerfile`](#hansi-local-django-init-sqlite-dockerfile)
* [`hansi local django init --db postgres`](#hansi-local-django-init-postgres)
* [`hansi local django init --db posgres --dockerfile`](#hansi-local-django-init-postgres-dockerfile)
* [`hansi local django init --db postgres --dockercompose`](#hansi-local-django-init-postgres-dockercompose)


## `hansi local django init`

Initialize a Django project with default sqlite DB.

```
USAGE
  $ hansi local django init [--db sqlite|postgres] [--dockerfile] [--dockercompose]

FLAGS
  --db=<option>    [default: sqlite] Database type
                   <options: sqlite|postgres>
  --dockercompose  Create docker-compose.yml
  --dockerfile     Create Dockerfile

DESCRIPTION
  Initialize a Django project with optional DB, Docker, and docker-compose
```


## `hansi local django init --db sqlite --dockerfile`

Initialize a Django project with sqlite DB and a running Dockerfile


```
USAGE
  $ hansi local django init --db sqlite --dockerfile

DESCRIPTION
  Creates a Django project with SQLite database.
  Generates and start a Dockerfile for containerized development.
  Migrations and superuser creation are done manually inside the container.
```

## `hansi local django init --db postgres`

Initialize a Django project with postgres DB.


```
USAGE
  $ hansi local django init --db postgres

DESCRIPTION
  Creates a Django project configured for PostgreSQL.
  You need to update your .env file with correct DB credentials manually.
```

## `hansi local django init --db postgres --dockerfile`


```
USAGE
  $ hansi local django init --db postgres --dockerfile

DESCRIPTION
  Creates a Django project with PostgreSQL database.
  Dockerfile is created but migrations and superuser creation are NOT run automatically.
  Update your .env with DB credentials and run:
```

## `hansi local django init --db postgres --dockercompose`


```
USAGE
  $ hansi local django init --db postgres --dockercompose

DESCRIPTION
  Creates a Django project configured for PostgreSQL with docker-compose setup.
  Both web and db services are defined and running.
  Migrations and superuser are run automatically inside the containers.
```


_See code: [src/commands/local/django/init.ts](https://github.com/alirezatsh/Hansi/blob/v0.0.1/src/commands/local/django/init.ts)_


_See code: [@oclif/plugin-plugins](https://github.com/oclif/plugin-plugins/blob/v5.4.47/src/commands/plugins/update.ts)_
<!-- commandsstop -->
