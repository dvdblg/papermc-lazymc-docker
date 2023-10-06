#!/bin/bash

# Enter server directory
cd papermc

# Set nullstrings back to 'latest'
: ${MC_VERSION:='latest'}
: ${PAPER_BUILD:='latest'}
: ${LAZYMC_VERSION:='latest'}

# Lowercase these to avoid 404 errors on wget
MC_VERSION="${MC_VERSION,,}"
PAPER_BUILD="${PAPER_BUILD,,}"
LAZYMC_VERSION="${LAZYMC_VERSION,,}"

# Get lazymc
if [ ${LAZYMC_VERSION} = latest ]
then
  LAZYMC_VERSION=$(wget -qO - https://api.github.com/repos/timvisee/lazymc/releases/latest | jq -r .tag_name)
fi
LAZYMC_URL="https://github.com/timvisee/lazymc/releases/download/$LAZYMC_VERSION/lazymc-$LAZYMC_VERSION-linux-x64-static"
wget -O lazymc ${LAZYMC_URL}
chmod +x lazymc

# Generate lazymc.toml if necessary
if [ ! -e lazymc.toml ]
then
  ./lazymc config generate
fi

# Get version information and build download URL and jar name
URL='https://papermc.io/api/v2/projects/paper'
if [[ $MC_VERSION == latest ]]
then
  # Get the latest MC version
  MC_VERSION=$(wget -qO - "$URL" | jq -r '.versions[-1]') # "-r" is needed because the output has quotes otherwise
fi
URL="${URL}/versions/${MC_VERSION}"
if [[ $PAPER_BUILD == latest ]]
then
  # Get the latest build
  PAPER_BUILD=$(wget -qO - "$URL" | jq '.builds[-1]')
fi
JAR_NAME="paper-${MC_VERSION}-${PAPER_BUILD}.jar"
URL="${URL}/builds/${PAPER_BUILD}/downloads/${JAR_NAME}"

# Update if necessary
if [[ ! -e $JAR_NAME ]]
then
  # Remove old server jar(s)
  rm -f *.jar
  # Download new server jar
  wget "$URL" -O "$JAR_NAME"
fi

# Update eula.txt with current setting
echo "eula=${EULA:-false}" > eula.txt

# Add RAM options to Java options if necessary
if [[ -n $MC_RAM ]] then
  JAVA_OPTS="-Xms${MC_RAM} -Xmx${MC_RAM} $JAVA_OPTS"
elif [[ -n $MC_RAM_MIN && -n $MC_RAM_MAX ]] then
  JAVA_OPTS="-Xms${MC_RAM_MIN} -Xmx${MC_RAM_MAX} $JAVA_OPTS"
fi

# Update lazymc config command
sed -i -e "s@command =.*@command = \"java -server ${JAVA_OPTS} -jar ${JAR_NAME} nogui\"@" lazymc.toml
# Update lazymc config advertised version (which is commented out by default)
sed -i -e "s@#version =.*@version = \"${MC_VERSION}\"@" lazymc.toml

# Start server
exec ./lazymc start
