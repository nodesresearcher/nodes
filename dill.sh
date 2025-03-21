#!/bin/bash

# Оформление текста
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_RESET='\033[0m'
CLR_GREEN='\033[0;32m'

# Переменные
DILL_VERSION="v1.0.4"
DILL_DIR="$HOME/dill"
DILL_LINUX_AMD64_URL="https://dill-release.s3.ap-southeast-1.amazonaws.com/$DILL_VERSION/dill-$DILL_VERSION-linux-amd64.tar.gz"

# Функция логотипа
function show_logo() {
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодами Dill      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar
}

# Функция установки ноды
function install_node() {
    install_dependencies

    echo -e "${CLR_INFO}Скачиваем и устанавливаем Dill Node...${CLR_RESET}"
    mkdir -p "$DILL_DIR"
    cd "$DILL_DIR"

    curl -O "$DILL_LINUX_AMD64_URL"
    tar -zxvf "dill-$DILL_VERSION-linux-amd64.tar.gz"

    echo -e "${CLR_SUCCESS}Установка завершена!${CLR_RESET}"
    
    # Запуск ноды
    echo -e "${CLR_INFO}Запускаем ноду...${CLR_RESET}"
    bash "$DILL_DIR/1_launch_dill_node.sh"
}

# Функция добавления валидатора
function add_validator() {
    echo -e "${CLR_INFO}Добавляем валидатора...${CLR_RESET}"
    bash "$DILL_DIR/2_add_validator.sh"
}

# Функция просмотра логов
function view_logs() {
    echo -e "${CLR_INFO}Просмотр логов Dill Node...${CLR_RESET}"
    journalctl -fu dill -n 50
}

# Функция удаления ноды
function remove_node() {
    echo -e "${CLR_WARNING}Вы уверены, что хотите удалить ноду? (y/n)${CLR_RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo -e "${CLR_INFO}Останавливаем и удаляем ноду...${CLR_RESET}"
        sudo systemctl stop dill
        sudo systemctl disable dill
        rm -rf "$DILL_DIR"
        echo -e "${CLR_SUCCESS}Нода удалена!${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Операция отменена.${CLR_RESET}"
    fi
}

# Функция перезапуска ноды
function restart_node() {
    echo -e "${CLR_INFO}Перезапускаем ноду...${CLR_RESET}"
    sudo systemctl restart dill
    echo -e "${CLR_SUCCESS}Нода успешно перезапущена!${CLR_RESET}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🏛 Добавить валидатора${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}6) ❌ Выйти${CLR_RESET}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) add_validator ;;
        3) view_logs ;;
        4) restart_node ;;
        5) remove_node ;;
        6) exit 0 ;;
        *) show_menu ;;
    esac
}

show_menu
