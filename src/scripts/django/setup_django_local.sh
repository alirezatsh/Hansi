#!/bin/bash

# Arguments from Python CLI
PROJECT_NAME=$1      
DB_TYPE=$2            
DOCKERFILE=$3        
DOCKER_COMPOSE=$4     
SUPERUSER=$5          

echo "Creating Django project '$PROJECT_NAME'..."

# 1. Create project folder and virtual environment
mkdir -p $PROJECT_NAME
python3 -m venv $PROJECT_NAME/venv
source $PROJECT_NAME/venv/bin/activate

# 2. Install Django and required packages
pip install --upgrade pip
pip install django djangorestframework psycopg2-binary python-dotenv celery

# 3. Start Django project
django-admin startproject $PROJECT_NAME $PROJECT_NAME
cd $PROJECT_NAME || exit

# 4. Configure database in settings.py
SETTINGS_FILE="$PROJECT_NAME/settings.py"

if [ "$DB_TYPE" == "postgres" ]; then
    echo "Configuring PostgreSQL database..."
    cat >> $SETTINGS_FILE <<EOL

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${PROJECT_NAME}_db',
        'USER': 'postgres',
        'PASSWORD': 'postgres',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
EOL

elif [ "$DB_TYPE" == "cloud" ]; then
    read -p "Enter cloud DB URL: " CLOUD_DB_URL
    cat >> $SETTINGS_FILE <<EOL

import dj_database_url
DATABASES = {
    'default': dj_database_url.parse("$CLOUD_DB_URL")
}
EOL
fi

# 5. Run initial migrations
python manage.py migrate

# 6. Optionally create a superuser
if [ "$SUPERUSER" == "y" ]; then
    echo "Creating superuser..."
    python manage.py createsuperuser
fi

# 7. Create .env file
ENV_FILE=".env"
echo "Creating .env file..."
cat > $ENV_FILE <<EOL
SECRET_KEY=$(python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
DEBUG=True
DB_TYPE=$DB_TYPE
EOL

if [ "$DB_TYPE" == "postgres" ]; then
cat >> $ENV_FILE <<EOL
DB_NAME=${PROJECT_NAME}_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432
EOL
fi

# 8. Create .gitignore
echo "Creating .gitignore..."
cat > .gitignore <<EOL
*.pyc
__pycache__/
venv/
db.sqlite3
*.log
.env
EOL

# 9. Optionally create Dockerfile
if [ "$DOCKERFILE" == "y" ]; then
    echo "Creating Dockerfile..."
    cat > Dockerfile <<EOL
FROM python:3.12-slim
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY . /app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOL

    pip freeze > requirements.txt
fi

# 10. Optionally create docker-compose.yml
if [ "$DOCKER_COMPOSE" == "y" ]; then
    echo "Creating docker-compose.yml..."
    cat > docker-compose.yml <<EOL
version: '3.8'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ${PROJECT_NAME}_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
      - rabbitmq
  celery:
    build: .
    command: celery -A $PROJECT_NAME worker -l info
    volumes:
      - .:/app
    depends_on:
      - db
      - rabbitmq
  celery-beat:
    build: .
    command: celery -A $PROJECT_NAME beat -l info
    volumes:
      - .:/app
    depends_on:
      - db
      - rabbitmq
EOL
fi

echo "Django project '$PROJECT_NAME' setup completed!"
