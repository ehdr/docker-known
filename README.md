docker-known
============

Run the [Known][1] social publishing platform in a [Docker][2] container!

This unofficial image uses the 0.6.4 ("Dunham") release of Known, and has been
designed to run one process per container, i.e.:

- one container used as [data volume][3] for settings, posts, etc.
- MySQL database running in one container (based on the [standard MySQL image][4])
- Apache running the Known PHP application in a container based on this image

**Note:** This Docker image has known (and most likely also unknown) problems
(see the [known issues][7]). If you want to deploy Known publicly, you should have
a look at the [official installation instructions][8]. And of course, please help
[report issues][7] as you find them!

How to run it
-------------
You can run it [the easy way](#how-to-run-it-using-fig) or the hard(er) way.
Let's start with the hard(er) way.

### First, create a data volume container
The data volume container will contain the MySQL database files and the Known
uploads directory (for uploaded photos, etc.):

    docker run --name datavolume \
        -v /var/lib/mysql \
        -v /known/uploads \
        -d ubuntu:trusty true

### Second, start the MySQL database server
Here you need to decide on passwords for the MySQL root user and for the MySQL
user account for the Known app:

    docker run --name mysql --volumes-from datavolume \
        -e MYSQL_DATABASE=known \
        -e MYSQL_USER=known \
        -e MYSQL_PASSWORD=knownpassword \
        -e MYSQL_ROOT_PASSWORD=rootpassword \
        -d mysql

### Third, start the actual Known app
Again, you need to pass in the MySQL information you decided on in the
previous step:

    docker run --name known --volumes-from datavolume --link mysql:mysql -p 80:80 \
        -e MYSQL_DATABASE=known \
        -e MYSQL_USER=known \
        -e MYSQL_PASSWORD=knownpassword \
        -d ehdr/known

Notes:

- the `--link` alias for the MySQL container (the part after the '`:`') must be
  exactly `mysql`
- the current version of Known (0.6.4) only supports running on port 80

How to run it using Fig
-----------------------
[Fig][6] offers a convenient way to start all the containers automatically.
Once you have Fig installed, just put something like the following in
a `fig.yml` file and run `fig up` (but promise to pick good passwords
first!):

    datavolume:
      image: ubuntu:trusty
      volumes:
        - /var/lib/mysql
        - /known/uploads
    
    mysql:
      image: mysql
      volumes_from:
        - datavolume
      environment:
        - MYSQL_DATABASE=known
        - MYSQL_USER=known
        - MYSQL_PASSWORD=knownpassword
        - MYSQL_ROOT_PASSWORD=rootpassword
    
    known:
      image: ehdr/known
      volumes_from:
        - datavolume
      environment:
        - MYSQL_DATABASE=known
        - MYSQL_USER=known
        - MYSQL_PASSWORD=knownpassword
      ports:
        - "80:80"
      links:
        - "mysql:mysql"

Finally, set up Known!
----------------------
Enter the Known site address into your browser, and follow the instructions.

If you are running docker locally on your machine, you should be able to
access it at `http://localhost/`.  If you are running [boot2docker][5], you
instead need to enter the local IP of your boot2docker virtual machine, which
you can find by running

    boot2docker ip

How to build it
---------------
To build the image locally, simply

    docker build -t ehdr/known .


[1]: https://withknown.com/
[2]: https://www.docker.com/
[3]: http://docs.docker.com/userguide/dockervolumes/
[4]: https://github.com/docker-library/mysql
[5]: http://boot2docker.io/
[6]: http://www.fig.sh/
[7]: https://github.com/ehdr/docker-known/issues
[8]: http://docs.withknown.com/en/latest/install/index.html
