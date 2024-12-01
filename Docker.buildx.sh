#! /bin/bash
# =============================================================================
# Authors:          Patrick Lehmann
#
# Entity:           STDOUT Post-Processor for Docker build
#
# License:
# =============================================================================
# Copyright 2017-2023 Patrick Lehmann - Boetzingen, Germany
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================

# work around for Darwin (Mac OS)
READLINK=readlink; if [[ $(uname) == "Darwin" ]]; then READLINK=greadlink; fi

# Save working directory
WorkingDir=$(pwd)
ScriptDir="$($READLINK -f $(dirname $0))"
RootDir="$($READLINK -f $ScriptDir/..)"

ANSI_ENABLE_COLOR() {
	ENABLECOLOR='-c '
	ANSI_BLACK="\e[30m"
	ANSI_RED="\e[31m"
	ANSI_GREEN="\e[32m"
	ANSI_YELLOW="\e[33m"
	ANSI_BLUE="\e[34m"
	ANSI_MAGENTA="\e[35m"
	ANSI_CYAN="\e[36m"
	ANSI_DARK_GRAY="\e[90m"
	ANSI_LIGHT_GRAY="\e[37m"
	ANSI_LIGHT_RED="\e[91m"
	ANSI_LIGHT_GREEN="\e[92m"
	ANSI_LIGHT_YELLOW="\e[93m"
	ANSI_LIGHT_BLUE="\e[94m"
	ANSI_LIGHT_MAGENTA="\e[95m"
	ANSI_LIGHT_CYAN="\e[96m"
	ANSI_WHITE="\e[97m"
	ANSI_NOCOLOR="\e[0m"

	# red texts
	COLORED_ERROR="${ANSI_RED}[ERROR]"
	COLORED_FAILED="${ANSI_RED}[FAILED]${ANSI_NOCOLOR}"

	# yellow texts
	COLORED_WARNING="${ANSI_YELLOW}[WARNING]"

	# green texts
	COLORED_PASSED="${ANSI_GREEN}[PASSED]${ANSI_NOCOLOR}"
	COLORED_DONE="${ANSI_GREEN}[DONE]${ANSI_NOCOLOR}"
	COLORED_SUCCESSFUL="${ANSI_GREEN}[SUCCESSFUL]${ANSI_NOCOLOR}"
}
ANSI_ENABLE_COLOR

# command line argument processing
COMMAND=2  # 0-help, 1-unknown option, 2-no arg needed
INDENT=""
VERBOSE=0; DEBUG=0
while [[ $# > 0 ]]; do
	key="$1"
	case $key in
		-i|--indent)
			shift
			INDENT=$1
			;;
#		-v|--verbose)
#			VERBOSE=1
#			;;
#		-d|--debug)
#			VERBOSE=1
#			DEBUG=1
#			;;
		-h|--help)
			COMMAND=0
			;;
		*)		# unknown option
			echo 1>&2 -e "${COLORED_ERROR} Unknown command line option '$key'.${ANSI_NOCOLOR}"
			COMMAND=1
			;;
	esac
	shift # past argument or value
done

if [ $COMMAND -le 1 ]; then
	echo ""
	echo "Synopsis:"
	echo "  Script to filter Docker 'buildx' outputs."
	echo ""
	echo "Usage:"
	echo "  Docker.buildx.sh [-v][-d] [--help] [--indent <pattern>]"
	echo ""
	echo "Common commands:"
	echo "  -h --help             Print this help page."
	echo ""
	echo "Common options:"
#	echo "  -v --verbose          Print verbose messages."
#	echo "  -d --debug            Print debug messages."
	echo "  -i --indent <pattern> Indent all lines by this pattern."
	echo ""
	exit $COMMAND
fi

# Counters
Counter_Error=0

Pattern_CACHED='#[0-9]+ CACHED'
Pattern_FROM='#[0-9]+ \[([-a-zA-Z0-9]+ )?[0-9]+/[0-9]+\] FROM'
Pattern_RUN='#[0-9]+ \[([-a-zA-Z0-9]+ )?[0-9]+/[0-9]+\] RUN'
Pattern_COPY='#[0-9]+ \[([-a-zA-Z0-9]+ )?[0-9]+/[0-9]+\] COPY'
Pattern_LABEL_ENV='#[0-9]+ \[([-a-zA-Z0-9]+ )?[0-9]+/[0-9]+\] (LABEL|ENV)'
Pattern_DONE='#[0-9]+ DONE [0-9]+\.[0-9]+s'
Pattern_ERROR='(#[0-9]+ )?ERROR:'
Pattern_CANCELED='#[0-9]+ CANCELED'
Pattern_Tagging='#[0-9]+ naming to (.*?) done'
Pattern_MIKTEX='#[0-9]+ [0-9]+\.[0-9]+ Installing package'
while IFS='\n' read -r line; do
	if [[ "${line}" =~ $Pattern_FROM ]]; then
		echo -e "${INDENT}${ANSI_MAGENTA}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_RUN ]]; then
		echo -e "${INDENT}${ANSI_CYAN}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_COPY ]]; then
		echo -e "${INDENT}${ANSI_LIGHT_CYAN}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_LABEL_ENV ]]; then
		echo -e "${INDENT}${ANSI_BLUE}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_DONE ]]; then
		echo -e "${INDENT}${ANSI_GREEN}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_ERROR ]]; then
		echo -e "${INDENT}${ANSI_LIGHT_RED}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_CANCELED ]]; then
		echo -e "${INDENT}${ANSI_LIGHT_RED}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_CACHED ]]; then
		echo -e "${INDENT}${ANSI_YELLOW}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_Tagging ]]; then
		ImageName=${BASH_REMATCH[1]}
		echo -e "${INDENT}${ANSI_LIGHT_GREEN}${line}${ANSI_NOCOLOR}"
	elif [[ "${line}" =~ $Pattern_MIKTEX ]]; then
		echo -e "${INDENT}${ANSI_LIGHT_BLUE}${line}${ANSI_NOCOLOR}"
	else
		echo -e "${INDENT}${ANSI_LIGHT_GRAY}${line}${ANSI_NOCOLOR}"
	fi
done < "/dev/stdin"

if [[ -n "${ImageName}" ]]; then
	echo ""
	echo "Image size of '${ImageName}' is $(docker image inspect ${ImageName} --format='{{.Size}}' | numfmt --to=iec)"
fi

exit $Counter_Error
