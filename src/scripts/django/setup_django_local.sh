#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

PROJECT_NAME=$1
DB_TYPE=${2:-sqlite}
DOCKERFILE=${3:-n}
DOCKER_COMPOSE=${4:-n}
SUPERUSER=${5:-n}

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Usage: $0 PROJECT_NAME [sqlite|postgres] [dockerfile y/n] [docker_compose y/n] [superuser y/n]${RESET}"
  exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
  echo -e "${RED}Directory $PROJECT_NAME already exists. Aborting.${RESET}"
  exit 1
fi

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

echo -e "${GREEN}Creating project directory and virtual environment...${RESET}"
mkdir -p "$PROJECT_NAME"
python3 -m venv "$PROJECT_NAME/venv"

echo -e "${GREEN}Activating virtual environment...${RESET}"
source "$PROJECT_NAME/venv/bin/activate"

# Create requirements.txt with essential packages for Django project 
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

echo -e "${GREEN}Installing required Python packages from requirements.txt...${RESET}"
python -m pip install --upgrade pip
python -m pip install --no-cache-dir -r "$PROJECT_DIR/requirements.txt"

echo -e "${GREEN}Starting Django project...${RESET}"
django-admin startproject "$PROJECT_NAME" "$PROJECT_NAME"
cd "$PROJECT_DIR" || exit 1

SETTINGS_FILE="$PROJECT_DIR/$PROJECT_NAME/settings.py"

#  Append PostgreSQL database configuration to settings.py 
if [ "$DB_TYPE" = "postgres" ]; then
  echo -e "${YELLOW}Configuring PostgreSQL settings (no connection attempt)...${RESET}"
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

# Generate .env file with default PostgreSQL environment variables 
if [ ! -f "$PROJECT_DIR/.env" ]; then
  cat > "$PROJECT_DIR/.env" <<EOL
DB_NAME=${PROJECT_NAME}_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=db
DB_PORT=5432
EOL
fi

GUIDE_DIR="$(cd "$(dirname "$0")" && cd ../../django/guides && pwd 2>/dev/null || true)"

echo -e "${GREEN}Copying guide file...${RESET}"

if [ "$DOCKER_COMPOSE" = "y" ]; then
  cp "$GUIDE_DIR/with-dockercompose/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true

elif [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ]; then
  cp "$GUIDE_DIR/with-sqlite/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true

elif [ "$DB_TYPE" = "postgres" ]; then
  cp "$GUIDE_DIR/with-postgres/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true
  
elif [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" = "y" ]; then
  cp "$GUIDE_DIR/with-sqlite-dockerfile/guide.txt" "$PROJECT_DIR/guide.txt" 2>/dev/null || true
fi

if [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ] && [ "$DOCKER_COMPOSE" != "y" ]; then
  echo -e "${GREEN}Running migrations for SQLite...${RESET}"

# Run initial migrations automatically only if SQLite is used
  python manage.py migrate
else
  echo -e "${YELLOW}Skipping migrations (PostgreSQL or Docker).${RESET}"
fi

cat > "$PROJECT_DIR/.gitignore" <<'PY'
*.pyc
__pycache__/
venv/
db.sqlite3
*.log
.env
PY

#  Create Dockerfile for building and running the Django app inside container 
if [ "$DOCKERFILE" = "y" ] || [ "$DOCKER_COMPOSE" = "y" ]; then
  cat > "$PROJECT_DIR/Dockerfile" <<'PY'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
COPY . /app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
PY
  echo -e "${GREEN}Dockerfile created"
fi

# Create docker-compose.yml to orchestrate Django and PostgreSQL services 
if [ "$DOCKER_COMPOSE" = "y" ]; then
  cat > "$PROJECT_DIR/docker-compose.yml" <<EOL
version: "3.9"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: \${DB_NAME}
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    ports:
      - "5432:5432"
    env_file:
      - .env
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    env_file:
      - .env
EOL
  echo -e "${GREEN}docker-compose.yml created"
fi

echo -e "${GREEN}Django project '$PROJECT_NAME' setup completed.${RESET}"
sleep 1
echo -e "${GREEN}Project '${PROJECT_NAME}' created successfully!${RESET}"
sleep 3
echo -e "${GREEN}Check guide.txt for more information.${RESET}"
