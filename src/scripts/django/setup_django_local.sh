#!/usr/bin/env bash
set -euo pipefail

# Colors for echo
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

PROJECT_NAME=$1
DB_TYPE=${2:-sqlite}
DOCKERFILE=${3:-n}
DOCKER_COMPOSE=${4:-n}
SUPERUSER=${5:-n}
OS_TYPE=${6:-linux}

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Usage: $0 PROJECT_NAME [sqlite|postgres] [dockerfile y/n] [docker_compose y/n] [superuser y/n] [os_type]${RESET}"
  exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
  echo -e "${RED}Directory $PROJECT_NAME already exists. Aborting.${RESET}"
  exit 1
fi

# --------------------------- Create project and virtualenv ---------------------------

echo -e "${GREEN}Creating project directory and virtual environment...${RESET}"
mkdir -p "$PROJECT_NAME"
python3 -m venv "$PROJECT_NAME/venv"

# --------------------------- Activate virtual environment ---------------------------

echo -e "${GREEN}Activating virtual environment...${RESET}"
if [ "$OS_TYPE" = "windows" ]; then
  cd "$PROJECT_NAME/venv/Scripts"
  .\activate
  cd ../../../
else
  source "$PROJECT_NAME/venv/bin/activate"
fi

# --------------------------- Install Python packages # ---------------------------

echo -e "${GREEN}Installing required Python packages...${RESET}"
pip install --upgrade pip
pip install django djangorestframework psycopg2-binary celery python-dotenv

# --------------------------- Start Django project ---------------------------
echo -e "${GREEN}Starting Django project...${RESET}"
django-admin startproject "$PROJECT_NAME" "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit 1

SETTINGS_FILE="$PROJECT_NAME/settings.py"

# --------------------------- Configure PostgreSQL if selected ---------------------------

if [ "$DB_TYPE" = "postgres" ]; then
  echo -e "${YELLOW}Configuring PostgreSQL settings...${RESET}"
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

  cat > .env <<EOL
DB_NAME=${PROJECT_NAME}_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432
EOL
fi

# --------------------------- Copy guide files ---------------------------

GUIDE_DIR="../guides"
echo -e "${GREEN}Copying guide file...${RESET}"
if [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ]; then
  cp "$GUIDE_DIR/with-sqlite/guide.txt" guide.txt
elif [ "$DB_TYPE" = "postgres" ]; then
  cp "$GUIDE_DIR/with-postgres/guide.txt" guide.txt
elif [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" = "y" ]; then
  cp "$GUIDE_DIR/with-sqlite-dockerfile/guide.txt" guide.txt
fi

# --------------------------- Run migrations for SQLite ---------------------------

if [ "$DB_TYPE" = "sqlite" ] && [ "$DOCKERFILE" != "y" ]; then
  echo -e "${GREEN}Running migrations for SQLite...${RESET}"
  python manage.py migrate
fi

# --------------------------- Create .gitignore ---------------------------

echo -e "${GREEN}Creating .gitignore...${RESET}"
cat > .gitignore <<'PY'
*.pyc
__pycache__/
venv/
db.sqlite3
*.log
.env
PY

# --------------------------- Create requirements.txt ---------------------------

echo -e "${GREEN}Creating requirements.txt...${RESET}"
cat > requirements.txt <<'PY'
Django==4.2.24
psycopg2-binary==2.9.10
djangorestframework==3.16.1
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
PY

# --------------------------- Dockerfile section ---------------------------

if [ "$DOCKERFILE" = "y" ]; then
  echo -e "${GREEN}Creating Dockerfile...${RESET}"
  cat > Dockerfile <<'PY'
FROM python:3.12-slim
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
COPY . /app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
PY

  if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}Building Docker image '${PROJECT_NAME}'...${RESET}"
    docker build -t "${PROJECT_NAME}" .
    EXISTING_ID=$(docker ps -a --filter "name=^/${PROJECT_NAME}$" --format '{{.ID}}' || true)
    if [ -n "$EXISTING_ID" ]; then
      docker rm -f "${PROJECT_NAME}" >/dev/null 2>&1 || true
    fi
    echo -e "${GREEN}Running Docker container '${PROJECT_NAME}'...${RESET}"
    if [ "$DB_TYPE" = "postgres" ]; then
      docker run -d --name "${PROJECT_NAME}" --env-file .env -p 8000:8000 "${PROJECT_NAME}"
    else
      docker run -d --name "${PROJECT_NAME}" -p 8000:8000 "${PROJECT_NAME}"
    fi
  else
    echo -e "${RED}Docker not found, skipping docker build/run.${RESET}"
  fi
fi

# --------------------------- Docker-compose section ---------------------------

if [ "$DOCKER_COMPOSE" = "y" ]; then
  echo -e "${GREEN}Creating docker-compose.yml...${RESET}"
  cat > docker-compose.yml <<EOL
version: '3.8'
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

  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose up -d
  elif command -v docker >/dev/null 2>&1; then
    docker compose up -d
  else
    echo -e "${RED}docker-compose not found and docker CLI doesn't support compose. Skipping docker-compose up.${RESET}"
  fi
fi

echo -e "${GREEN}Django project '$PROJECT_NAME' setup completed.${RESET}"
