if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

# Download the schema
curl -o api.json http://localhost:24817/pulp/api/v3/docs/api.json?plugin=$1
# Get the version of the pulpcore or plugin as reported by status API

if [ ${3-x} ];
then
    export VERSION=$3
else
    export VERSION=$(http :24817/pulp/api/v3/status/ | jq --arg plugin $1 -r '.versions[] | select(.component == $plugin) | .version')
fi

if [ $2 = 'python' ]
then
    docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate \
        -i /local/api.json \
        -g python \
        -o /local/$1-client \
        -DpackageName=pulpcore.client.$1 \
        -DprojectName=$1-client \
        -DpackageVersion=${VERSION} \
        --skip-validate-spec \
        --strict-spec=false
    cp python/__init__.py $1-client/pulpcore/
    cp python/__init__.py $1-client/pulpcore/client
fi
if [ $2 = 'ruby' ]
then
    docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate \
        -i /local/api.json \
        -g ruby \
        -o /local/$1-client \
        -DgemName=$1_client \
        -DgemLicense="GPLv2" \
        -DgemVersion=${VERSION} \
        --skip-validate-spec \
        --strict-spec=false
fi

rm api.json
