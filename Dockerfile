FROM alpine:3.20
COPY w16.sh /w16.sh
RUN sh /w16.sh
CMD ["sleep","30"]
