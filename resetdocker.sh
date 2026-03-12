# stop containers and remove volumes                         09:22 
docker compose down -v

# clear the data directory
sudo rm -rf /home/sel/data/db/*

# rebuild and start
docker compose up --build -d

# follow logs to see init script output
docker compose logs -f mariadb