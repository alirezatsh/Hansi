#!/bin/bash
set -euo pipefail

# ------------------- Colors -------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# ------------------- Variables -------------------
PROJECT_NAME=${1:-}
DB_TYPE=${2:-sqlite}
DOCKERFILE=${3:-n}
DOCKER_COMPOSE=${4:-n}

PROJECT_DIR="$(pwd)/$PROJECT_NAME"
SETTINGS_FILE="$PROJECT_DIR/$PROJECT_NAME/settings.py"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUIDE_DIR="$SCRIPT_DIR/../../guides/django"

# ------------------- Functions -------------------
usage() {
  echo -e "${RED}Usage: $0 PROJECT_NAME [sqlite|postgres] [dockerfile y/n] [docker_compose y/n]${RESET}"
  exit 1
}

check_inputs() {
  if [ -z "$PROJECT_NAME" ]; then
    usage
  fi
  if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Directory $PROJECT_NAME already exists. Aborting.${RESET}"
    exit 1
  fi
}

create_project_env() {
  echo -e "${GREEN}Creating project directory and virtual environment...${RESET}"
  mkdir -p "$PROJECT_NAME"
  python3 -m venv "$PROJECT_NAME/venv"

  echo -e "${GREEN}Activating virtual environment...${RESET}"
  source "$PROJECT_NAME/venv/bin/activate"

  pip install django psycopg2-binary
}

create_requirements() {
  cat > "$PROJECT_DIR/requirements.txt" <<PY
Django==4.2.24
djangorestframework==3.16.1
psycopg2-binary==2.9.10
celery==5.5.3
django-celery-results==2.5.1
django-celery-beat==2.6.0
whitenoise==6.6.0
django-filter==24.3
django-extensions==3.2.3
django-cors-headers==4.4.0
django-storages==1.14.4
djangorestframework-simplejwt==5.3.1
drf-spectacular==0.27.2
django-redis==5.4.0
Faker==28.4.1
factory-boy==3.3.1
pytest==8.3.3
pytest-django==4.8.0
python-dotenv==1.0.1
boto3==1.40.42
Pillow==11.3.0
PY
}

start_django_project() {
  echo -e "${GREEN}Starting Django project...${RESET}"
  django-admin startproject "$PROJECT_NAME" "$PROJECT_NAME"
  cd "$PROJECT_DIR" || exit 1
}

configure_postgres() {
  if [ "$DB_TYPE" = "postgres" ]; then
    if [ "$DOCKER_COMPOSE" = "y" ]; then
      echo -e "${YELLOW}Configuring PostgreSQL settings (waiting for connection with Docker)...${RESET}"
    else
      echo -e "${YELLOW}Configuring PostgreSQL settings (no connection attempt)...${RESET}"
    fi

    cat >> "$SETTINGS_FILE" <<'PY'

import os
from dotenv import load_dotenv
load_dotenv(os.path.join(BASE_DIR, ".env"))

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'PROJECT_DB'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'postgres'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
PY
  fi
}

generate_env() {
  if [ ! -f "$PROJECT_DIR/.env" ]; then
    cat > "$PROJECT_DIR/.env" <<EOL
DB_NAME=${PROJECT_NAME}_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=db
DB_PORT=5432
EOL
  fi
}

copy_guide() {
  echo -e "${GREEN}Copying guide file...${RESET}"
  if [ "$DOCKER_COMPOSE" = "y" ]; then
    cp "$GUIDE_DIR/with-dockercompose/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true

  elif [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ]; then
    cp "$GUIDE_DIR/with-sqlite/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true

  elif [ "$DB_TYPE" = "postgres" ] && [ "$DOCKERFILE" != "y" ]; then
    cp "$GUIDE_DIR/with-postgres/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true
    
  elif [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" = "y" ]; then
    cp "$GUIDE_DIR/with-sqlite-dockerfile/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true

  elif [ "$DB_TYPE" = "postgres" ] && [ "$DOCKERFILE" = "y" ]; then
    cp "$GUIDE_DIR/with-postgres-dockerfile/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true
  fi
}

run_migrations() {
  if [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ] && [ "$DOCKER_COMPOSE" != "y" ]; then
    echo -e "${GREEN}Running migrations for SQLite (local environment)...${RESET}"

  elif [ "$DB_TYPE" = "postgres" ] && [ "$DOCKER_COMPOSE" != "y" ]; then
    echo -e "${YELLOW}Skipping migrations (You can run it after configuration).${RESET}"
    
  elif [ "$DOCKERFILE" = "y" ] && [ "$DB_TYPE" = "sqlite" ]; then
    echo -e "${GREEN}Migrations and superuser will be handled inside Docker container...${RESET}"

  elif [ "$DOCKER_COMPOSE" = "y" ]; then
    echo -e "${YELLOW}Migrations will be handled inside docker compose.${RESET}"
  fi
}

create_gitignore() {
  cat > "$PROJECT_DIR/.gitignore" <<'PY'
*.pyc
__pycache__/
venv/
db.sqlite3
*.log
.env
PY
}

create_dockerfile() {
  if [ "$DOCKERFILE" = "y" ] || [ "$DOCKER_COMPOSE" = "y" ]; then
    cat > "$PROJECT_DIR/Dockerfile" <<'PY'
FROM python:3.12-slim
WORKDIR /app
ENV TZ="Asia/Tehran"
RUN apt-get update && apt-get install -y \
    iputils-ping \
    curl \
    netcat-traditional \
    nano \
    git \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
COPY . /app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
PY
    echo -e "${GREEN}Dockerfile created${RESET}"
  fi
}

build_and_run_docker() {
  if [ "$DOCKERFILE" = "y" ] && [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKER_COMPOSE" != "y" ]; then
    echo -e "${GREEN}Building Docker image for $PROJECT_NAME...${RESET}"
    docker build -t "$PROJECT_NAME:latest" "$PROJECT_DIR"

    # ensure host db file exists and has permissive mode so Docker bind-mount won't create a directory
    mkdir -p "$PROJECT_DIR"
    if [ ! -f "$PROJECT_DIR/db.sqlite3" ]; then
      touch "$PROJECT_DIR/db.sqlite3"
      chmod 666 "$PROJECT_DIR/db.sqlite3"
    else
      chmod 666 "$PROJECT_DIR/db.sqlite3" || true
    fi

    echo -e "${GREEN}Running container for $PROJECT_NAME with mounted SQLite...${RESET}"
    docker run -d \
      --name "$PROJECT_NAME" \
      -p 8000:8000 \
      -v "$PROJECT_DIR/db.sqlite3:/app/db.sqlite3" \
      "$PROJECT_NAME:latest"

    echo -e "${GREEN}Waiting for Django to be ready...${RESET}"
    sleep 5

    echo -e "${GREEN}Running migrations inside container...${RESET}"
    docker exec -it "$PROJECT_NAME" python manage.py migrate

    echo -e "${GREEN}Creating Django superuser inside container...${RESET}"
    docker exec -it "$PROJECT_NAME" python manage.py createsuperuser || true
  elif [ "$DOCKER_COMPOSE" = "y" ]; then
    echo -e "${YELLOW}Docker Compose will handle migrations.${RESET}"
  fi
}

create_docker_compose() {
  if [ "$DOCKER_COMPOSE" = "y" ]; then
    cat > "$PROJECT_DIR/docker-compose.yml" <<EOL
version: "3.9"
services:
  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: ${PROJECT_NAME}_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    env_file:
      - .env
    volumes:
      - ${PROJECT_NAME}_db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5
      start_period: 5s
      timeout: 5s

  web:
    build: .
    image: ${PROJECT_NAME}_web:latest
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    env_file:
      - .env
    command: python manage.py runserver 0.0.0.0:8000
    restart: always

volumes:
  ${PROJECT_NAME}_db_data:
EOL

    echo -e "${GREEN}docker-compose.yml created${RESET}"

    echo -e "${GREEN}Building and starting containers...${RESET}"
    docker compose up -d --build
    sleep 5

    echo -e "${GREEN}Running Django migrations inside container...${RESET}"
    docker compose exec web python manage.py migrate

    echo -e "${GREEN}Creating Django superuser inside container...${RESET}"
    docker compose exec -it web python manage.py createsuperuser || true
  fi
}

final_messages() {
  echo -e "${GREEN}Django project '$PROJECT_NAME' setup completed.${RESET}"
  sleep 1
  echo -e "${GREEN}Project '${PROJECT_NAME}' created successfully!${RESET}"
  sleep 3
  echo -e "${GREEN}We created a guide.txt file. Please Check it for more information.${RESET}"
}

# ------------------- Main -------------------
main() {
  check_inputs
  create_project_env
  create_requirements
  start_django_project
  configure_postgres
  generate_env
  copy_guide
  run_migrations
  create_gitignore
  create_dockerfile
  build_and_run_docker
  create_docker_compose
  final_messages
}

main "$@"