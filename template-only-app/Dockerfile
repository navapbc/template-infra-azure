FROM python:3-alpine as release

RUN adduser --system --disabled-password --no-create-home app

WORKDIR /app

RUN apk --no-cache add \
  postgresql16-client~=16 \
  pipx \
  gcc musl-dev python3-dev libffi-dev openssl-dev cargo make
# https://github.com/Azure/azure-cli/issues/19591
RUN pipx install --global azure-cli
RUN mkdir -p /home/app/.azure && chmod -R 777 /home/app/.azure

COPY requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

COPY db-migrate /usr/bin/
COPY migrations.sql /app/
COPY *.py /app/
COPY templates /app/templates

# Set the host to 0.0.0.0 to make the server available external
# to the Docker container that it's running in.
ENV HOST=0.0.0.0

# Run as non-root user
USER app

# Create a basic webserver and run it until the container is stopped
CMD ["python", "-m", "app"]
