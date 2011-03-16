#postgres or sqlite
backend=sqlite

[postgres]
host=localhost
port=5432
#database admin (must have permissions to create databases and users)
dbadmin=postgres
#disable: SSL connections are never used
#allow: try non-SSL, then SSL
#prefer: try SSL, then non-SSL
#require: connect only with SSL
#default - prefer
ssl=prefer
