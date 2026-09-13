FROM python:3.12-slim

WORKDIR /app

# Install system dependencies (needed for psycopg2, etc)
RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose the port Koyeb expects (8000)
EXPOSE 8000

# Run migrations and then start the server
CMD alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000
