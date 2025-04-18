#!/bin/bash

# Цвета
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_RESET='\033[0m'
CLR_GREEN='\033[0;32m'

# Пути
KEY_DIR="$HOME/ssh_temp_keys"
KEY_NAME="temp_key"
KEY_PATH="$KEY_DIR/$KEY_NAME"

# ======= Логотип ========
function show_logo() {
    echo -e "${CLR_INFO}         SSH Key Manager by Profit Nodes         ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/logo_new.sh | bash
}

# ======= Генерация ключей ========
function generate_keys() {
    mkdir -p "$KEY_DIR"
    if ssh-keygen -t rsa -b 4096 -C "temp@key" -f "$KEY_PATH" -N "" > /dev/null 2>&1; then
        echo -e "${CLR_SUCCESS}✅ Ключи успешно созданы в: $KEY_DIR${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}❌ Ошибка при генерации ключей.${CLR_RESET}"
    fi
}

# ======= Показ приватного ключа ========
function show_private() {
    if [ -f "$KEY_PATH" ]; then
        echo -e "${CLR_INFO}🔐 Приватный ключ:${CLR_RESET}"
        cat "$KEY_PATH"
    else
        echo -e "${CLR_WARNING}Приватный ключ не найден.${CLR_RESET}"
    fi
}

# ======= Показ публичного ключа ========
function show_public() {
    if [ -f "$KEY_PATH.pub" ]; then
        echo -e "${CLR_INFO}🔓 Публичный ключ:${CLR_RESET}"
        cat "$KEY_PATH.pub"
    else
        echo -e "${CLR_WARNING}Публичный ключ не найден.${CLR_RESET}"
    fi
}

# ======= Удаление ключей ========
function delete_keys() {
    if [ -f "$KEY_PATH" ] || [ -f "$KEY_PATH.pub" ]; then
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
        rm -rf "$KEY_DIR"
        echo -e "${CLR_SUCCESS}🗑️ Ключи и директория успешно удалены.${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Ключи уже удалены или не найдены.${CLR_RESET}"
    fi
}

# ======= Меню ========
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🔐 Сгенерировать SSH-ключи${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 📥 Показать приватный ключ${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📤 Показать публичный ключ${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️ Удалить ключи и папку${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"
    echo -ne "${CLR_INFO}Выберите действие: ${CLR_RESET}"
    read -r choice
    case $choice in
        1) generate_keys ;;
        2) show_private ;;
        3) show_public ;;
        4) delete_keys ;;
        5) exit 0 ;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}"; sleep 1 ;;
    esac
    echo ""
    show_menu
}

show_menu
