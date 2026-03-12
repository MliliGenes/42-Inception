# Inception Makefile

COMPOSE		= docker compose -f srcs/docker-compose.yml
DATA_DIR	= /home/sel/data

all: setup
	$(COMPOSE) up --build -d
	$(COMPOSE) logs mariadb

setup:
	@sudo mkdir -p $(DATA_DIR)/mysql
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)

re: fclean all

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v
	@sudo rm -rf $(DATA_DIR)/mysql
	@sudo rm -rf $(DATA_DIR)/wordpress
	@sudo mkdir -p $(DATA_DIR)/mysql
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)
	docker system prune -af
	docker volume prune -f

logs:
	$(COMPOSE) logs -f

status:
	docker ps -a

bash-mariadb:
	docker exec -it mariadb bash

bash-wordpress:
	docker exec -it wordpress bash

bash-nginx:
	docker exec -it nginx bash

.PHONY: all setup re clean fclean logs status bash-mariadb bash-wordpress bash-nginx