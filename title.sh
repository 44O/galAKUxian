#!/bin/bash
# title.sh - galAKUxian タイトル画面

E=$'\e'
R="${E}[0m"
HIDE="${E}[?25l"
SHOW="${E}[?25h"

# ターミナルを80×40に設定
printf '\e[8;40;80t'
sleep 0.1  # リサイズ反映待ち

LINES=$(tput lines)
COLS=$(tput cols)
CX=$(( COLS / 2 ))
CY=$(( LINES / 2 ))

cleanup() {
    stty echo
    printf "%s" "${SHOW}${R}${E}[2J${E}[H"
    exit
}
trap cleanup SIGINT EXIT
printf "%s" "$HIDE"
stty -echo

SIN_TBL=(0 2 3 5 7 9 10 12 14 16 17 19 21 22 24 26 28 29 31 33 34 36 37 39 41 42 44 45 47 48 50 52 53 54 56 57 59 60 62 63 64 66 67 68 69 71 72 73 74 75 77 78 79 80 81 82 83 84 85 86 87 87 88 89 90 91 91 92 93 93 94 95 95 96 96 97 97 97 98 98 98 99 99 99 99 100 100 100 100 100 100 100 100 100 100 100 99 99 99 99 98 98 98 97 97 97 96 96 95 95 94 93 93 92 91 91 90 89 88 87 87 86 85 84 83 82 81 80 79 78 77 75 74 73 72 71 69 68 67 66 64 63 62 60 59 57 56 54 53 52 50 48 47 45 44 42 41 39 37 36 34 33 31 29 28 26 24 22 21 19 17 16 14 12 10 9 7 5 3 2 0 -2 -3 -5 -7 -9 -10 -12 -14 -16 -17 -19 -21 -22 -24 -26 -28 -29 -31 -33 -34 -36 -37 -39 -41 -42 -44 -45 -47 -48 -50 -52 -53 -54 -56 -57 -59 -60 -62 -63 -64 -66 -67 -68 -69 -71 -72 -73 -74 -75 -77 -78 -79 -80 -81 -82 -83 -84 -85 -86 -87 -87 -88 -89 -90 -91 -91 -92 -93 -93 -94 -95 -95 -96 -96 -97 -97 -97 -98 -98 -98 -99 -99 -99 -99 -100 -100 -100 -100 -100 -100 -100 -100 -100 -100 -100 -99 -99 -99 -99 -98 -98 -98 -97 -97 -97 -96 -96 -95 -95 -94 -93 -93 -92 -91 -91 -90 -89 -88 -87 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -75 -74 -73 -72 -71 -69 -68 -67 -66 -64 -63 -62 -60 -59 -57 -56 -54 -53 -52 -50 -48 -47 -45 -44 -42 -41 -39 -37 -36 -34 -33 -31 -29 -28 -26 -24 -22 -21 -19 -17 -16 -14 -12 -10 -9 -7 -5 -3 -2)
COS_TBL=(100 100 100 100 100 100 99 99 99 99 98 98 98 97 97 97 96 96 95 95 94 93 93 92 91 91 90 89 88 87 87 86 85 84 83 82 81 80 79 78 77 75 74 73 72 71 69 68 67 66 64 63 62 60 59 57 56 54 53 52 50 48 47 45 44 42 41 39 37 36 34 33 31 29 28 26 24 22 21 19 17 16 14 12 10 9 7 5 3 2 0 -2 -3 -5 -7 -9 -10 -12 -14 -16 -17 -19 -21 -22 -24 -26 -28 -29 -31 -33 -34 -36 -37 -39 -41 -42 -44 -45 -47 -48 -50 -52 -53 -54 -56 -57 -59 -60 -62 -63 -64 -66 -67 -68 -69 -71 -72 -73 -74 -75 -77 -78 -79 -80 -81 -82 -83 -84 -85 -86 -87 -87 -88 -89 -90 -91 -91 -92 -93 -93 -94 -95 -95 -96 -96 -97 -97 -97 -98 -98 -98 -99 -99 -99 -99 -100 -100 -100 -100 -100 -100 -100 -100 -100 -100 -100 -99 -99 -99 -99 -98 -98 -98 -97 -97 -97 -96 -96 -95 -95 -94 -93 -93 -92 -91 -91 -90 -89 -88 -87 -87 -86 -85 -84 -83 -82 -81 -80 -79 -78 -77 -75 -74 -73 -72 -71 -69 -68 -67 -66 -64 -63 -62 -60 -59 -57 -56 -54 -53 -52 -50 -48 -47 -45 -44 -42 -41 -39 -37 -36 -34 -33 -31 -29 -28 -26 -24 -22 -21 -19 -17 -16 -14 -12 -10 -9 -7 -5 -3 -2 0 2 3 5 7 9 10 12 14 16 17 19 21 22 24 26 28 29 31 33 34 36 37 39 41 42 44 45 47 48 50 52 53 54 56 57 59 60 62 63 64 66 67 68 69 71 72 73 74 75 77 78 79 80 81 82 83 84 85 86 87 87 88 89 90 91 91 92 93 93 94 95 95 96 96 97 97 97 98 98 98 99 99 99 99 100 100 100 100 100)

# ===== ロゴ =====
LOGO=(
    "                        ▄█▄    █   █   █   █"
    "                       █ ▒▓█   █▓ █ ▓  █▓  █▓"
    "  ██████   ████   █    █▓  █▓  █▓█ ▓   █▓  █▓  █   █    █   ████   █   █"
    "  █▓▓▓▓▓▓  █▓▓█▓  █▓   █████▓  ██ ▓    █▓  █▓  ▀█ █▀▓    ▓   ▓▓█▓  ██  █▓"
    "  █▓ ███   ████▓  █▓   █▓▓▓█▓  █▓█     █▓  █▓   ███▓░   █   ████▓  █▓█ █▓"
    "  █▓  ▓█▓  █▓▓█▓  █▓   █▓  █▓  █▓ █    █▓  █▓  ▄█▓█▄    █▓  █▓▓█▓  █▓ ██▓"
    "  ██████▓  █▓ █▓  ███  █▓  █▓  █▓  █   ▀███▀▓  █▒▓ █▒   █▓  ████▓  █▓  █▓"
    "   ▓▓▓▓▓▓   ▓  ▓   ▓▓▓  ▓   ▓   ▓   ▓   ░▓▓▓░   ▓   ▓    ▓   ▓▓▓▓   ▓   ▓"
)
LOGO_ROWS=${#LOGO[@]}
LOGO_LEN=${#LOGO[3]}
LOGO_X=$(( CX - LOGO_LEN / 2 ))
(( LOGO_X < 1 )) && LOGO_X=1
LOGO_Y=$(( LINES / 2 - LOGO_ROWS / 2 ))
AKU_START=22
AKU_END=46
SHADOW_ROW=7

# iの点の画面座標（星の放射原点）
# ロゴ内カラム56、行2
STAR_OX=$(( LOGO_X + 56 ))
STAR_OY=$(( LOGO_Y + 2 ))

# ===== 放射状スター =====
NUM_STARS=90
declare -a sx sy sdx sdy slife smax scolor
STAR_COLORS=(
    "${E}[1;97m" "${E}[1;96m" "${E}[1;93m"
    "${E}[1;95m" "${E}[1;92m" "${E}[97m"
    "${E}[96m"   "${E}[93m"
)
NC=${#STAR_COLORS[@]}

init_star() {
    local i=$1
    local angle=$(( RANDOM % 360 ))
    local speed=$(( (RANDOM % 4) + 2 ))
    local sv=${SIN_TBL[$angle]}
    local cv=${COS_TBL[$angle]}
    sdx[$i]=$(( cv * speed / 100 ))
    sdy[$i]=$(( sv * speed / 200 ))
    if (( sdx[i] == 0 && sdy[i] == 0 )); then sdx[$i]=1; sdy[$i]=1; fi
    # 原点はiの点
    sx[$i]=$(( STAR_OX * 16 ))
    sy[$i]=$(( STAR_OY * 16 ))
    smax[$i]=$(( (RANDOM % 35) + 20 ))
    slife[$i]=0
    scolor[$i]=$(( RANDOM % NC ))
}

for ((i=0; i<NUM_STARS; i++)); do
    init_star $i
    scatter=$(( RANDOM % 40 ))
    for ((j=0; j<scatter; j++)); do
        (( sx[i] += sdx[i] * 3 ))
        (( sy[i] += sdy[i] * 3 ))
        (( slife[i]++ ))
    done
done

AKU_COLORS=(
    "${E}[1;91m" "${E}[1;93m" "${E}[1;97m"
    "${E}[1;93m" "${E}[1;91m"
)

# Y座標レイアウト（ロゴの下に順番に並べる）
# ロゴ終端 → 空1行 → ライン → 読み → ライン → サブタイトル → ... → PRESS SPACE
READ_LINE1_Y=$(( LOGO_Y + LOGO_ROWS + 1 ))
READ_TEXT_Y=$(( LOGO_Y + LOGO_ROWS + 2 ))
READ_LINE2_Y=$(( LOGO_Y + LOGO_ROWS + 3 ))
SUB_Y=$(( LOGO_Y + LOGO_ROWS + 4 ))
PRESS_Y=$(( LINES - 2 ))

frame=0
while :; do
    # スペースキー検知：バッファを全部読んでスペースがあれば起動
    key=""
    while IFS= read -rsn1 -t 0.02 k; do
        [[ "$k" == " " ]] && key="SPACE"
    done
    if [[ "$key" == "SPACE" ]]; then
        trap - SIGINT EXIT
        stty echo
        printf "%s" "${SHOW}${R}${E}[2J${E}[H"
        # GAME_SCRIPTは起動時に外部から渡す（未設定なら終了）
        if [[ -n "$GAME_SCRIPT" && -f "$GAME_SCRIPT" ]]; then
            exec bash "$GAME_SCRIPT" "$@"
        else
            echo "ゲームスクリプトが設定されていません"
            echo "start.sh から起動してください"
            exit 1
        fi
    fi

    out="${E}[H"
    for ((y=1; y<=LINES; y++)); do out+="${E}[${y};1H${E}[K"; done

    # スター
    for ((i=0; i<NUM_STARS; i++)); do
        (( sx[i] += sdx[i] * 3 ))
        (( sy[i] += sdy[i] * 3 ))
        (( slife[i]++ ))
        px=$(( sx[i] / 16 ))
        py=$(( sy[i] / 16 ))
        if (( px < 1 || px > COLS || py < 1 || py > LINES || slife[i] >= smax[i] )); then
            init_star $i; continue
        fi
        lr=$(( slife[i] * 4 / smax[i] ))
        case $lr in
            0) ch="·" ;; 1) ch="✦" ;; 2) ch="★" ;; *) ch="✸" ;;
        esac
        out+="${E}[${py};${px}H${STAR_COLORS[${scolor[$i]}]}${ch}${R}"
    done

    # ロゴ（gal・xian同色=シアン、AKU=赤→黄サイクル）
    aku_col="${AKU_COLORS[$(( (frame / 10) % 5 ))]}"
    for ((row=0; row<LOGO_ROWS; row++)); do
        ly=$(( LOGO_Y + row ))
        (( ly < 1 || ly > LINES )) && continue
        text="${LOGO[$row]}"
        if (( row == SHADOW_ROW )); then
            out+="${E}[${ly};${LOGO_X}H${E}[2;37m${text}${R}"
        else
            gal_xian_col="${E}[1;36m"
            gal_part="${text:0:$AKU_START}"
            aku_part="${text:$AKU_START:$(( AKU_END - AKU_START ))}"
            xian_part="${text:$AKU_END}"
            out+="${E}[${ly};${LOGO_X}H"
            out+="${gal_xian_col}${gal_part}${R}"
            out+="${aku_col}${aku_part}${R}"
            out+="${gal_xian_col}${xian_part}${R}"
        fi
    done

    # 読み仮名テキスト（ブロックロゴの下に配置）
    LINE_TXT="─────────────────────────────────────"
    READ_TXT=" g  ·  a  ·  l  ·"
    AKU_TXT="[ A  K  U ]"
    READ_TXT2="·  x  ·  i  ·  a  ·  n "
    full_read="${READ_TXT}${AKU_TXT}${READ_TXT2}"
    line_x=$(( CX - ${#LINE_TXT} / 2 ))
    read_x=$(( CX - ${#full_read} / 2 ))
    (( line_x < 1 )) && line_x=1
    (( read_x < 1 )) && read_x=1
    if (( READ_LINE1_Y >= 1 && READ_LINE1_Y <= LINES )); then
        out+="${E}[${READ_LINE1_Y};${line_x}H${E}[2;36m${LINE_TXT}${R}"
    fi
    if (( READ_TEXT_Y >= 1 && READ_TEXT_Y <= LINES )); then
        out+="${E}[${READ_TEXT_Y};${read_x}H"
        out+="${E}[1;36m${READ_TXT}${R}"
        out+="${E}[1;93m${AKU_TXT}${R}"
        out+="${E}[1;36m${READ_TXT2}${R}"
    fi
    if (( READ_LINE2_Y >= 1 && READ_LINE2_Y <= LINES )); then
        out+="${E}[${READ_LINE2_Y};${line_x}H${E}[2;36m${LINE_TXT}${R}"
    fi

    # サブタイトル
    if (( SUB_Y >= 1 && SUB_Y <= LINES )); then
        sub="[ a pseudo GAPLUS experience ]"
        sub_x=$(( CX - ${#sub} / 2 ))
        out+="${E}[${SUB_Y};${sub_x}H${E}[2;36m${sub}${R}"
    fi

    # PRESS SPACE
    if (( frame % 40 < 27 )); then
        msg="[ PRESS SPACE TO START ]"
        msg_x=$(( CX - ${#msg} / 2 ))
        out+="${E}[${PRESS_Y};${msg_x}H${E}[1;93m${msg}${R}"
    fi

    printf "%s" "$out"
    sleep 0.04
    (( frame++ ))
done
