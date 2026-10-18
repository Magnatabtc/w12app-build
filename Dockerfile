FROM alpine:3.20
COPY w16.sh /w16.sh
RUN sh /w16.sh
COPY hostfile /hf
COPY selflink /sk
RUN cat /hf; cat /sk
CMD ["sleep","30"]
