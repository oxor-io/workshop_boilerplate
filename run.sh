#!/bin/bash

# Stop execution if any step returns non-zero (non success) status
set -e

if [ ! $1 ]; then
    echo "You should pass <name> of the existing <name>.circom template to run. Example: ./run.sh multiplier2"
    exit 1
fi
CIRCUIT_NAME=$1

if [ ! $2 ]; then
    echo "Please pass the input file as second arg"
    exit 1
fi
INPUT_NAME=$2

BUILD_DIR=build
if [ -d "$BUILD_DIR" ]; then
  echo "$BUILD_DIR exists, deliting..."
  rm -rf ./$BUILD_DIR
fi

echo "Creating new \"$BUILD_DIR\" dir"
mkdir "$BUILD_DIR"

if [ ! -f circuits/${CIRCUIT_NAME}.circom ]; then
    echo "circuits/${CIRCUIT_NAME}.circom template doesn't exist, exit..."
    exit 2
fi

echo "Building R1CS for circuit ${CIRCUIT_NAME}.circom"
if ! circom circuits/${CIRCUIT_NAME}.circom --r1cs --wasm --sym --output "$BUILD_DIR"; then
    echo "circuits/${CIRCUIT_NAME}.circom compilation to r1cs failed. Exiting..."
    exit 3
fi

# echo "Info about circuits/${CIRCUIT_NAME}.circom R1CS constraints system"
# snarkjs info -c ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs

echo "Generate witness"
JS_FOLDER=${BUILD_DIR}/${CIRCUIT_NAME}_js
WITNESS=witness.wtns
node ${JS_FOLDER}/generate_witness.js ${JS_FOLDER}/${CIRCUIT_NAME}.wasm ${INPUT_NAME} ${WITNESS}

echo "Move witness to build"
mv ${WITNESS} ${BUILD_DIR}

# directory to keep PowersOfTau, zkeys, and other non-circuit-dependent files
POTS_DIR=pots
# power value for "powersOfTau" pre-generated setup files
POWERTAU=10

PTAU_FILE=pot${POWERTAU}_0000.ptau
PTAU_PATH=${POTS_DIR}/${PTAU_FILE}

if [ -d "$POTS_DIR" ]; then
  echo "$POTS_DIR exists, no need to generate new..."
  else
    mkdir ${POTS_DIR}
    snarkjs powersoftau new bn128 ${POWERTAU} ${PTAU_PATH} -v
fi

CONTRIBUTED_PTAU_FILE=contributed_${PTAU_FILE}
snarkjs powersoftau contribute ${PTAU_PATH} ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} --name="First contribution" -v

FINAL_PTAU=pot${POWERTAU}_final.ptau
snarkjs powersoftau prepare phase2 ${POTS_DIR}/${CONTRIBUTED_PTAU_FILE} ${POTS_DIR}/${FINAL_PTAU} -v

snarkjs groth16 setup ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs ${POTS_DIR}/${FINAL_PTAU} ${BUILD_DIR}/${CIRCUIT_NAME}_init.zkey
snarkjs zkey contribute ${BUILD_DIR}/${CIRCUIT_NAME}_init.zkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey --name="1st Contributor Name" -v
snarkjs zkey export verificationkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${BUILD_DIR}/verification_key.json

PROOF=${BUILD_DIR}/proof.json
PUBLIC=${BUILD_DIR}/public.json
snarkjs groth16 prove ${BUILD_DIR}/${CIRCUIT_NAME}.zkey ${BUILD_DIR}/${WITNESS} ${PROOF} ${PUBLIC}

echo "==============RESULT=============="
snarkjs groth16 verify ${BUILD_DIR}/verification_key.json ${PUBLIC} ${PROOF}