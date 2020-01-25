#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PUSH="$1"

docker system prune

versions=(
    "ELK_VERSION=7.5.1 SG_VERSION=40.0.0 SG_KIBANA_VERSION=40.0.0"
)

######################################################################################

function push_docker {
    export DOCKER_ID_USER="zzvara"
    RET="1"

    while [ "$RET" -ne 0 ]; do
        echo "$DOCKER_HUB_PWD" | docker login --username "$DOCKER_ID_USER" --password-stdin
        echo "Pushing $1"
        docker push "$1" > /dev/null
        RET="$?"
        echo "Return code: $RET"
        echo ""

        if [ "$RET" -ne 0 ]; then
            sleep 15
        fi
    done
}

check_and_push() {
    local status=$?
    if [ $status -ne 0 ]; then
         echo "ERR - The command $1 failed with status $status"
         exit $status
    else
         push_docker "$1"
    fi
}

for versionstring in "${versions[@]}"
do
    : 
    eval "$versionstring"

    ELK_FLAVOUR="-oss"

    ELK_VERSION_NUMBER="${ELK_VERSION//./}"

    CACHE=""
    #CACHE="--no-cache"

    LASTCMDSEC="0"
    
    cd "$DIR/elasticsearch"
    echo "Build image zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    check_and_push "zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    LASTCMDSEC="$SECONDS"

    cd "$DIR/kibana"
    echo "Build image zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    check_and_push "zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    LASTCMDSEC="$SECONDS"

    ELK_FLAVOUR=""

    cd "$DIR/elasticsearch"
    echo "Build image zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    docker build -t "zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    check_and_push "zzvara/sg-elasticsearch:$ELK_VERSION$ELK_FLAVOUR-$SG_VERSION"
    LASTCMDSEC="$SECONDS"

    cd "$DIR/kibana"
    echo "Build image zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    docker build -t "zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg ELK_FLAVOUR="$ELK_FLAVOUR" --build-arg SG_KIBANA_VERSION="$SG_KIBANA_VERSION"  .
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    check_and_push "zzvara/sg-kibana:$ELK_VERSION$ELK_FLAVOUR-$SG_KIBANA_VERSION"
    LASTCMDSEC="$SECONDS"

    cd "$DIR/sgadmin"
    echo "Build image zzvara/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    docker build -t "zzvara/sg-sgadmin:$ELK_VERSION-$SG_VERSION" --pull $CACHE --build-arg ELK_VERSION="$ELK_VERSION" --build-arg SG_VERSION="$SG_VERSION" . > /dev/null
    echo "$(( SECONDS - LASTCMDSEC )) sec"
    echo ""
    check_and_push "zzvara/sg-sgadmin:$ELK_VERSION-$SG_VERSION"
    LASTCMDSEC="$SECONDS"
done

echo "Built "${#versions[@]}" versions"