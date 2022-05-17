FROM ubuntu:20.04 as eksctl
ENV AWS_REGION=us-east-2
RUN apt-get update && apt-get -y install curl dnsutils
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp; \
    mv /tmp/eksctl /usr/local/bin; \
    eksctl version
RUN curl -o aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator; \
    chmod 755 aws-iam-authenticator; \
    mv ./aws-iam-authenticator /usr/local/bin

FROM eksctl as gcloud
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
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-'; \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters get-credentials "cluster-nsm" && \
    eksctl utils write-kubeconfig --cluster cluster-istio && \
    /bin/bash

# docker run -it --env-file ./clusters.env -e AWS_ACCESS_KEY=${AWS_ACCESS_KEY} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e GCLOUD_SERVICE_KEY=${GCLOUD_SERVICE_KEY} $(docker build -q . --target createclusters )
FROM gcloud as createclusters
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-' && \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters create "cluster-nsm" --machine-type="n1-standard-2" --num-nodes="2"&& \
    gcloud container clusters get-credentials "cluster-nsm" && \
    eksctl create cluster  \
      --name cluster-istio \
      --version 1.22 \
      --nodegroup-name cluster-istio-workers \
      --node-type t2.xlarge \
      --nodes 2

# docker run -it --envfile ./clusters.env -e AWS_ACCESS_KEY=${AWS_ACCESS_KEY} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e GCLOUD_SERVICE_KEY=${GCLOUD_SERVICE_KEY} $(docker build -q . --target deleteclusters )
FROM gcloud as deleteclusters
CMD bash -c 'echo "${GCLOUD_SERVICE_KEY}"| gcloud auth activate-service-account --key-file=-' && \
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID} && \
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE} && \
    gcloud container clusters get-credentials "cluster-nsm" && \
    gcloud container clusters delete "cluster-nsm" && \
    eksctl delete cluster --name "cluster-istio"






