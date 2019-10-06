#/bin/sh

cd `dirname $0`

# valiables
export ARTIFACT_NAME=oke-private-cluster

# clean up
rm -rf target

# build
mkdir target
cd src
zip --verbose \
    --recurse-paths \
    ../target/${ARTIFACT_NAME} * \
    --exclude=./terraform.tfstate* \
    --exclude=./terraform.tfvars* \
    --exclude=./provider.tf \
    --exclude=./variables-user-credentials.tf