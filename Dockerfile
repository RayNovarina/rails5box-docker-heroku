# Modified version of: https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose
# and https://github.com/philou/planning-poker.git

#-------------------------------------------------------------------------------
# Docker images can start off with nothing, but it's extremely
# common to pull in from a base image. In our case we're pulling
# in from the slim version of the official Ruby 2.4 image.
#
# Details about this image can be found here:
# https://hub.docker.com/_/ruby/
#
# Slim is pulling in from the official Debian Jessie image.
#
# You can tell it's using Debian Jessie by clicking the
# Dockerfile link next to the 2.4-slim bullet on the Docker hub.
#
# The Docker hub is the standard place for you to find official
# Docker images. Think of it like GitHub but for Docker images.

FROM ruby:2.4.0-slim

# It is good practice to set a maintainer for all of your Docker
# images. It's not necessary but it's a good habit.
MAINTAINER Ray Novarina <RNova94037@gmail.com>

#-------------------------------------------------------------------------------
# Install essential Linux packages:
# Ensure that our apt package list is updated and install a few
# packages to ensure that we can compile assets (nodejs) and
# communicate with PostgreSQL (libpq-dev).

# Fix for: "Getting tons of debconf messages unless TERM is set to linux"
# per: https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get update && \
  apt-get install -y apt-utils && \
  apt-get upgrade -y && \
  apt-get install -y build-essential nodejs libpq-dev postgresql-client libsqlite3-dev && \
  apt-get install -y vim curl wget lsof
ENV DEBIAN_FRONTEND teletype

#-------------------------------------------------------------------------------
# The name of the application is my_dockerized_app and while there
# is no standard on where your project should live inside of the Docker
# image, I like to put it in the root of the image and name it
# after the project.
#
# We don't even need to set the INSTALL_PATH variable, but I like
# to do it because we're going to be referencing it in a few spots
# later on in the Dockerfile.
#
# The variable could be named anything you want.
ENV INSTALL_PATH /my_dockerized_app

# Define where our application will live inside the image
ENV RAILS_ROOT /my_dockerized_app

# This just creates the folder in the Docker image at the
# install path we defined above. This is the base directory used in any
# further RUN, COPY, and ENTRYPOINT commands.
RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH
# We're going to be executing a number of commands below, and
# having to CD into the /my_dockerized_app folder every time would be
# lame, so instead we can set the WORKDIR to be /my_dockerized_app.
#
# By doing this, Docker will be smart enough to execute all
# future commands from within this directory.

#-------------------------------------------------------------------------------
# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.

# This is going to copy in the Gemfile and Gemfile.lock from our
# work station at a path relative to the Dockerfile to the
# my_dockerized_app/ path inside of the Docker image.
#
# It copies it to /my_dockerized_app because of the WORKDIR being set.
#
# We copy in our Gemfile before the main app because Docker is
# smart enough to cache "layers" when you build a Docker image.
#
# You see, each command we have in the Dockerfile is going to be
# ran and then saved as a separate layer. Docker is smart enough
# to only re-build pieces that change, in order from top to bottom.
#
# This is an advanced concept but it means that we'll be able to
# cache all of our gems so that if we make an application code
# change, it won't re-run bundle install unless a gem changed.
#
# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
COPY Gemfile.forDockerBuild Gemfile
COPY Gemfile.lock.forDockerBuild Gemfile.lock
COPY Rakefile.forDockerBuild Rakefile

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler

# Finish establishing our Ruby environment
RUN bundle install --jobs 20 --retry 5

#-------------------------------------------------------------------------------
# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

ADD . /my_dockerized_app

# This might look a bit alien but it's copying in everything from
# the current directory relative to the Dockerfile, over to the
# /my_dockerized_app folder inside of the Docker image.
#
# We can get away with using the . for the second argument because
# this is how the unix command cp (copy) works. It stands for the
# current directory.
COPY . .

#-------------------------------------------------------------------------------
# Expose port 3000 to the Docker host, so we can access it
# from the outside.
# Note: will be ignored by Heroku upon deploy.
EXPOSE 3000

#-------------------------------------------------------------------------------
# Configure an entry point, so we don't need to specify
# "bundle exec" for each of our commands. You can now run commands without
# specifying "bundle exec" on the console. If you need to, you can override the
# entrypoint as well.
#     docker run -it demo "rake test"
#     docker run -it --entrypoint="" demo "ls -la"
ENTRYPOINT ["bundle", "exec"]

# This is the command that's going to be run by default if you run the
# Docker container without any arguments. Use the "exec" form of CMD so our
# script shuts down gracefully on SIGTERM (i.e. `docker stop`)

# Tell the Rails dev server to bind to all interfaces by default.
# In our case, it will start the default Rails server and port. (Puma: localhost:3000)
CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]

# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]


#===============================================================================
# Variant per: https://github.com/philou/planning-poker
# FROM ruby:2.3.3
# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
# RUN mkdir /myapp
# WORKDIR /myapp
# ADD Gemfile /myapp/Gemfile
# ADD Gemfile.lock /myapp/Gemfile.lock
# RUN gem install bundler
# RUN bundle install
# ADD . /myapp
# CMD rails s -p 3000 -b '0.0.0.0'

#===============================================================================
# Variant per: https://github.com/philou/planning-poker
# # Base our image on an official, minimal image of our preferred Ruby
# # Repeated in Gemfile
# # FROM ruby:2.4.0-slim
#
# # Install essential Linux packages
# RUN \
#   apt-get update && \
#   apt-get upgrade -y && \
#   apt-get install -y build-essential libpq-dev postgresql-client libsqlite3-dev && \
#   apt-get install -y wget libfreetype6 libfontconfig bzip2
#
#
# # Install phanton js (https://hub.docker.com/r/cmfatih/phantomjs/~/dockerfile/, https://gist.github.com/jakemauer/99227bc5f7c0fef375f2, https://gist.github.com/julionc/7476620)
# ENV PHANTOMJS_VERSION 2.1.1
# RUN \
#   wget -q --no-check-certificate -O /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
#   tar -xjf /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 -C /tmp && \
#   rm -f /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
#   mv /tmp/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/ /usr/local/share/phantomjs && \
#   ln -s /usr/local/share/phantomjs/bin/phantomjs /usr/local/bin/phantomjs
#
# # Define where our application will live inside the image
# ENV RAILS_ROOT /var/www/planning-poker
#
# # Create application home. App server will need the pids dir so just create everything in one shot
# RUN mkdir -p $RAILS_ROOT/tmp/pids
#
# # Set our working directory inside the image
# WORKDIR $RAILS_ROOT
#
# # Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# # (the src likely changed and we don't want to invalidate Docker's cache too early)
# # http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
# COPY Gemfile Gemfile
#
# COPY Gemfile.lock Gemfile.lock
#
# # Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
# RUN gem install bundler
#
# # Finish establishing our Ruby enviornment
# RUN bundle install
#
# # Copy the Rails application into place
# COPY . .
#
# # Define the script we want run once the container boots
# # Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]

#===============================================================================
# Variant per: https://blog.codeship.com/running-rails-development-environment-docker/
#FROM ruby:2.2
#MAINTAINER marko@codeship.com
#
## Install apt based dependencies required to run Rails as
## well as RubyGems. As the Ruby image itself is based on a
## Debian image, we use apt-get to install those.
#RUN apt-get update && apt-get install -y \
#  build-essential \
#  nodejs
#
## Configure the main working directory. This is the base
## directory used in any further RUN, COPY, and ENTRYPOINT
## commands.
#RUN mkdir -p /app
#WORKDIR /app
#
## Copy the Gemfile as well as the Gemfile.lock and install
## the RubyGems. This is a separate step so the dependencies
## will be cached unless changes to one of those two files
## are made.
#COPY Gemfile Gemfile.lock ./
#RUN gem install bundler && bundle install --jobs 20 --retry 5
#
## Copy the main application.
#COPY . ./
#
## Expose port 3000 to the Docker host, so we can access it
## from the outside.
#EXPOSE 3000
#
## Configure an entry point, so we don't need to specify
## "bundle exec" for each of our commands. You can now run commands without
## specifying "bundle exec" on the console. If you need to, you can override the
## entrypoint as well.
##     docker run -it demo "rake test"
##     docker run -it --entrypoint="" demo "ls -la"
##ENTRYPOINT ["bundle", "exec"]
#
## The main command to run when the container starts. Also
## tell the Rails dev server to bind to all interfaces by
## default.
#CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

#-------------------------------------------------------------------------------
# Variant per: https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose
## Provide a dummy DATABASE_URL and more to Rails so it can pre-compile
## assets. The values do not need to be real, just valid syntax.
##
## If you're saving your assets to a CDN and are working with multiple
## app instances, you may want to remove this step and deal with asset
## compilation at a different stage of your deployment.
#RUN bundle exec rake RAILS_ENV=production DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=foo,bar SECRET_TOKEN=dummytoken assets:precompile
#
## In production you will very likely reverse proxy Rails with nginx.
## This sets up a volume so that nginx can read in the assets from
## the Rails Docker image without having to copy them to the Docker host.
#VOLUME ["$INSTALL_PATH/public"]
#VOLUME ["$INSTALL_PATH/"]
