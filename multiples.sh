#!/bin/bash

CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;97;42m'
CLR_WARNING='\033[1;30;103m'
CLR_ERROR='\033[1;97;41m'
CLR_GREEN='\033[0;32m'
CLR_RESET='\033[0m'

# Логотип
function show_logo() {
    echo -e "${CLR_GREEN}    Добро пожаловать в скрипт установки ноды Multiple   ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar wget
}

# Функция установки ноды Multiple
function install_node() {
    install_dependencies
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/install.sh"
        sleep 5
    else
        echo -e "${CLR_ERROR}❌ Ошибка: Архитектура $ARCH не поддерживается!${CLR_RESET}"
        exit 1
    fi

    echo -e "${CLR_INFO}🌍 Загружаем установочный файл...${CLR_RESET}"
    wget -O install.sh "$CLIENT_URL"
    echo -e "${CLR_INFO}⚙️ Запуск установки...${CLR_RESET}"
    sleep 5
    source ./install.sh

    echo -e "${CLR_INFO}📦 Скачивание обновления...${CLR_RESET}"
    wget -O update.sh https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/update.sh
    echo -e "${CLR_INFO}🔄 Обновление клиента...${CLR_RESET}"
    sleep 5
    source ./update.sh

    echo -e "${CLR_INFO}🚀 Запуск сервиса Multiple...${CLR_RESET}"
    wget -O start.sh https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/start.sh
    sleep 5
    source ./start.sh

    echo -e "${CLR_WARNING}🔗 Введите ваш Account ID:${CLR_RESET}"
    read -r IDENTIFIER
    echo -e "${CLR_WARNING}🔑 Введите ваш PIN:${CLR_RESET}"
    read -r PIN

    echo -e "${CLR_WARNING}🔗 Привязываем аккаунт...${CLR_RESET}"
    multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100

    echo -e "${CLR_SUCCESS}✅ Нода Multiple успешно установлена и запущена!${CLR_RESET}"
}

# Обновление ноды
function reinstal_node() {
    echo -e "${CLR_WARNING}Обновляем ноду Multiple...${CLR_RESET}"
    pkill -f multiple-node
    sudo rm -rf ~/multipleforlinux multipleforlinux.tar
    sleep 5
    install_node
    echo -e "${CLR_SUCCESS}Нода Multiple успешно обновлена!${CLR_RESET}"
}

# Удаление ноды
function remove_node() {
    echo -e "${CLR_ERROR}Удаляем ноду Multiple...${CLR_RESET}"
    pkill -f multiple-node
    sudo rm -rf ~/MultipleForLinux multipleforlinux.tar
    rm -rf multiple_node.sh
    echo -e "${CLR_SUCCESS}Нода Multiple успешно удалена!${CLR_RESET}"
}

# Просмотр статуса
function check_status() {
    if [ -d ~/multipleforlinux ]; then
        cd ~/multipleforlinux || exit
        ./multiple-cli status
    else
        echo -e "${CLR_WARNING}Нода не найдена! Убедитесь, что она установлена.${CLR_RESET}"
    fi
}

# Установка нескольких контейнеров Multiple через Docker
function install_multiple_nodes_docker() {
    echo -e "${CLR_WARNING}🔗 Введите ваш Account ID:${CLR_RESET}"
    read -r IDENTIFIER
    echo -e "${CLR_WARNING}🔑 Введите ваш PIN:${CLR_RESET}"
    read -r PIN

    echo -e "${CLR_WARNING}📦 Введите количество нод для запуска (например: 5, 10, 20):${CLR_RESET}"
    read -r NODE_COUNT

    echo -e "${CLR_INFO}🐳 Создаём Dockerfile и скрипт запуска...${CLR_RESET}"
    mkdir -p ~/multiple_docker && cd ~/multiple_docker

    cat <<EOF > Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y curl tar wget
RUN wget -O install.sh https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/install.sh && \\
    chmod +x install.sh && ./install.sh && rm install.sh
RUN wget -O update.sh https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/update.sh && \\
    chmod +x update.sh && ./update.sh && rm update.sh
COPY start-node.sh /start-node.sh
RUN chmod +x /start-node.sh
ENTRYPOINT ["/start-node.sh"]
EOF

    cat <<EOF > start-node.sh
#!/bin/bash
nohup multiple-node > /var/log/multiple-node.log 2>&1 &
sleep 5
multiple-cli bind --bandwidth-download 100 --identifier \$IDENTIFIER --pin \$PIN --storage 200 --bandwidth-upload 100
tail -f /dev/null
EOF

    docker build -t multiple-node .

    for i in \$(seq 1 \$NODE_COUNT); do
        docker run -d \\
            --name multiple-node-\${i} \\
            -e IDENTIFIER=\$IDENTIFIER \\
            -e PIN=\$PIN \\
            multiple-node
    done

    echo -e "${CLR_SUCCESS}✅ Установлено \$NODE_COUNT контейнеров с нодами Multiple!${CLR_RESET}"
}

# Перезапуск всех контейнеров
function restart_all_nodes() {
    echo -e "${CLR_INFO}🔁 Перезапускаем все контейнеры multiple-node...${CLR_RESET}"
    for container in \$(docker ps -a --filter "name=multiple-node-" --format "{{.Names}}"); do
        docker restart \$container
    done
    echo -e "${CLR_SUCCESS}✅ Все контейнеры перезапущены!${CLR_RESET}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Переустановить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 💻 Проверка статуса${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🐳 Установить несколько нод через Docker${CLR_RESET}"
    echo -e "${CLR_GREEN}7) 🔁 Перезапустить все Docker-ноды${CLR_RESET}"

    echo -e "${CLR_WARNING}Выберите действие:${CLR_RESET}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) reinstal_node ;;
        3) remove_node ;;
        4) check_status ;;
        5) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}" ;;
        6) install_multiple_nodes_docker ;;
        7) restart_all_nodes ;;
        *) echo -e "${CLR_ERROR}Неверный выбор! Пожалуйста, выберите от 1 до 7.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
