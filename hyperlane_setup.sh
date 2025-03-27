#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_RESET='\033[0m'
CLR_GREEN='\033[0;32m'

# Доступные сети
NETWORKS=(base optimism arbitrum polygon avalanche scroll linea gnosis)

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодами Hyperlane      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция выбора сети
function select_network() {
    echo -e "${CLR_INFO}Выберите сеть:${CLR_RESET}"
    select NETWORK in "${NETWORKS[@]}"; do
        if [[ -n "$NETWORK" ]]; then
            echo "$NETWORK" | xargs  # Убираем возможные пробелы
            return
        else
            echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}"
        fi
    done
}

# Функция просмотра логов
function view_logs() {
    echo -e "${CLR_INFO}Выберите сеть для просмотра логов:${CLR_RESET}"
    
    select NETWORK in "${NETWORKS[@]}"; do
        if [ -n "$NETWORK" ]; then
            CONTAINER_NAME="hyperlane_$NETWORK"
            echo "Ищу контейнер: $CONTAINER_NAME"

            if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                echo -e "${CLR_INFO}Просмотр логов для $NETWORK...${CLR_RESET}"
                docker logs --tail 50 -f "$CONTAINER_NAME"
            else
                echo -e "${CLR_ERROR}Контейнер $CONTAINER_NAME не найден!${CLR_RESET}"
            fi
        else
            echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}"
        fi
        break
    done
}

# Функция удаления нод (одной или всех)
function remove_node() {
    echo -e "${CLR_INFO}Выберите вариант удаления:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) Удалить конкретную ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) Удалить ВСЕ ноды сразу${CLR_RESET}"
    read -r remove_choice

    case $remove_choice in
        1)
            echo -e "${CLR_INFO}Выберите сеть для удаления:${CLR_RESET}"
            select NETWORK in "${NETWORKS[@]}"; do
                if [[ -n "$NETWORK" ]]; then
                    CONTAINER_NAME="hyperlane_$NETWORK"
                    echo "Удаляю контейнер: $CONTAINER_NAME"

                    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                        docker stop "$CONTAINER_NAME"
                        docker rm -f "$CONTAINER_NAME"
                        rm -rf "$HOME/hyperlane_db_$NETWORK"
                        echo -e "${CLR_SUCCESS}Нода $NETWORK удалена.${CLR_RESET}"
                    else
                        echo -e "${CLR_ERROR}Контейнер $CONTAINER_NAME не найден!${CLR_RESET}"
                    fi
                else
                    echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}"
                fi
                break
            done
            ;;
        2)
            echo -e "${CLR_WARNING}Вы уверены, что хотите удалить ВСЕ ноды? (y/n)${CLR_RESET}"
            read -r confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                for NETWORK in "${NETWORKS[@]}"; do
                    CONTAINER_NAME="hyperlane_$NETWORK"
                    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                        docker stop "$CONTAINER_NAME"
                        docker rm -f "$CONTAINER_NAME"
                        rm -rf "$HOME/hyperlane_db_$NETWORK"
                        echo -e "${CLR_SUCCESS}Нода $NETWORK удалена.${CLR_RESET}"
                    fi
                done
                echo -e "${CLR_SUCCESS}Все ноды удалены!${CLR_RESET}"
            else
                echo -e "${CLR_WARNING}Операция отменена.${CLR_RESET}"
            fi
            ;;
        *)
            echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}"
            ;;
    esac
}

# Функция перезапуска нод (одной или всех)
function restart_node() {
    echo -e "${CLR_INFO}Выберите вариант перезапуска:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) Перезапустить конкретную ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) Перезапустить ВСЕ ноды${CLR_RESET}"
    read -r restart_choice

    case $restart_choice in
        1)
            echo -e "${CLR_INFO}Выберите сеть для перезапуска:${CLR_RESET}"
            select NETWORK in "${NETWORKS[@]}"; do
                if [[ -n "$NETWORK" ]]; then
                    CONTAINER_NAME="hyperlane_$NETWORK"
                    echo "Перезапускаю контейнер: $CONTAINER_NAME"

                    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                        docker restart "$CONTAINER_NAME"
                        echo -e "${CLR_SUCCESS}Нода $NETWORK перезапущена.${CLR_RESET}"
                    else
                        echo -e "${CLR_ERROR}Контейнер $CONTAINER_NAME не найден!${CLR_RESET}"
                    fi
                else
                    echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}"
                fi
                break
            done
            ;;
        2)
            echo -e "${CLR_WARNING}Вы уверены, что хотите перезапустить ВСЕ ноды? (y/n)${CLR_RESET}"
            read -r confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                for NETWORK in "${NETWORKS[@]}"; do
                    CONTAINER_NAME="hyperlane_$NETWORK"
                    if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                        docker restart "$CONTAINER_NAME"
                        echo -e "${CLR_SUCCESS}Нода $NETWORK перезапущена.${CLR_RESET}"
                    fi
                done
                echo -e "${CLR_SUCCESS}Все ноды перезапущены!${CLR_RESET}"
            else
                echo -e "${CLR_WARNING}Операция отменена.${CLR_RESET}"
            fi
            ;;
        *)
            echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}"
            ;;
    esac
}

RPC_FILE="$HOME/.hyperlane_rpc"

declare -A RPC_URLS=(
    [base]="https://base.drpc.org"
    [optimism]="https://op-pokt.nodies.app"
    [arbitrum]="https://arbitrum.drpc.org"
    [polygon]="https://polygon-pokt.nodies.app"
    [avalanche]="https://avalanche.drpc.org"
    [scroll]="https://scroll.drpc.org"
    [linea]="https://linea.drpc.org"
    [gnosis]="https://gnosis-pokt.nodies.app"
)

# Загрузка сохранённых RPC, если есть
if [[ -f "$RPC_FILE" ]]; then
    while IFS== read -r key value; do
        RPC_URLS[$key]="$value"
    done < "$RPC_FILE"
fi


# Функция установки ноды
function install_node() {
    install_dependencies
    
    echo -e "${CLR_INFO}Выберите количество сетей для установки:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) 3 сети (base, optimism, arbitrum)${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 8 сетей (все доступные)${CLR_RESET}"
    echo -e "${CLR_GREEN}3) Выбрать конкретные сети${CLR_RESET}"
    read -r network_choice

    case $network_choice in
        1) SELECTED_NETWORKS=(base optimism arbitrum) ;;
        2) SELECTED_NETWORKS=("${NETWORKS[@]}") ;;
        3) 
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
    # Сохраняем значения в файл, чтобы использовать в других функциях (например, при перезапуске с новым RPC)
    echo "VALIDATOR_NAME=\"$VALIDATOR_NAME\"" > ~/.hyperlane_env
    echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> ~/.hyperlane_env



    for NETWORK in "${SELECTED_NETWORKS[@]}"; do
        RPC_URL="${RPC_URLS[$NETWORK]}"
        echo -e "${CLR_SUCCESS}Используется публичный RPC для $NETWORK: $RPC_URL${CLR_RESET}"


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

# Проверка и установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    if ! command -v docker &> /dev/null; then
        sudo apt install docker.io -y
    else
        echo -e "${CLR_SUCCESS}Docker уже установлен.${CLR_RESET}"
    fi
}

function change_rpc() {
    echo -e "${CLR_INFO}Выберите сеть, для которой хотите изменить RPC:${CLR_RESET}"
    # Загружаем сохранённые переменные
    if [[ -f ~/.hyperlane_env ]]; then
        source ~/.hyperlane_env
    else
        echo -e "${CLR_ERROR}❌ Не найдены сохранённые данные валидатора. Сначала установите ноду.${CLR_RESET}"
        return
    fi

    select NETWORK in "${!RPC_URLS[@]}"; do
        if [[ -n "$NETWORK" ]]; then
            echo -e "${CLR_INFO}Текущий RPC для $NETWORK: ${CLR_SUCCESS}${RPC_URLS[$NETWORK]}${CLR_RESET}"
            echo -e "${CLR_INFO}Введите новый RPC для $NETWORK:${CLR_RESET}"
            read -r NEW_RPC
            RPC_URLS[$NETWORK]="$NEW_RPC"
            
            # Сохраняем в файл
            RPC_URLS[$NETWORK]="$NEW_RPC"
            echo "$NETWORK=$NEW_RPC" > "$RPC_FILE.tmp"
            
            # Добавляем все текущие значения
            for net in "${!RPC_URLS[@]}"; do
                echo "$net=${RPC_URLS[$net]}" >> "$RPC_FILE.tmp"
            done
            
            mv "$RPC_FILE.tmp" "$RPC_FILE"

            echo -e "${CLR_SUCCESS}RPC для $NETWORK обновлён на: $NEW_RPC${CLR_RESET}"

            CONTAINER_NAME="hyperlane_$NETWORK"

            if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
                echo -e "${CLR_INFO}Перезапуск контейнера $CONTAINER_NAME с новым RPC...${CLR_RESET}"
                docker stop "$CONTAINER_NAME"
                docker rm "$CONTAINER_NAME"

                docker run -d -it \
                --name "$CONTAINER_NAME" \
                --mount type=bind,source="$HOME/hyperlane_db_$NETWORK",target="/hyperlane_db_$NETWORK" \
                gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
                ./validator \
                --db "/hyperlane_db_$NETWORK" \
                --originChainName "$NETWORK" \
                --reorgPeriod 1 \
                --validator.id "$VALIDATOR_NAME" \
                --validator.key "$PRIVATE_KEY" \
                --chains."$NETWORK".signer.key "$PRIVATE_KEY" \
                --chains."$NETWORK".customRpcUrls "$NEW_RPC" \
                --checkpointSyncer.type localStorage \
                --checkpointSyncer.path "/hyperlane_db_$NETWORK/checkpoints"

                echo -e "${CLR_SUCCESS}Контейнер $CONTAINER_NAME перезапущен с новым RPC.${CLR_RESET}"
            else
                echo -e "${CLR_WARNING}Контейнер $CONTAINER_NAME не найден. Возможно, он ещё не установлен.${CLR_RESET}"
            fi
            break
        else
            echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}"
        fi
    done
}


# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 📜 Просмотр логов конкретной ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🗑️  Удалить ноды (одну или все)${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Перезапустить ноды (одну или все)${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ✏️  Изменить RPC вручную для выбранной сети${CLR_RESET}"
    echo -e "${CLR_GREEN}6) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер действия и нажмите Enter:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) remove_node ;;
        4) restart_node ;;
        5) change_rpc ;;
        6) exit 0 ;;
        *) show_menu ;;
    esac
}

show_menu
