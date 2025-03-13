#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' # Зеленый текст

# Доступные сети
NETWORKS=(base optimism arbitrum polygon avalanche scroll linea gnosis abstract zora)

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодами Hyperlane      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    if ! command -v docker &> /dev/null; then
        sudo apt install docker.io -y
    else
        echo -e "${CLR_SUCCESS}Docker уже установлен.${CLR_RESET}"
    fi
}

# Функция выбора сети
function select_network() {
    echo -e "${CLR_INFO}Выберите сеть:${CLR_RESET}"
    for i in "${!NETWORKS[@]}"; do
        echo -e "${CLR_GREEN}$((i+1))) ${NETWORKS[$i]}${CLR_RESET}"
    done
    read -r network_choice
    if (( network_choice >= 1 && network_choice <= ${#NETWORKS[@]} )); then
        echo "${NETWORKS[$((network_choice-1))]}"
    else
        echo ""
    fi
}

# Функция просмотра логов
function view_logs() {
    echo -e "${CLR_INFO}Выберите сеть для просмотра логов:${CLR_RESET}"
    
    select NETWORK in "${NETWORKS[@]}"; do
        if [ -n "$NETWORK" ]; then
            CONTAINER_NAME="hyperlane_$NETWORK"

            if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                echo -e "${CLR_INFO}Просмотр логов для $NETWORK...${CLR_RESET}"
                docker logs --tail 50 -f "$CONTAINER_NAME"
            else
                echo -e "${CLR_ERROR}Контейнер $CONTAINER_NAME не найден!${CLR_RESET}"
                sleep 2
            fi
        else
            echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}"
        fi
        break
    done
}

# Функция удаления конкретной ноды
function remove_node() {
    NETWORK=$(select_network)
    if [ -n "$NETWORK" ]; then
        docker stop "hyperlane_$NETWORK"
        docker rm "hyperlane_$NETWORK"
        rm -rf "$HOME/hyperlane_db_$NETWORK"
        echo -e "${CLR_SUCCESS}Нода $NETWORK удалена.${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Неверный выбор сети.${CLR_RESET}"
    fi
}

# Функция переустановки конкретной ноды
function reinstall_node() {
    NETWORK=$(select_network)
    if [ -n "$NETWORK" ]; then
        echo -e "${CLR_INFO}Введите RPC для сети $NETWORK:${CLR_RESET}"
        read -r RPC_URL
        remove_node "$NETWORK"
        install_node "$NETWORK" "$RPC_URL"
    else
        echo -e "${CLR_ERROR}Неверный выбор сети.${CLR_RESET}"
    fi
}

# Функция установки ноды
function install_node() {
    install_dependencies
    
    echo -e "${CLR_INFO}Выберите количество сетей для установки:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) 3 сети${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 6 сетей${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 10 сетей${CLR_RESET}"
    echo -e "${CLR_GREEN}4) Выбрать конкретные сети${CLR_RESET}"
    read -r network_choice

    case $network_choice in
        1) SELECTED_NETWORKS=(base optimism arbitrum) ;;
        2) SELECTED_NETWORKS=(base optimism arbitrum polygon avalanche scroll) ;;
        3) SELECTED_NETWORKS=("${NETWORKS[@]}") ;;
        4) 
            SELECTED_NETWORKS=()
            echo -e "${CLR_INFO}Введите названия сетей через пробел (доступны: ${NETWORKS[*]})${CLR_RESET}"
            read -ra CUSTOM_NETWORKS
            for net in "${CUSTOM_NETWORKS[@]}"; do
                if [[ " ${NETWORKS[*]} " =~ " $net " ]]; then
                    SELECTED_NETWORKS+=("$net")
                else
                    echo -e "${CLR_WARNING}Сеть $net не найдена в списке.${CLR_RESET}"
                fi
            done
            ;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}"; exit 1 ;;
    esac

    echo -e "${CLR_INFO}Введите имя валидатора:${CLR_RESET}"
    read -r VALIDATOR_NAME
    echo -e "${CLR_INFO}Введите private key EVM кошелька c 0x в начале:${CLR_RESET}"
    read -r PRIVATE_KEY

    for NETWORK in "${SELECTED_NETWORKS[@]}"; do
        echo -e "${CLR_INFO}Введите вашу RPC для сети $NETWORK:${CLR_RESET}"
        read -r RPC_URL

        mkdir -p "$HOME/hyperlane_db_$NETWORK" && chmod -R 777 "$HOME/hyperlane_db_$NETWORK"

        docker run -d -it \
        --name hyperlane_$NETWORK \
        --mount type=bind,source="$HOME/hyperlane_db_$NETWORK",target="/hyperlane_db_$NETWORK" \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db "/hyperlane_db_$NETWORK" \
        --originChainName "$NETWORK" \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --validator.key "$PRIVATE_KEY" \
        --chains."$NETWORK".signer.key "$PRIVATE_KEY" \
        --chains."$NETWORK".customRpcUrls "$RPC_URL" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db_$NETWORK/checkpoints
    done
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 📜 Просмотр логов конкретной ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🗑️  Удалить конкретную ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Переустановить конкретную ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) remove_node ;;
        4) reinstall_node ;;
        5) exit 0 ;;
        *) show_menu ;;
    esac
}

show_menu
