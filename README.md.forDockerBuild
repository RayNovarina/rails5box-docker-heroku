
==================
$ docker-compose build shell > build-shell.txt

$ docker run -it mydockerizedapp_shell bash

$ docker-compose run web rails new . --force --database=postgresql --skip-bundle

======================


# Railsbox4-Make-Docker-Image: March 17, 2017

# Based on Docker Tutorial "Compose and Rails" at: https://docs.docker.com/compose/rails/

# NOTE: this Readme.md file will be overwritten in the Rails container build step
below. Make a backup copy first, if desired.

1) Before starting, you’ll need to have Docker Compose installed via instructions
at: https://docs.docker.com/compose/install/

2) log into projects root
  cd /Users/.../Projects

3) Git
  .../Projects $ git clone https://github.com/RayNovarina/Railsbox4.git

4) Scrub local Docker dev framework.
- List Only stopped containers:
  .../Railsbox4 $ docker ps --filter "status=exited"

- Delete Only stopped containers:
.../Railsbox4 $ docker rm $(docker ps --filter "status=exited" -aq)

- Delete every Docker containers
# Must be run first because images are attached to containers
.../Railsbox4 $ docker rm -f $(docker ps -a -q)

- Delete every Docker image
.../Railsbox4 $ docker rmi -f $(docker images -q)

5) Define the project
Start by setting up the four files you’ll need to build the app.

First, since your app is going to run inside a Docker container containing
all of its dependencies, you’ll need to define exactly what needs to be included
in the container. This is done using a file called Dockerfile.

.../Railsbox4/Dockerfile:
``
    FROM ruby:2.3.3
    RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
    RUN mkdir /myapp
    WORKDIR /myapp
    ADD Gemfile /myapp/Gemfile
    ADD Gemfile.lock /myapp/Gemfile.lock
    RUN gem install bundler -v 1.11.2
    RUN bundle _1.11.2_ install
    ADD . /myapp
``
NOTE: The bundle version number is explicity set else bundle fails during our
later step "docker-compose up" with:
  web_1  | bundler: failed to load command: rails (/usr/local/bundle/bin/rails)
  web_1  | Bundler::GemNotFound: Could not find gem 'pg' in any of the gem sources listed in your Gemfile.

Soooo..... per https://discuss.circleci.com/t/bundler-fails-to-find-appropriate-version-despite-installing-appropriate-version-earlier-in-the-build/280
and
https://makandracards.com/makandra/9741-run-specific-version-of-bundler
use an old/different bundle version.

That’ll put your application code inside an image that will build a container
with Ruby, Bundler and all your dependencies inside it. For more information on
how to write Dockerfiles, see the Docker user guide and the Dockerfile reference.

6) Next, create a bootstrap Gemfile which just loads Rails. It’ll be overwritten
in a moment by rails new.
.../railsbox4/Gemfile:
``
    source 'https://rubygems.org'
    gem 'rails', '5.0.0.1'
``
You’ll need an empty Gemfile.lock in order to build our Dockerfile.
.../railsbox4/Gemfile.lock:
``

``

7) Finally, docker-compose.yml is where the magic happens. This file describes
the services that comprise your app (a database and a web app), how to get each
one’s Docker image (the database just runs on a pre-made PostgreSQL image, and
the web app is built from the current directory), and the configuration needed
to link them together and expose the web app’s port.

NOTE: The bundle version number is explicity set else bundle fails later.
.../railsbox4/docker-compose.yml:
``
    version: '2'
    services:
      db:
        image: postgres
      web:
        build: .
        command: bundle _1.11.2_ exec rails s -p 3000 -b '0.0.0.0'
        volumes:
          - .:/myapp
        ports:
          - "3000:3000"
        depends_on:
          - db
``

8) Build the project

With those four files in place, you can now generate the Rails skeleton app
using docker-compose run:

  $ docker-compose run web rails new . --force --database=postgresql --skip-bundle

    Creating network "railsbox4makedockerimage_default" with the default driver
    Pulling db (postgres:latest)...
    Creating railsbox4makedockerimage_db_1
    Building web
    Step 1/9 : FROM ruby:2.3.3
    2.3.3: Pulling from library/ruby
      .........
    Step 7/9 : RUN gem install bundler -v 1.11.2
     ---> Running in 932bb23998d1
    Successfully installed bundler-1.11.2
    1 gem installed
     ---> 2affe471cf3e
     ---> Running in a1424ada0238
    Fetching gem metadata from https://rubygems.org/...........
    Fetching version metadata from https://rubygems.org/...
    Fetching dependency metadata from https://rubygems.org/..
    Resolving dependencies...
    Installing rake 12.0.0
      .......
    Step 9/9 : ADD . /myapp
     ---> f8d9ca0a2ad9
    Removing intermediate container e9ff4f256e35
    Successfully built f8d9ca0a2ad9
    WARNING: Image for service web was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-
    compose up --build`.
          exist
          force  README.md
          create  Rakefile
             ......
          remove  config/initializers/cors.rb

First, Compose will build postgres image? and then the image for the web service
using the Dockerfile. Then it’ll run rails new inside a new container, using
that image. Once it’s done, you should have generated a fresh app and have
PostgreSQL running in its own container.

9) See what we ended up with:

  .../railsbox4/$ ls -l
    total 56
    -rw-r--r--   1 user  staff   215 Feb 13 23:33 Dockerfile
    -rw-r--r--   1 user  staff  1480 Feb 13 23:43 Gemfile
       .....
    drwxr-xr-x   3 root  root   102 Feb 13 23:43 tmp
    drwxr-xr-x   3 root  root   102 Feb 13 23:43 vendor

  .../railsbox4/$ docker images
    REPOSITORY                     TAG           IMAGE ID            SIZE
    railsbox4makedockerimage_web   latest        f8d9ca0a2ad9        812 MB
    ruby                           2.3.3         b03eadf54a64        733 MB
    postgres                       latest        4e18b2c30f8d        266 MB

  .../railsbox4/$ docker ps
    CONTAINER ID        IMAGE               COMMAND                  PORTS               NAMES
    35fdb63329d7        postgres            "docker-entrypoint..."   5432/tcp            railsbox4makedockerimage_db_1

10) Looking around in the postgresql container:

  .../railsbox4/$ $ docker exec -it 35f bash
  root@35fdb63329d7:/# pwd
  /
  root@35fdb63329d7:/# ls
  bin   dev                         docker-entrypoint.sh  home  lib64  mnt  proc  run   srv  tmp var
     ......
  root@35fdb63329d7:/# ls /etc
  adduser.conf            debian_version   hosts           locale.alias    modprobe.d         ppp     rmt          subgid-
     ......
  dbus-1                  host.conf        ld.so.conf.d    mime.types      postgresql         rcS.d   staff-group-for-usr-local
  debconf.conf            hostname         libaudit.conf   mke2fs.conf     postgresql-common  resolv.conf  subgid

  root@35fdb63329d7:/# ls /etc/postgresql
  root@35fdb63329d7:/# ls /etc/postgresql-common
  createcluster.conf  pg_upgradecluster.d  root.crt  supported_versions  user_clusters

  root@35fdb63329d7:/# exit

11) And in the web image:
$ docker run -it railsbox4makedockerimage_web bash
root@8c9f33087692:/myapp# pwd
/myapp
root@8c9f33087692:/myapp# ls
Dockerfile  Gemfile  Gemfile.lock  README.md  docker-compose.yml
root@8c9f33087692:/myapp# exit

12) Cleanup:
Stop the running postgres container:
  .../railsbox4/$ docker stop 35fdb
  35fdb
