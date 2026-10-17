#!/usr/bin/env julia

# Абсолютно полная база данных ASCII-артов
const LOGOS = Dict(
    "arch" => (
        color = "\x1b[36m", # Циан
        icon = "   ",
        lines = [
            "       /\\       ",
            "      /  \\      ",
            "     /\\   \\     ",
            "    /      \\    ",
            "   /   _    \\   ",
            "  /   _|_    \\  ",
            " /___/   \\___\\ "
        ]
    ),
    "gentoo" => (
        color = "\x1b[95m", # Ярко-розовый
        icon = " ",
        lines = [
            " _-----_ ",
            "(       \\",
            "\\    0   \\",
            " \\        )",
            " /      _/ ",
            "(     _-   ",
            "\\____-     "
        ]
    ),
    "guix" => (
        color = "\x1b[33m", # Желтый
        icon = " ",
        lines = [
            "..                             `.",
            " `--..```..`           `..```..--`",
            "   .-:///-:::.       `-:::///:-.",
            "      ````.:::`     `:::.````   ",
            "           -//:`    -::-        ",
            "            ://:   -::-         ",
            "            `///- .:::`         ",
            "             -+++-:::.          ",
            "              :+/:::-           ",
            "              `-....`           "
        ]
    ),
    "android" => (
        color = "\x1b[92m", # Ярко-зеленый
        icon = " ",
        lines = [
            "  ;,           ,; ",
            "   ';,.-----.,;'  ",
            "  ,'           ', ",
            " /    O     O    \\",
            "|                 |",
            "'-----------------'"
        ]
    ),
    "debian" => (
        color = "\x1b[31m", # Красный
        icon = " ",
        lines = [
            "  _____     ",
            " /  __ \\    ",
            "|  /  | |   ",
            "|  \\_/  |   ",
            " \\_____/    ",
            "  \\\\        ",
            "   \\\\____   ",
            "    \\____|  "
        ]
    ),
    "fedora" => (
        color = "\x1b[34m", # Синий
        icon = " ",
        lines = [
            "        ______       ",
            "       / ____/___    ",
            "      / /_  / __ \\   ",
            "     / __/ / /_/ /   ",
            "    /_/    \\____/    ",
            "  _    __            ",
            " / |  / /___ _  __   ",
            " | | / / __ \\ |/_/   ",
            " | |/ / /_/ />  <    ",
            " |___/\\____/_/|_|    "
        ]
    ),
    "mint" => (
        color = "\x1b[32m", # Зеленый
        icon = " ",
        lines = [
            " ___________ ",
            "|_          |",
            "  | |\\   /| |",
            "  | | \\ / | |",
            "  | |  V  | |",
            "  | |     | |",
            "  |_________|"
        ]
    ),
    "ubuntu" => (
        color = "\x1b[31m", # Красный
        icon = " ",
        lines = [
            "         _          ",
            "      /\\   /\\       ",
            "     ((     ))      ",
            "  ___ \\\\___// ___   ",
            " /   \\       /   \\  ",
            "((   ))     ((   )) ",
            " \\___/       \\___/  "
        ]
    )
)

# Секретные цитаты для троллинга друга на Rust
const SECRETS = [
    "«Rust — это язык, на котором пишут hello world три часа, а потом гордятся, что он скомпилировался.»",
    "«Go для микросервисов, Julia для математики и Highload. Лучший дуэт, в котором нет места унылому Rust!»",
    "«Зачем компилировать код со скоростью черепахи на Rust, если на Julia можно запустить JIT и обогнать его на первом же вираже?»",
    "«Rust говно, потому что программисты на Rust тратят 90% времени на борьбу с компилятором, а не на создание маркетплейсов.»"
]

const RESET = "\x1b[0m"
const BOLD = "\x1b[1m"

# Иконки Nerd Font
const ICON_KERNEL = " "
const ICON_SHELL  = " "
const ICON_TERM   = " "
const ICON_DE     = " "
const ICON_RAM    = " "

# Палитра (цветные кружочки)
const PALETTE = "\x1b[30m● \x1b[31m● \x1b[32m● \x1b[33m● \x1b[34m● \x1b[35m● \x1b[36m● \x1b[37m●" * RESET

# Железобетонная функция честного подсчета ОЗУ
function get_ram_info()
    total_mem, free_mem, buffers, cached = 0, 0, 0, 0
    if isfile("/proc/meminfo")
        for line in eachline("/proc/meminfo")
            if startswith(line, "MemTotal:") total_mem = parse(Int, split(line)[2])
            elseif startswith(line, "MemFree:") free_mem = parse(Int, split(line)[2])
            elseif startswith(line, "Buffers:") buffers = parse(Int, split(line)[2])
            elseif startswith(line, "Cached:") cached = parse(Int, split(line)[2])
            end
        end
    end
    used_mem = total_mem - free_mem - buffers - cached
    total_mib = round(Int, total_mem / 1024)
    used_mib = round(Int, used_mem / 1024)
    pct = total_mib > 0 ? used_mib / total_mib : 0.0
    bars = round(Int, pct * 10)
    bar_str = "[" * repeat("#", bars) * repeat("-", 10 - bars) * "]"
    return string(used_mib) * "MiB / " * string(total_mib) * "MiB " * bar_str
end

# Определение DE/WM
function get_de_wm()
    de = get(ENV, "XDG_CURRENT_DESKTOP", get(ENV, "DESKTOP_SESSION", ""))
    if get(ENV, "HYPRLAND_INSTANCE_SIGNATURE", "") != "" return "Hyprland"
    elseif get(ENV, "I3SOCK", "") != "" return "i3wm"
    elseif get(ENV, "SWAYSOCK", "") != "" return "Sway"
    end
    return de != "" ? de : "Unknown (WM/DE)"
end

# Системное инфо
function get_system_info()
    user = get(ENV, "USER", "user")
    host = isfile("/etc/hostname") ? readchomp("/etc/hostname") : "localhost"
    os_name, os_id = "Linux", "linux"
    if isfile("/etc/os-release")
        for line in eachline("/etc/os-release")
            if startswith(line, "NAME=") os_name = strip(replace(line, "NAME=" => ""), ['"', '\''])
            elseif startswith(line, "ID=") os_id = strip(replace(line, "ID=" => ""), ['"', '\''])
            end
        end
    end
    kernel = readchomp(`uname -r`)
    shell = basename(get(ENV, "SHELL", "bash"))
    term = get(ENV, "TERM", "alacritty")
    return (user=user, host=host, os_name=os_name, os_id=os_id, kernel=kernel, shell=shell, term=term)
end

function main()
    # Обработка секретного флага
    if length(ARGS) >= 1 && (ARGS[1] == "-secret" || ARGS[1] == "--secret")
        println("\x1b[33m\x1b[1m[jfetch - Секретная база]:\x1b[0m")
        println("\x1b[35m" * rand(SECRETS) * "\x1b[0m")
        return
    end

    info = get_system_info()
    ram = get_ram_info()
    dewm = get_de_wm()
    
    # Автоопределение лого
    default_logo = "arch"
    if haskey(LOGOS, info.os_id) default_logo = info.os_id
    elseif occursin("arch", lowercase(info.os_name)) default_logo = "arch"
    elseif occursin("android", lowercase(info.os_name)) default_logo = "android"
    elseif occursin("mint", lowercase(info.os_name)) default_logo = "mint"
    elseif occursin("debian", lowercase(info.os_name)) default_logo = "debian"
    elseif occursin("fedora", lowercase(info.os_name)) default_logo = "fedora"
    elseif occursin("ubuntu", lowercase(info.os_name)) default_logo = "ubuntu"
    end
    
    logo_name = default_logo
    i = 1
    while i <= length(ARGS)
        if (ARGS[i] == "-logo" || ARGS[i] == "--logo") && i + 1 <= length(ARGS)
            logo_name = lowercase(ARGS[i+1])
            break
        end
        i += 1
    end
    
    logo = get(LOGOS, logo_name, LOGOS["arch"])
    
    # Классический чистый дизайн
    info_lines = [
        logo.color * BOLD * info.user * "@" * info.host * RESET,
        logo.color * "-----------------------" * RESET,
        logo.icon * " OS:     " * info.os_name,
        ICON_KERNEL * " Kernel: " * info.kernel,
        ICON_DE * " DE/WM:  " * dewm,
        ICON_SHELL * " Shell:  " * info.shell,
        ICON_TERM * " Term:   " * info.term,
        ICON_RAM * " RAM:    " * ram,
        "", 
        PALETTE 
    ]
    
    max_lines = max(length(logo.lines), length(info_lines))
    logo_width = length(logo.lines) > 0 ? maximum(length, logo.lines) : 15
    
    for idx in 1:max_lines
        if idx <= length(logo.lines)
            padded_logo = rpad(logo.lines[idx], logo_width)
            print(logo.color * padded_logo * RESET * "  ")
        else
            print(repeat(" ", logo_width + 2))
        end
        
        if idx <= length(info_lines)
            print(info_lines[idx])
        end
        println()
    end
end

main()
