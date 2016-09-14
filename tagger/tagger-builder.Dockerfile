FROM golang:1.6
RUN apt-get update && apt-get install -y -q --no-install-depends libgit2-dev
#COPY tagger /go/src/tagger
COPY install-glide.sh /install-glide.sh
RUN /install-glide.sh

