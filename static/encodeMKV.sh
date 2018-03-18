#!/bin/sh
# (c) 2007 Michael Stapelberg
# http://michael.stapelberg.de/Artikel/x264
#
# Return codes:
# 0	Everything was OK
# 1	Not all necessary programs have been installed
# 2	Encoding failed
#
# Syntax is:
# encodeMKV.sh <source-file> <title> [output-file]

# ------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------
# Ogg-Quality (from 0 to 10)
OGG_QUALITY=5
# Bitrate for x264-video
X264_BITRATE=1000

# If you do not want to install the programs in $PATH, you can
# specify their path here hard-coded...
MENCODER=`which mencoder`
MPLAYER=`which mplayer`
OGGENC=`which oggenc`
MKVMERGE=`which mkvmerge`


# ------------------------------------------------------------------------
# Don't touch the script below if you do not know what you're doing :)
# ------------------------------------------------------------------------

# Check if all programs are here before starting the work
if [ -z "${MENCODER}" -o -z "${MPLAYER}" ]; then
	echo "Error: mencoder or mplayer was not found. Please install it"
	exit 1
fi

if [ -z "${OGGENC}" ]; then
	echo "Error: oggenc was not found. Please install it"
	exit 1
fi

if [ -z "${MKVMERGE}" ]; then
	echo "Error: mkvmerge was not found. Please install it"
	exit 1
fi

# Check if the necessary parameters were given
if [ -z "${2}" ]; then
	echo "Syntax: ${0} <source-file> <title> [output-file]"
	exit 1
fi

# Define filenames
SRC_VID=${1}
TMP_VID=${1}.tmpv
TMP_AUD=${1}.tmpa

TITLE=${2}
if [ -z "${3}" ]; then
	MKV=${1}.mkv
else
	MKV=${3}
fi

if [ ! -f "${SRC_VID}" ]; then
	echo "Error: Sourcefile does not exist"
	exit 2
fi

echo -e "\nx264/matroska-encode-script\n"
echo "------------------------------------------------------------------------"
echo "Encoding \"${SRC_VID}\" to \"${MKV}\"..."
echo -e "\tTitle: ${TITLE}"
echo -e "\t(Temporary video file: ${TMP_VID})"
echo -e "\t(Temporary audio file: ${TMP_AUD})"
echo -e "------------------------------------------------------------------------\n"

# Delete the tempfiles
rm -f "${TMP_VID}" "${TMP_AUD}" "${TMP_AUD}.ogg"

# Encode video
${MENCODER} -really-quiet -ovc x264 -x264encopts \
bitrate=${X264_BITRATE}:subq=6:partitions=all:8x8dct:me=umh:frameref=5:bframes=3:b_pyramid:weight_b:pass=1 \
-oac copy -of rawvideo -o "${TMP_VID}" "${SRC_VID}" 1>&- || {
	echo -e "\nError: mencoder could not encode the file. Check the printed errors"
	exit 2
}
${MENCODER} -really-quiet -ovc x264 -x264encopts \
bitrate=${X264_BITRATE}:subq=6:partitions=all:8x8dct:me=umh:frameref=5:bframes=3:b_pyramid:weight_b:pass=2 \
-oac copy -of rawvideo -o "${TMP_VID}" "${SRC_VID}" 1>&- || {
	echo -e "\nError: mencoder could not encode the file. Check the printed errors"
	exit 2
}


# Extract audio
${MPLAYER} -really-quiet -vo null -ao pcm:fast:file="${TMP_AUD}" "${SRC_VID}" || {
	echo -e "\nError: Audio-track could not be extracted via mplayer. Check the printed errors"
	exit 2
}

# Encode audio
${OGGENC} -Q -q${OGG_QUALITY} "${TMP_AUD}" -o "${TMP_AUD}.ogg" || {
	echo -e "\nError: Audio-track could not be converted to ogg. Check the printed errors"
	exit 2
}

# Mux files to MKV
${MKVMERGE} -q -o "${MKV}" --title "${TITLE}" --default-language ger "${TMP_VID}" "${TMP_AUD}.ogg" || {
	echo -e "\nError: Files could not be muxed to mkv. Check the printed erorrs"
	exit 2
}

# Delete tempfiles
rm "${TMP_VID}" "${TMP_AUD}" "${TMP_AUD}.ogg"

echo -e "\n------------------------------------------------------------------------"
echo "Created videofile \"${MKV}\"!"
echo "------------------------------------------------------------------------"
