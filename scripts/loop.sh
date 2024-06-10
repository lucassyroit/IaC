for file in sql/*.sql; do
  mysql --password=$1 --user=$2 --host=$3 --database=phpbb < $file
done