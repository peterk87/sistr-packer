cat << EOF
OH FUCK YES
  _________.___  ______________________________  
 /   _____/|   |/   _____/\__    ___/\______   \ 
 \_____  \ |   |\_____  \   |    |    |       _/ 
 /        \|   |/        \  |    |    |    |   \ 
/_______  /|___/_______  /  |____|    |____|_  / 
        \/             \/                    \/  

Main SISTR VM build script for CentOS 7

================================================================================
Install EPEL, development tools and deps for SISTR
================================================================================
EOF

yum -y install epel-release
yum groupinstall -y development
yum -y install sudo gcc gcc-gfortran python-pip python-devel python-virtualenv nginx atlas-devel blas-devel atlas blas lapack-devel lapack wget


cat << EOF

================================================================================
Install PostgreSQL 9.5
================================================================================
EOF
yum -y install http://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm
yum -y groupinstall "PostgreSQL Database Server 9.5 PGDG"
# following needed for psycopg2
yum -y install postgresql95-devel
ln -s /usr/pgsql-9.5/bin/pg_config /usr/bin/pg_config

/usr/pgsql-9.5/bin/postgresql95-setup initdb
systemctl enable postgresql-9.5.service
systemctl start postgresql-9.5.service

cat << EOF
--------------------------------------------------------------------------------
Edit pg_hba.conf at /var/lib/pgsql/9.5/data/pg_hba.conf
"trust" needed for all localhost connections
--------------------------------------------------------------------------------
  Replace METHOD with 'trust'
    TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
    host    all         all         127.0.0.1/32         ident->trust
EOF
sed -ri 's/^(host\s+all\s+all\s+\S+\s+)\w+$/\1trust/g' /var/lib/pgsql/9.5/data/pg_hba.conf
# local   all         all                              trust
sed -ri 's/^(local\s+all\s+all\s+)\w+$/\1trust/g' /var/lib/pgsql/9.5/data/pg_hba.conf

grep host /var/lib/pgsql/9.5/data/pg_hba.conf
grep local /var/lib/pgsql/9.5/data/pg_hba.conf

cat << EOF
--------------------------------------------------------------------------------
Restart PostgreSQL to load changes from pg_hba.conf
--------------------------------------------------------------------------------
EOF
systemctl restart postgresql-9.5.service


cat << EOF

================================================================================
Install, enable and start Redis
================================================================================
EOF
yum -y install redis
systemctl enable redis.service
systemctl start redis.service


cat << EOF

--------------------------------------------------------------------------------
================================================================================
SISTR SETUP
================================================================================
--------------------------------------------------------------------------------
EOF

mkdir -p /home/sistr/sistr_backend

cd /home/sistr
if ! [ $(pwd) == "/home/sistr" ] ; then
  echo "COULD NOT CD TO SISTR HOME"
  exit 1
fi


cat << EOF
================================================================================
Write sistr_db init script
================================================================================
EOF

cat > /home/sistr/sistr_db-init.sql <<EOF
CREATE USER sistr WITH PASSWORD 'sistr_password';
CREATE DATABASE sistr_db;
GRANT ALL PRIVILEGES ON DATABASE "sistr_db" to sistr;
CREATE DATABASE sistr_test_db;
GRANT ALL PRIVILEGES ON DATABASE "sistr_test_db" to sistr;
\c sistr_db
CREATE EXTENSION hstore;
\c sistr_test_db
CREATE EXTENSION hstore;
EOF


cat << EOF

================================================================================
Initialize sistr_db and sistr PostgreSQL user
================================================================================
EOF
sudo -u postgres psql -f /home/sistr/sistr_db-init.sql


cat << EOF

================================================================================
Download latest sistr_db dump
================================================================================
EOF

# TODO: Use version of DB dump that matches sistr_backend release version
curl -O https://lfz.corefacility.ca/sistr-db-dumps/sistr_db-4330_public-2016_01_12.sql.gz


cat << EOF

================================================================================
Load public sistr_db dump
================================================================================
EOF

gunzip -c sistr_db-4330_public-2016_01_12.sql.gz | sudo -u postgres psql sistr_db


cat << EOF

================================================================================
Install NCBI BLAST+
================================================================================
EOF

# curl -O ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.4.0/ncbi-blast-2.4.0+-2.x86_64.rpm
curl -O https://lfz.corefacility.ca/sistr-db-dumps/ncbi-blast-2.4.0+-2.x86_64.rpm
yum -y --nogpgcheck localinstall ncbi-blast-2.4.0+-2.x86_64.rpm
rm ncbi-blast-2.4.0+-2.x86_64.rpm


cat << EOF

================================================================================
Install Mash
================================================================================
EOF

# wget https://github.com/marbl/Mash/releases/download/v1.1/mash-Linux64-v1.1.tar.gz
curl -O https://lfz.corefacility.ca/sistr-db-dumps/mash.tgz
tar xzf mash.tgz --strip-components=1
cp mash /usr/bin/mash


cat << EOF

================================================================================
Install Mono for CentOS 7 for running MIST
================================================================================
EOF

yum -y install yum-utils
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
yum -y update
yum -y install mono-complete


cat << EOF

================================================================================
Install download QUAST 2.3 (later versions run some long running tasks; only want simple metrics)
================================================================================
EOF

# curl -L http://downloads.sourceforge.net/project/quast/quast-2.3.tar.gz > quast.tgz
curl -O https://lfz.corefacility.ca/sistr-db-dumps/quast.tgz
tar xzf quast.tgz


cat << EOF

================================================================================
Download sistr_backend repo
================================================================================
EOF

# wget https://bitbucket.org/peterk87/sistr_backend/get/master.tar.gz -O sistr_backend.tgz
curl -O https://lfz.corefacility.ca/sistr-db-dumps/sistr_backend.tgz
echo "Extract sistr_backend.tgz straight into sistr_backend directory"
tar -xzf sistr_backend.tgz -C /home/sistr/sistr_backend/ --strip-components=1
echo "Create SISTR log directory"
mkdir -p /home/sistr/sistr_backend/tmp
cd /home/sistr/sistr_backend

echo "Create sistr-config.py from sistr-config-TEMPLATE.py"
cp sistr-config-TEMPLATE.py sistr-config.py

echo "Update sistr-config.py"
sed -i 's/QUAST_BIN_PATH = .*/QUAST_BIN_PATH = "\/home\/sistr\/quast-2.3\/quast.py"/' /home/sistr/sistr_backend/sistr-config.py
sed -i 's/MASH_BIN_PATH = .*/MASH_BIN_PATH = "\/usr\/bin\/mash"/' /home/sistr/sistr_backend/sistr-config.py

echo "Update Supervisord.conf; ensure 0.0.0.0 instead of localhost"
sed -ri 's/^(.+gunicorn.+--bind)\s(\S+):\w+/\1 0.0.0.0:8000/' /home/sistr/sistr_backend/supervisord.conf


cat << EOF

================================================================================
Download sistr_backend repo
================================================================================
EOF

cd /home/sistr
mkdir -P /home/sistr/sistr-app
wget https://bitbucket.org/peterk87/sistr-app/get/master.tar.gz -O sistr-app.tgz
tar -xzf sistr-app.tgz -C /home/sistr/sistr-app/ --strip-components=1
sed -i 's@https://lfz.corefacility.ca/sistr-wtf/api/@http://localhost:44448/api/@g' /home/sistr/sistr-app/resources/public/js/compiled/sistr_app.js
ln -s /home/sistr/sistr-app/resources/public/ /usr/share/nginx/html/sistr


cat << EOF

================================================================================
Enable and start nginx
================================================================================
EOF

systemctl enable nginx.service
systemctl start nginx.service


cat << EOF

================================================================================
Setup sistr_backend Python 2.7 virtualenv
================================================================================
EOF

virtualenv .venv
source /home/sistr/sistr_backend/.venv/bin/activate
export PYTHONPATH="/home/sistr/sistr_backend"
export SISTR_APP_SETTINGS="/home/sistr/sistr_backend/sistr-config.py"

# upgrade pip to allow installation of wheel pre-compiled binary Python modules
pip install --upgrade pip
pip install wheel
pip install SQLAlchemy
pip install numpy
pip install -r requirements.txt


cat << EOF

================================================================================
SISTR DB migration (if necessary)
================================================================================
EOF
alembic upgrade head



# Modify supervisord.conf with # of Gunicorn and Celery workers that make sense for image
# TODO


cat << EOF

================================================================================
Write systemd SISTR service
================================================================================
EOF

cat > /etc/systemd/system/sistr.service <<EOF
[Unit]
Description=SISTR Supervisord
Requires=postgresql-9.5.service
After=postgresql-9.5.service
Requires=redis.service
After=redis.service

[Service]
Type=forking
User=sistr
Group=sistr
Environment="PYTHONPATH=/home/sistr/sistr_backend"
Environment="SISTR_APP_SETTINGS=/home/sistr/sistr_backend/sistr-config.py"
ExecStartPre=/usr/bin/bash -c "source /home/sistr/sistr_backend/.venv/bin/activate"
ExecStart=/home/sistr/sistr_backend/.venv/bin/supervisord -c /home/sistr/sistr_backend/supervisord.conf
ExecReload=/home/sistr/sistr_backend/.venv/bin/supervisorctl reload
ExecStop=/home/sistr/sistr_backend/.venv/bin/supervisorctl shutdown

[Install]
WantedBy=multi-user.target
EOF


cat << EOF

================================================================================
Enable sistr.service
================================================================================
EOF

systemctl enable sistr.service

/usr/sbin/groupadd -g 666 sistr
/usr/sbin/useradd sistr -u 666 -g sistr -G wheel
echo "sistr" | passwd --stdin sistr
echo "sistr        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/sistr
chmod 0440 /etc/sudoers.d/sistr

chown -R sistr:sistr /home/sistr/


cat << EOF

================================================================================
Start sistr.service
================================================================================
EOF

systemctl start sistr.service
systemctl status sistr.service


cat << EOF

================================================================================
Enable port forwarding for SISTR Gunicorn running at localhost:8000
================================================================================
EOF

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=8000/tcp
# maybe open up port for supervisorctl?
# firewall-cmd --permanent --zone=public --add-port=9001/tcp
