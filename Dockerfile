FROM debian:12-slim
RUN apt update &&\
    apt install nmap -y
