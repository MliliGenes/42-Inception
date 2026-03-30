# Inception Makefile

COMPOSE		= docker compose -f srcs/docker-compose.yml
DATA_DIR	= /home/sel/data

all: setup
	$(COMPOSE) up --build -d
	$(COMPOSE) logs mariadb
	@$(MAKE) links

links:
	@echo "WordPress: https://sel-mlil.42.fr"
	@echo "Adminer: http://localhost:8080"
	@echo "Static Page: http://localhost:3000"
	@echo "2048: http://localhost:2048"

setup:
	@sudo mkdir -p $(DATA_DIR)/mysql
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@sudo mkdir -p $(DATA_DIR)/portainer
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)

re: fclean all

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v
	@sudo rm -rf $(DATA_DIR)/mysql
	@sudo rm -rf $(DATA_DIR)/wordpress
	@sudo rm -rf $(DATA_DIR)/portainer
	@sudo mkdir -p $(DATA_DIR)/mysql
	@sudo mkdir -p $(DATA_DIR)/wordpress
	@sudo mkdir -p $(DATA_DIR)/portainer
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)

hardclean: fclean
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



.PHONY: all setup re clean fclean hardclean logs status links bash-mariadb bash-wordpress bash-nginx