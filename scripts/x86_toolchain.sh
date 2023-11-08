# This bash script is a toolchain for compiling and running assembly programs on x86 or x86-64 systems. It supports various options to control the compilation and execution process, and it uses the NASM assembler and the ld linker to compile the assembly code. The script can run the executable in the QEMU emulator or the GDB debugger, depending on the provided options.

#! /bin/bash

# This line specifies the interpreter to use, in this case, it's set to use the Bash shell.

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022

# This condition checks if the number of command-line arguments (specified using $#) is less than 1. If there are not enough arguments, it proceeds to display usage information and exits the script.

if [ $# -lt 1 ]; then
	echo "Usage:"
	echo ""
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-64| --x86-64                 Compile for 64bit (x86-64) system."
	echo "-o | --output <filename>      Output filename."

	exit 1
fi

# This part of the code processes command-line arguments using a while loop and a case statement to set various flags and values based on the provided options.

POSITIONAL_ARGS=() # An array to store non-option arguments (e.g., the assembly filename).
GDB=False # A flag to indicate whether to run the GDB debugger or not.
OUTPUT_FILE="" # A variable to store the output file name.
VERBOSE=False # A flag to indicate whether to show verbose output or not.
BITS=False # A flag to indicate whether to compile for 64-bit or 32-bit architecture.
QEMU=False # A flag to indicate whether to run the QEMU emulator or not.
BREAK="_start" # A variable to store the breakpoint for the GDB debugger.
RUN=False # A flag to indicate whether to run the program in the GDB debugger automatically or not.
while [[ $# -gt 0 ]]; do # A loop to iterate over the command-line arguments.
	case $1 in # A case statement to match the argument with the corresponding option.
		-g|--gdb) # If the argument is -g or --gdb, set the GDB flag to True.
			GDB=True
			shift # past argument
			;;
		-o|--output) # If the argument is -o or --output, set the output file name to the next argument.
			OUTPUT_FILE="$2"
			shift # past argument
			shift # past value
			;;
		-v|--verbose) # If the argument is -v or --verbose, set the verbose flag to True.
			VERBOSE=True
			shift # past argument
			;;
		-64|--x84-64) # If the argument is -64 or --x84-64, set the BITS flag to True.
			BITS=True
			shift # past argument
			;;
		-q|--qemu) # If the argument is -q or --qemu, set the QEMU flag to True.
			QEMU=True
			shift # past argument
			;;
		-r|--run) # If the argument is -r or --run, set the RUN flag to True.
			RUN=True
			shift # past argument
			;;
		-b|--break) # If the argument is -b or --break, set the breakpoint to the next argument.
			BREAK="$2"
			shift # past argument
			shift # past value
			;;
		-*|--*) # If the argument is any other option, display an error message and exit.
			echo "Unknown option $1"
			exit 1
			;;
		*) # If the argument is not an option, add it to the positional arguments array.
			POSITIONAL_ARGS+=("$1") # save positional arg
			shift # past argument
			;;
	esac
done

# This line restores the positional parameters from the array.

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# This condition checks if the specified assembly file exists. If not, it displays an error message and exits.

if [[ ! -f $1 ]]; then
	echo "Specified file does not exist"
	exit 1
fi

# This condition checks if the output file name is not provided. If not, it is derived from the assembly file name by removing the extension.

if [ "$OUTPUT_FILE" == "" ]; then
	OUTPUT_FILE=${1%.*}
fi

# This condition checks if the verbose flag is set. If yes, it provides information about the script's progress.

if [ "$VERBOSE" == "True" ]; then
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi

# This condition checks if the BITS flag is set. If yes, it assembles the provided assembly file using NASM for 64-bit architecture. If no, it assembles the file for 32-bit architecture.

if [ "$BITS" == "True" ]; then

	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then

	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

# This condition checks if the verbose flag is set. If yes, it prints a message indicating that the assembly is finished and the linking is started.

if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
	
fi

# This condition checks if the BITS flag is set. If yes, it links the assembly output file to create an executable for 64-bit architecture. If no, it links the file for 32-bit architecture.

if [ "$BITS" == "True" ]; then

	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then

	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi

# This condition checks if the verbose flag is set. If yes, it prints a message indicating that the linking is finished.

if [ "$VERBOSE" == "True" ]; then

	echo "Linking finished"

fi

# This condition checks if the QEMU flag is set. If yes, it runs the executable in the QEMU emulator. The choice of QEMU command depends on the BITS flag. It then exits the script.

if [ "$QEMU" == "True" ]; then

	echo "Starting QEMU ..."
	echo ""

	if [ "$BITS" == "True" ]; then
	
		qemu-x86_64 $OUTPUT_FILE && echo ""

	elif [ "$BITS" == "False" ]; then

		qemu-i386 $OUTPUT_FILE && echo ""

	fi

	exit 0
	
fi

# This condition checks if the GDB flag is set. If yes, it sets up GDB parameters, such as breakpoints and program execution, and then starts the GDB debugger with the executable.

if [ "$GDB" == "True" ]; then

	gdb_params=()
	gdb_params+=(-ex "b ${BREAK}")

	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")

	fi

	gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
