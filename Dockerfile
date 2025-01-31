FROM ubuntu:20.04
RUN apt-get update -y
COPY . /app
WORKDIR /app
RUN set -xe \
    && apt-get update -y \
    && apt-get install -y python3-pip \
    && apt-get install -y mysql-client 
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
ENTRYPOINT [ "python3" ]
CMD [ "app.py" ]