## Configuring admin users

Create a file ``twpreload/twadmins``, with colon-seperated usernames and passwords, e.g:

```
cat <<EOF > twpreload/twadmins
user1:pwd1
user2:pwd2
EOF
```

## Restricting internet access

Create a ``twpreload/twhosts`` file with a white list of hosts to connect to, separated by carrage return.
