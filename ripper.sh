#!/bin/bash

# set music dir
music_dir="/home/lucas/Music"

# backup abcde config file
sudo mv /etc/abcde.conf /etc/abcde.conf.bak

#create custom abcde.conf file
sudo touch /etc/abcde.conf
echo "OUTPUTFORMAT='\${TRACKFILE}'" | sudo tee /etc/abcde.conf
cd $music_dir

# generate initial CD data file and time out abcde
timeout 5 abcde -N -f -o flac > /dev/null 2>&1

# get title string and remove leading `DTITLE=`
{
    DTITLE=$(cat ./abcde*/cddbread.* | grep DTITLE)
    rm -r $music_dir/abcde*
} || {
    echo "could not find album data"
    exit 1
}

st_title=${DTITLE//DTITLE=/}

# get artist string, remove leading and trailing whitespace
artist=$(echo $st_title | cut -d/ -f1)
artist=$(echo $artist | xargs -0)

# cancel operation if ABCDE cannot find track names
if [ "$artist" = "Unknown Artist" ]; then
  echo "unknown artist, rip manually"
  exit 1
fi

# try to read disk, echo error and exit script if fails,
# cd into artist dir
{
    cd "$artist"
} || {
    echo "making artist directory..."
    mkdir "$artist" && cd "$artist"
}

# get album string, remove leading and trailing whitespace
album=$(echo $st_title | cut -d/ -f2)
album=$(echo $album | xargs -0)

# try to cd into album directory, create if it does not exist
{
    cd "$album"
} || {
    echo "making album directory..."
    mkdir "$album" && cd "$album"
}

# try to read disk, echo error and exit script if fails
# cd into album dir
{
    abcde -N -f -o flac
} || {
    echo "abcde could not read disk"
    rm -r abcde*
    exit 1
}

# restore original config file
sudo cp /etc/abcde.conf.bak /etc/abcde.conf
