FROM ruby:3
WORKDIR /app
RUN apt-get update && apt-get install default-mysql-client -y
COPY . .
RUN bundle install