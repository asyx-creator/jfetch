#!/usr/bin/env bash

clear
gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "1 2" \
	"jfetch Installer v3.3" "Быстрая установка команды и зависимостей"

# 1. ТЕХНИЧЕСКИЙ ВЫБОР ОКРУЖЕНИЯ
gum style --foreground 117 "Выберите ваше окружение:"
TARGET_ENV=$(gum choose "Arch Linux" "Termux (Android)")

# 2. АВТОМАТИЧЕСКАЯ УСТАНОВКА ЯЗЫКА JULIA
if [ "$TARGET_ENV" == "Arch Linux" ]; then
    gum style --foreground 214 "Проверка зависимостей для Arch Linux..."
    if ! command -v julia &> /dev/null; then
        gum style --foreground 196 "Julia не найдена! Устанавливаем через pacman..."
        sudo pacman -S --noconfirm julia
    else
        gum style --foreground 82 "✔ Julia уже установлена в системе"
    fi
else
    gum style --foreground 214 "Проверка зависимостей для Termux..."
    if ! command -v julia &> /dev/null; then
        gum style --foreground 196 "Julia не найдена! Устанавливаем через pkg..."
        pkg install -y julia
    else
        gum style --foreground 82 "✔ Julia уже установлена в Termux"
    fi
fi

# 3. АВТОМАТИЧЕСКАЯ УСТАНОВКА JETBRAINS MONO NERD FONT (ЧЕРЕЗ PACMAN ДЛЯ ARCH)
if [ "$TARGET_ENV" == "Arch Linux" ]; then
    gum style --foreground 117 "Проверить и установить JetBrains Mono Nerd Font?"
    if gum confirm "Установить официальный пакет шрифта через pacman?"; then
        if ! pacman -Qi ttf-jetbrains-mono-nerd &> /dev/null; then
            gum spin --spinner dot --title "Установка ttf-jetbrains-mono-nerd через pacman..." -- \
                sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd
            gum style --foreground 82 "✔ Нативный шрифт успешно установлен в систему!"
        else
            gum style --foreground 82 "✔ Шрифт ttf-jetbrains-mono-nerd уже есть в вашей системе"
        fi
    fi
fi

# 4. ВЫБОР ПУТИ УСТАНОВКИ КОМАНДЫ
gum style --foreground 117 "Куда установить саму команду jfetch?"
INSTALL_TYPE=$(gum choose "Глобально (нужен sudo, /usr/local/bin)" "Локально (без sudo, ~/.local/bin)")

if [ "$INSTALL_TYPE" == "Глобально (нужен sudo, /usr/local/bin)" ]; then
    BIN_DIR="/usr/local/bin"
    SUDO="sudo"
else
    BIN_DIR="$HOME/.local/bin"
    SUDO=""
    mkdir -p "$BIN_DIR"
fi

# 5. СОЗДАНИЕ КОМАНДЫ
if [ -f "./jfetch.jl" ]; then
    $SUDO cp ./jfetch.jl "$BIN_DIR/jfetch"
    $SUDO chmod +x "$BIN_DIR/jfetch"
    gum style --foreground 82 "✔ Команда успешно скопирована в $BIN_DIR/jfetch"
else
    gum style --foreground 196 "Ошибка: Файл jfetch.jl не найден в текущей папке!"
    exit 1
fi

# 6. НАСТРОЙКА АЛИАСОВ (АВТОЗАПУСК)
gum style --foreground 117 "Хотите настроить alias для быстрого вызова?"
if gum confirm "Добавить jfetch в конфигурацию вашего шелла?"; then
    if [ -n "$ZSH_VERSION" ]; then
        RC_FILE="$HOME/.zshrc"
    else
        RC_FILE="$HOME/.bashrc"
    fi

    if [ "$TARGET_ENV" == "Termux (Android)" ]; then
        echo "alias jfetch='$BIN_DIR/jfetch -logo android'" >> "$RC_FILE"
    else
        echo "alias jfetch='$BIN_DIR/jfetch'" >> "$RC_FILE"
    fi
    gum style --foreground 82 "✔ Алиас успешно добавлен в $RC_FILE"
    gum style --foreground 214 "Запустите 'source $RC_FILE' для применения настроек!"
fi

# ФИНАЛЬНОЕ УВЕДОМЛЕНИЕ
gum style \
	--foreground 82 --border-foreground 82 --border rounded \
	--align center --width 50 --margin "1" \
	"Всё готово! 🎉" "Установка завершена. Команда 'jfetch' полностью готова к запуску."
