#!/bin/bash

# Цвета для вывода
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_RESET='\033[0m'
CLR_GREEN='\033[0;32m'

# Папка, где хранятся все контейнеры
BASE_DIR="$HOME/dria_docker_nodes"
mkdir -p "$BASE_DIR"

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_SUCCESS} Добро пожаловать в скрипт установки ноды Dria ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget curl docker.io
    sudo systemctl enable docker && sudo systemctl start docker
}

function install_node() {
    echo -e "${CLR_INFO}Начинаем установку ноды Dria...${CLR_RESET}"
    install_dependencies
    curl -fsSL https://dria.co/launcher | bash
    echo -e "${CLR_SUCCESS}Нода Dria успешно установлена!${CLR_RESET}"
}

function configure_node() {
    echo -e "${CLR_INFO}Настройка параметров ноды...${CLR_RESET}"
    dkn-compute-launcher settings
}

function start_node() {
    echo -e "${CLR_INFO}🚀 Запуск ноды Dria в screen сессии...${CLR_RESET}"
    if screen -list | grep -q "dria_node"; then
        echo -e "${CLR_WARNING}⚠ Нода уже запущена в screen сессии 'dria_node'.${CLR_RESET}"
    else
        screen -dmS dria_node bash -c "dkn-compute-launcher start; exec bash"
        echo -e "${CLR_SUCCESS}✅ Нода Dria успешно запущена в screen сессии 'dria_node'!${CLR_RESET}"
    fi
}

function update_node() {
    echo -e "${CLR_INFO}Обновление ноды до последней версии...${CLR_RESET}"
    dkn-compute-launcher update
    echo -e "${CLR_SUCCESS}Нода успешно обновлена!${CLR_RESET}"
}

function measure_models() {
    echo -e "${CLR_INFO}Измерение производительности моделей...${CLR_RESET}"
    dkn-compute-launcher measure
}

function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду Dria? (y/n)${CLR_RESET}"
    read -r confirmation
    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo -e "${CLR_INFO}🚀 Удаление ноды Dria...${CLR_RESET}"
        screen -X -S dria_node quit
        rm -rf .dria
        echo -e "${CLR_SUCCESS}✅ Нода Dria успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}❌ Удаление отменено пользователем.${CLR_RESET}"
    fi
}

add_new_docker_node() {
    echo -e "${CLR_INFO}Введите прокси в формате ip:port:username:password:${CLR_RESET}"
    read -r proxy_input

    if ! [[ "$proxy_input" =~ ^[0-9.]+:[0-9]+:.+:.+$ ]]; then
        echo -e "${CLR_ERROR}Неверный формат прокси. Используй ip:port:user:pass${CLR_RESET}"
        return
    fi

    port=4001
    while ss -tuln | grep -q ":$port "; do
        ((port++))
    done

    node_dir="$BASE_DIR/dria_node_$port"
    mkdir -p "$node_dir"

    IFS=':' read -r proxy_ip proxy_port proxy_user proxy_pass <<< "$proxy_input"

    cat > "$node_dir/Dockerfile" <<EOF
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y curl screen proxychains4 && \
    curl -L https://github.com/firstbatchxyz/dkn-compute-launcher/releases/download/v0.1.5/dkn-compute-launcher-linux-amd64 -o /usr/local/bin/dkn-compute-launcher && \
    chmod +x /usr/local/bin/dkn-compute-launcher && \
    apt clean
RUN echo "strict_chain\nproxy_dns\ntcp_read_time_out 15000\ntcp_connect_time_out 8000\n[ProxyList]\nhttp $proxy_ip $proxy_port $proxy_user $proxy_pass" > /etc/proxychains4.conf
CMD proxychains4 dkn-compute-launcher --port=$port start
EOF

    docker build -t dria_node_$port "$node_dir"
    docker run -d --name dria_node_$port --restart unless-stopped dria_node_$port

    echo -e "${CLR_SUCCESS}✅ Нода успешно установлена и запущена на порту $port через прокси ${proxy_ip}:${proxy_port}${CLR_RESET}"
}

list_nodes() {
    echo -e "${CLR_INFO}Активные контейнеры Dria:${CLR_RESET}"
    docker ps --filter name=dria_node_ --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

gpu_status() {
    echo -e "${CLR_INFO}Текущая загрузка GPU:${CLR_RESET}"
    nvidia-smi
}

schedule_restarts() {
    echo -e "${CLR_INFO}Настройка случайных перезапусков контейнеров в фоне...${CLR_RESET}"
    containers=$(docker ps --filter name=dria_node_ --format "{{.Names}}")
    for container in $containers; do
        delay=$((RANDOM % 3600 + 3600))
        (sleep $delay && echo -e "${CLR_WARNING}🔁 Перезапуск $container через $delay сек...${CLR_RESET}" && docker restart "$container") &
    done
    echo -e "${CLR_SUCCESS}✅ Таймеры перезапуска установлены для всех контейнеров.${CLR_RESET}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду (старая реализация)${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ⚙️  Настроить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) ✅ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 📊 Проверить производительность моделей${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ➕ Добавить изолированную Docker-ноду с прокси${CLR_RESET}"
    echo -e "${CLR_GREEN}8) 📄 Посмотреть список Docker-нод${CLR_RESET}"
    echo -e "${CLR_GREEN}9) 📈 Посмотреть загрузку GPU${CLR_RESET}"
    echo -e "${CLR_GREEN}10) 🔁 Настроить случайные перезапуски контейнеров${CLR_RESET}"
    echo -e "${CLR_GREEN}11) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) configure_node ;;
        3) start_node ;;
        4) update_node ;;
        5) measure_models ;;
        6) remove_node ;;
        7) add_new_docker_node ;;
        8) list_nodes ;;
        9) gpu_status ;;
        10) schedule_restarts ;;
        11) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ; exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
