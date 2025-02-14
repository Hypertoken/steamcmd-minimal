# Set the User and Group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

# Download a small base image to start with
FROM ubuntu:impish as downloader

# Install Steam dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get autoremove -y \
    && apt-get install -y \
        wget libsdl2-2.0-0:i386

# Set local working directory
WORKDIR /app

# Download and extract Steam
RUN wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    && tar -zxf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Start again with a small base image
FROM ubuntu:impish as installer

# Copy the User and Group IDs from the previous stage
ARG USER_ID
ARG GROUP_ID
ARG STEAM_DEFAULT_PATH=/home/steam/steamcmd.sh

ENV STEAM_PATH=${STEAM_DEFAULT_PATH}

# Add label metadata
LABEL com.renegademaster.steamcmd-minimal.authors="Hypertoken" \
    com.renegademaster.steamcmd-minimal.source-repository="https://github.com/Hypertoken/steamcmd-minimal" \
    com.renegademaster.steamcmd-minimal.image-repository="https://hub.docker.com/repository/docker/hypertoken77/steamcmd-minimal"

# Set local working directory
WORKDIR /home/steam

# Install Steam dependencies, and trim image bloat
RUN apt-get update && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
        lib32stdc++6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the Steam installation from the previous build stage
COPY --from=downloader /app /home/steam

# Copy only the essential libraries required for Steam to function
COPY --from=downloader [ \
    "/usr/lib/i386-linux-gnu/libpthread.so.0", \
    "/usr/lib/i386-linux-gnu/libthread_db.so.1", \
    "/usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.14.0", \
    "/usr/lib/i386-linux-gnu/" \
]

# Link the libraries and executables so that they can be found
# Make a Steam User, and change the ownership of the Steam directory
RUN mkdir -p /home/steam/.steam/sdk64 \
    && ln -s /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0.14.0 /usr/lib/i386-linux-gnu/libSDL2-2.0.so.0 \
    && ln -s /home/steam/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so \
    && useradd -u ${USER_ID} -m -d /home/steam steam \
    && chown -R ${USER_ID}:${GROUP_ID} /home/steam

# Switch to the Steam User
USER ${USER_ID}:${GROUP_ID}
