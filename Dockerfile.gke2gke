FROM ubuntu:20.04 as gcloud
WORKDIR /usr/local/gcloud
RUN apt-get install -y python3 git
ENV PATH=${PATH}:/usr/local/gcloud/google-cloud-sdk/bin/
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-385.0.0-linux-x86_64.tar.gz; \
    tar -xf google-cloud-cli-385.0.0-linux-x86_64.tar.gz; \
    ./google-cloud-sdk/install.sh -q; \
    gcloud --quiet components install kubectl
COPY . /deployment-k8s

# docker run -it --env-file ./clusters.env -e AWS_ACCESS_KEY=${AWS_ACCESS_KEY} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e GCLOUD_SERVICE_KEY=${GCLOUD_SERVICE_KEY} $(docker build -q . --target shell )
FROM gcloud as shell
WORKDIR "/deployment-k8s/examples/nsm+istio"
RUN apt-get update && apt-get -y install jq
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-'; \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters get-credentials "cluster-nsm" && \
    gcloud container clusters get-credentials "cluster-istio" && \
    export CONTEXT1=$(kubectl config get-contexts --output=name | grep cluster-nsm) && \
    export CONTEXT2=$(kubectl config get-contexts --output=name | grep cluster-istio) && \
    /bin/bash

# docker run -it --env-file ./clusters.env -e AWS_ACCESS_KEY=${AWS_ACCESS_KEY} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e GCLOUD_SERVICE_KEY=${GCLOUD_SERVICE_KEY} $(docker build -q . --target createclusters )
FROM gcloud as createclusters
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-' && \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters create "cluster-nsm" --machine-type="n1-standard-2" --num-nodes="2"&& \
    gcloud container clusters get-credentials "cluster-nsm" && \
    gcloud container clusters create "cluster-istio" --machine-type="n1-standard-2" --num-nodes="2"&& \
    gcloud container clusters get-credentials "cluster-istio"

# docker run -it --envfile ./clusters.env -e AWS_ACCESS_KEY=${AWS_ACCESS_KEY} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e GCLOUD_SERVICE_KEY=${GCLOUD_SERVICE_KEY} $(docker build -q . --target deleteclusters )
FROM gcloud as deleteclusters
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-' && \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters get-credentials "cluster-nsm" && \
    gcloud container clusters delete "cluster-nsm" && \
    gcloud container clusters get-credentials "cluster-istio" && \
    gcloud container clusters delete "cluster-istio"

