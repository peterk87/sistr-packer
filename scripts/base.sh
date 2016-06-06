sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

mv /etc/issue /etc/issue.old
cat > /etc/issue <<EOF
  _________.___  ______________________________  
 /   _____/|   |/   _____/\__    ___/\______   \ 
 \_____  \ |   |\_____  \   |    |    |       _/ 
 /        \|   |/        \  |    |    |    |   \ 
/_______  /|___/_______  /  |____|    |____|_  / 
        \/             \/                    \/  

Welcome to the SISTR Virtual Environment.

As you can see, the Virtual Environment does not have a GUI installed. You should interact with SISTR using the HTTP API, a web browser or a terminal.

You can access the SISTR HTTP API through http://localhost:44448/api/. 

You can access the SISTR web interface by navigating to http://localhost:44449/sistr in your web browser. The SISTR public username and password is \`sistr\` and \`sistr\`.

ADVANCED USERS ONLY: You can log into this virtual environment by using the username \`vagrant\` and the password \`vagrant\`. Alternatively, you can SSH into this virtual environment by running \`ssh -p42222 vagrant@localhost\` and using the password \`vagrant\`.

EOF

cat /etc/issue.old >> /etc/issue
rm /etc/issue.old