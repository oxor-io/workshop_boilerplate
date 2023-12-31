#!/bin/bash

# Stop execution if any step returns non-zero (non success) status
set -e

CIRCUIT_NAME=
INPUT_NAME=
CEREMONY=

while getopts "c:i:r:" opt; do
  case $opt in
    c)
      CIRCUIT_NAME=$(basename "$OPTARG" .circom)
      ;;
    i)
      INPUT_NAME=$(basename "$OPTARG" .json)
      ;;
    r)
      CEREMONY=$OPTARG
      ;;
    \?)
      exit 1
      ;;
  esac
done

BUILD_DIR=build
JS_FOLDER=${BUILD_DIR}/${CIRCUIT_NAME}_js
WITNESS=witness.wtns

POTS_DIR=pots # directory to keep PowersOfTau
POWERTAU=14 # power value for "powersOfTau"

PTAU_FILE=pot${POWERTAU}_0000.ptau
PTAU_PATH=${POTS_DIR}/${PTAU_FILE}

PROOF=${BUILD_DIR}/proof.json
PUBLIC=${BUILD_DIR}/public.json

CONTRIBUTED_PTAU_FILE=contributed_${PTAU_FILE}
FINAL_PTAU=pot${POWERTAU}_final.ptau

# Is circuit exist?
if [ ! -f circuits/${CIRCUIT_NAME}.circom ]; then
  echo "circuits/${CIRCUIT_NAME}.circom doesn't exist, exit..."
  exit 3
fi

if [ ! -f ${INPUT_NAME}.json ]; then
  echo "Input file: ${INPUT_NAME}.json is not exist"
  exit 4
fi

if [ -d "$BUILD_DIR" ]; then
  echo "$BUILD_DIR exists, deliting..."
  rm -rf ./$BUILD_DIR
fi

echo "Creating new $BUILD_DIR dir"
mkdir -p "$BUILD_DIR"

echo "Building R1CS for circuit ${CIRCUIT_NAME}.circom"
if ! circom circuits/${CIRCUIT_NAME}.circom --r1cs --wasm --sym -o $BUILD_DIR; then
  echo "circuits/${CIRCUIT_NAME}.circom compilation to r1cs failed. Exiting..."
  exit 5
fi

# echo "Info about circuits/${CIRCUIT_NAME}.circom R1CS constraints system"
# snarkjs info -c ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs

echo "Generate witness"
node ${JS_FOLDER}/generate_witness.js ${JS_FOLDER}/${CIRCUIT_NAME}.wasm ${INPUT_NAME}.json ${WITNESS}

# Move witness to build
mv ${WITNESS} ${BUILD_DIR}

if [ -d $POTS_DIR ] && [ -f $PTAU_PATH ]; then
  echo "No need to generate new POTS"
else
  echo "Generate new PTAU"
  mkdir -p ${POTS_DIR}
  snarkjs powersoftau new bn128 ${POWERTAU} ${PTAU_PATH}
fi

if [ -z $CEREMONY ]; then
  echo "Ceremony required, start..."
  snarkjs powersoftau contribute ${PTAU_PATH} ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} --name="First contribution"
  snarkjs powersoftau prepare phase2 ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} ${POTS_DIR}/${FINAL_PTAU}
fi

snarkjs groth16 setup ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs ${POTS_DIR}/${FINAL_PTAU} ${BUILD_DIR}/${CIRCUIT_NAME}_init.zkey
snarkjs zkey contribute ${BUILD_DIR}/${CIRCUIT_NAME}_init.zkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey --name="1st Contributor Name"
snarkjs zkey export verificationkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${BUILD_DIR}/verification_key.json

echo "Start proving"
snarkjs groth16 prove ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${BUILD_DIR}/${WITNESS} ${PROOF} ${PUBLIC}

echo "==============RESULT=============="
snarkjs groth16 verify ${BUILD_DIR}/verification_key.json ${PUBLIC} ${PROOF}