# Lightweight Alpine-based image for the devops-tool CLI.
FROM alpine:3.20

# Install only what's required:
#   bash        - the scripts are written in Bash
#   coreutils   - GNU date/uname/etc. with full option support
#   iputils     - provides `ping`
#   bind-tools  - provides `nslookup` for host resolution
RUN apk add --no-cache \
        bash \
        coreutils \
        iputils \
        bind-tools

# Create an unprivileged user to run the CLI.
RUN addgroup -S devops && adduser -S devops -G devops

WORKDIR /app

# Copy only the application code into the image.
COPY app/ /app/

# Ensure the script is executable.
RUN chmod +x /app/app.sh

USER devops

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
