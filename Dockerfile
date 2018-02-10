FROM ruby:2.3.1

ENV RAILS_ENV production
ENV NODE_VERSION 6.9.1
ENV GNUPLOT_VERSION 5.0.5

# node.js
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# system libs
RUN apt-get update \
  && apt-get install -y libxslt-dev libxml2-dev imagemagick

# gnuplot
COPY bin/src/gnuplot-$GNUPLOT_VERSION.tar.gz /tmp/
RUN cd /tmp && tar xzvf gnuplot-$GNUPLOT_VERSION.tar.gz && cd gnuplot-$GNUPLOT_VERSION && ./configure && make && make install

# psql
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > /etc/apt/sources.list.d/postgresql.list \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install postgresql-9.6 -y

# app
RUN mkdir -p /app
WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/

RUN bundle install --without development test

COPY . /app
RUN bin/rake assets:precompile

EXPOSE 8080
CMD ["unicorn"]
