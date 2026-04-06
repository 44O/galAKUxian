#!/bin/bash

# キャプチャービーム・上下左右移動・護衛機・ボス

E=$'\e'; R="${E}[0m"; C="${E}[H"
HIDE="${E}[?25l"; SHOW="${E}[?25h"; CLEAR_LINE="${E}[K"

FG_STAR1="${E}[37m"; FG_STAR2="${E}[96m"; FG_STAR3="${E}[93m"
FG_SCORE="${E}[1;36m"
FG_ENEMY0="${E}[1;92m"; FG_ENEMY1="${E}[1;95m"; FG_ENEMY2="${E}[1;91m"
FG_BOSS="${E}[1;97m"; FG_MINIBOSS="${E}[1;93m"
FG_EBULLET="${E}[1;31m"; FG_EZIGZAG="${E}[1;33m"; FG_BBULLET="${E}[1;35m"
FG_ITEM="${E}[1;93m"; FG_ITEM_CB="${E}[1;96m"   # キャプチャーアイテム
FG_BEAM="${E}[1;96m"                             # キャプチャービーム
FG_ESCORT="${E}[1;92m"                           # 護衛機
FG_BULLET1="${E}[1;37m"; FG_BULLET2="${E}[1;91m"; FG_BULLET3="${E}[1;96m"
FG_EX_Y="${E}[1;93m"; FG_EX_R="${E}[1;91m"; FG_EX_D="${E}[2;31m"
FG_PLAYER="${E}[1;93m"; FG_RESPAWN="${E}[2;33m"; FG_DEAD="${E}[1;31m"
FG_ALERT="${E}[1;91m"

# --- 初期化 ---
LINES=$(tput lines); COLS=$(tput cols)

# 自機：上下左右移動、縦範囲は下1/3
PLAYER_X=$((COLS/2)); PLAYER_Y=$((LINES-3))
PLAYER_DX=0; PLAYER_DY=0  # 進行方向（押したら継続）
PLAYER_Y_MIN=$(( LINES*2/3 ))
PLAYER_Y_MAX=$(( LINES-2 ))
PLAYER_ALIVE=1

SCORE=0; frame=0; LEVEL=1; POWER=1; LIVES=3
BEAM_UNLOCK=0  # キャプチャービーム解放フラグ（POWERと独立）

# 点字ルックアップ
declare -a BRAILLE_TBL=(
    $'\u2801' $'\u2802' $'\u2804' $'\u2840'
    $'\u2808' $'\u2810' $'\u2820' $'\u2880'
)
declare -a LIVES_STR=("" "♥ " "♥ ♥ " "♥ ♥ ♥ " "♥ ♥ ♥ ♥ ")
SPRITE=("${FG_ENEMY0}<OX>${R}" "${FG_ENEMY1}>O=<${R}" "${FG_ENEMY2}[OX]${R}")

# 星
NUM_STARS=50
declare -a star_y star_x star_speed star_bright
for ((i=0; i<NUM_STARS; i++)); do
    star_y[$i]=$(( RANDOM % (LINES*8) ))
    star_x[$i]=$(( RANDOM % (COLS*2) ))
    star_speed[$i]=$(( (RANDOM%4)+2 ))
    star_bright[$i]=$(( RANDOM%3 ))
done

# 通常敵
ENEMY_ROWS=3; ENEMY_COLS=8; E_COUNT=$((ENEMY_ROWS*ENEMY_COLS))
declare -a e_alive e_y e_x e_type e_hp
declare -a e_mode e_angle e_radius e_phase e_target_x e_side

# 自機弾（最大3発）
m_y=(-1 -1 -1); m_x=(-1 -1 -1); m_active=(0 0 0)

# アイテム（通常パワーアップ）
p_y=-1; p_x=-1; p_active=0; p_type=0  # type:0=PWR 1=キャプチャー

# 敵弾
declare -a eb_y eb_x eb_active eb_dx eb_zigzag
for ((i=0; i<8; i++)); do eb_active[$i]=0; eb_y[$i]=-1; eb_x[$i]=-1; eb_dx[$i]=0; eb_zigzag[$i]=0; done

# 爆発
declare -a ex_y ex_x ex_ttl ex_active
for ((i=0; i<8; i++)); do ex_active[$i]=0; ex_ttl[$i]=0; done
EX_CHARS=($'\u2738' $'\u273a' $'\u273b' $'\u273c' $'\u00b7' $'\u00b7' ' ')

# ===== キャプチャービーム =====
BEAM_ACTIVE=0    # 1=照射中
BEAM_TTL=0       # 照射持続フレーム
BEAM_W=6         # ビーム幅（自機幅の約2倍）
BEAM_H=11        # ビーム高さ（3文字分追加）

# ===== 護衛機 =====
# 最大4機（左2右2）、位置は自機相対
declare -a escort_alive escort_offset escort_draw_x  # offsetはx方向のずれ、draw_xは実際のX座標
ESCORT_MAX=4
for ((i=0; i<ESCORT_MAX; i++)); do escort_alive[$i]=0; escort_draw_x[$i]=-1; done
# オフセット定義：左2右2の配置
ESCORT_OFFSETS=(6 -6 10 -10)  # 右1・左1・右2・左2の順
# 護衛機の弾（各機1発）
declare -a em_active em_y em_x
for ((i=0; i<ESCORT_MAX; i++)); do em_active[$i]=0; em_y[$i]=-1; em_x[$i]=-1; done

# ===== ボス =====
BOSS_ACTIVE=0; BOSS_X=$((COLS/2)); BOSS_Y=2
BOSS_HP=0; BOSS_MAX_HP=0
BOSS_DX=2; BOSS_PHASE=0; BOSS_FRAME=0; BOSS_Y_DIR=1
declare -a bb_y bb_x bb_active bb_dx
for ((i=0; i<6; i++)); do bb_active[$i]=0; done
BOSS_SPRITE_1="  ╔══《BOSS》══╗  "
BOSS_SPRITE_2="╠═╣ ◈  ◉  ◈ ╠═╣"
BOSS_SPRITE_3="║  ╠══════╣  ║"
BOSS_SPRITE_4="╠═╣ ▼  ▼  ▼ ╠═╣"
BOSS_SPRITE_5="  ╚══════════╝  "

# 総攻撃
RUSH_STAGE=0; RUSH_FRAME=0

CLEAR_ALL=""
for ((y=1; y<=LINES; y++)); do CLEAR_ALL+="${E}[${y};1H${CLEAR_LINE}"; done

# ===== チャレンジングステージ =====
CHALLENGE_STAGE=0      # 1=チャレンジング中
CHALLENGE_WAVE=0       # 現在の編隊番号（0〜4）
CHALLENGE_TOTAL=5      # 総編隊数
CHALLENGE_HIT=0        # 累積ヒット数
CHALLENGE_DONE=0       # ステージ終了フラグ
CHALLENGE_END_FRAME=0  # 終了後カウント

# チャレンジング敵（最大5機）
CH_MAX=5
declare -a ch_alive ch_x16 ch_y16 ch_dx16 ch_dy16 ch_hits ch_spawn_frame ch_flash
for ((i=0; i<CH_MAX; i++)); do
    ch_alive[$i]=0; ch_x16[$i]=0; ch_y16[$i]=0
    ch_dx16[$i]=0; ch_dy16[$i]=0; ch_hits[$i]=0
    ch_spawn_frame[$i]=0; ch_flash[$i]=0
done
CH_WAVE_SIZE=0         # 今の編隊の機数
CH_WAVE_SPAWNED=0      # 今の編隊で出現済み機数
CH_WAVE_ORIGIN_X=0     # 編隊出現X座標
CH_GRAVITY=1           # 重力加速度（×16固定小数点 /frame、遅め）
CH_WAVE_DX=0           # 編隊共通の横ベクトル
CH_WAVE_DY0=0          # 編隊共通の初速（縦）

init_challenge_wave() {
    # 編隊の全機をリセット
    for ((i=0; i<CH_MAX; i++)); do ch_alive[$i]=0; ch_hits[$i]=0; ch_flash[$i]=0; done
    CH_WAVE_SIZE=$(( (RANDOM%3)+3 ))   # 3〜5機
    CH_WAVE_SPAWNED=0
    CH_WAVE_ORIGIN_X=$(( (RANDOM%(COLS-10))+5 ))
    # 編隊共通の横ベクトル（全機同じ値）
    local spd_x=$(( (RANDOM%3)+2 ))
    (( RANDOM%2==0 )) && spd_x=$(( -spd_x ))
    CH_WAVE_DX=$(( spd_x * 16 / 4 ))
    CH_WAVE_DY0=$(( 3 ))              # 初速：下向き（画面上部からゆっくり落下して登場）
    local base_frame=$frame
    for ((i=0; i<CH_WAVE_SIZE; i++)); do
        ch_spawn_frame[$i]=$(( base_frame + i*5 ))  # 5フレーム間隔
    done
}

challenge_all_gone() {
    # 全機が画面外（下端・左右）に消えたか
    local gone=1
    for ((i=0; i<CH_WAVE_SIZE; i++)); do
        if (( ch_alive[i]==1 )); then gone=0; break; fi
        # spawn_frameをまだ過ぎていない機は未出現→待機中
        if (( ch_spawn_frame[i] > frame )); then gone=0; break; fi
    done
    echo $gone
}

spawn_explosion() {
    local ey=$1 ex_=$2
    for ((i=0; i<8; i++)); do
        (( ex_active[i]==0 )) && { ex_active[$i]=1; ex_y[$i]=$ey; ex_x[$i]=$ex_; ex_ttl[$i]=6; break; }
    done
}

fire_enemy_bullet() {
    local fx=$1 fy=$2 zigzag=${3:-0}
    for ((bi=0; bi<8; bi++)); do
        if (( eb_active[bi]==0 )); then
            eb_active[$bi]=1; eb_y[$bi]=$fy; eb_x[$bi]=$fx
            eb_zigzag[$bi]=$zigzag; eb_dx[$bi]=$(( (RANDOM%3)-1 ))
            break
        fi
    done
}

fire_boss_bullet() {
    local fx=$1 fy=$2 dx=$3
    for ((bi=0; bi<6; bi++)); do
        (( bb_active[bi]==0 )) && { bb_active[$bi]=1; bb_y[$bi]=$fy; bb_x[$bi]=$fx; bb_dx[$bi]=$dx; break; }
    done
}

add_escort() {
    # 空きスロットに護衛機を追加（左→右の順）
    for ((i=0; i<ESCORT_MAX; i++)); do
        (( escort_alive[i]==0 )) && { escort_alive[$i]=1; break; }
    done
}

# escort_count は ecnt変数に直接代入（サブシェル回避）
count_escorts() {
    ecnt=0
    for ((i=0; i<ESCORT_MAX; i++)); do (( escort_alive[i]==1 )) && (( ecnt++ )); done
}

DIFFICULTY=1   # ボス撃破ごとに上がる難易度（1〜）
RESPAWN_DEAD_FRAME=0  # 死亡したフレーム番号
RESPAWN_DELAY=50      # リスポーンまでのフレーム数（約2秒）

init_enemies() {
    for ((i=0; i<E_COUNT; i++)); do
        e_alive[$i]=1; e_mode[$i]=0; e_angle[$i]=0
        e_radius[$i]=0; e_phase[$i]=0; e_side[$i]=0
        e_type[$i]=$(( (i/ENEMY_COLS)%3 )); e_hp[$i]=1
    done
    # 3の倍数でRUSH、6の倍数でBOSS（RUSHも兼ねる）
    RUSH_STAGE=0; BOSS_ACTIVE=0
    if (( LEVEL%6==0 )); then
        # BOSSステージ（6の倍数）
        RUSH_STAGE=1; RUSH_FRAME=0
        BOSS_ACTIVE=1
        BOSS_X=$((COLS/2-8)); BOSS_Y=2
        BOSS_MAX_HP=$(( 8 + DIFFICULTY*4 )); BOSS_HP=$BOSS_MAX_HP
        BOSS_DX=2; BOSS_PHASE=0; BOSS_FRAME=0; BOSS_Y_DIR=1
        for ((i=0; i<6; i++)); do bb_active[$i]=0; done
        # ミニボス追加（難易度に応じて）
        for ((k=0; k<DIFFICULTY && k<3; k++)); do
            mi=$(( RANDOM%E_COUNT ))
            e_hp[$mi]=3; e_type[$mi]=2
        done
    elif (( LEVEL%3==0 )); then
        # RUSHステージ（3の倍数）
        RUSH_STAGE=1; RUSH_FRAME=0
    fi
}
init_enemies

# ===== 起動引数によるデバッグモード =====
case "${1:-}" in
    rush)
        LEVEL=3; init_enemies   # LEVEL=3がRUSH（3の倍数）
        ;;
    boss)
        LEVEL=6; init_enemies   # LEVEL=6がBOSS（6の倍数）
        ;;
    challenge)
        CHALLENGE_STAGE=1; CHALLENGE_WAVE=0; CHALLENGE_HIT=0; CHALLENGE_DONE=0
        init_challenge_wave
        ;;
esac

cleanup() {
    stty echo
    printf "%s" "${SHOW}${R}${E}[2J${C}"
    (( SCORE>0 )) && echo "=== GAME OVER ===" && echo "SCORE: $SCORE  LEVEL: $LEVEL"
    exit
}
trap cleanup SIGINT EXIT
printf "%s" "$HIDE"; stty -echo

# --- メインループ ---
while :; do
    # --- 入力 ---
    # カーソル：押した方向に進み続ける
    # 入力処理
    # バッファを全部読み、種類ごとに集計してから一括適用
    fire=0; beam_fire=0; do_stop=0
    got_dir=0; new_dx=$PLAYER_DX; new_dy=$PLAYER_DY

    while IFS= read -rsn1 -t 0.005 k; do
        if [[ $k == $'\e' ]]; then
            IFS= read -rsn2 -t 0.005 k2
            case "$k2" in
                '[D') got_dir=1; new_dx=-2; new_dy=0 ;;
                '[C') got_dir=1; new_dx=2;  new_dy=0 ;;
                '[A') got_dir=1; new_dx=0;  new_dy=-1 ;;
                '[B') got_dir=1; new_dx=0;  new_dy=1 ;;
            esac
        elif [[ $k == ' ' ]]; then
            do_stop=1; fire=1
        elif [[ $k == 'f' ]]; then
            fire=1
        elif [[ $k == 'b' ]]; then
            : # bキーは未使用
        fi
    done

    # スペース優先：方向キーより後に処理することで上書き防止
    if (( do_stop == 1 )); then
        PLAYER_DX=0; PLAYER_DY=0
    elif (( got_dir == 1 )); then
        PLAYER_DX=$new_dx; PLAYER_DY=$new_dy
    fi

    # 自機移動（生存中・リスポーン中ともに移動可能）
    (( PLAYER_X += PLAYER_DX ))
    (( PLAYER_Y += PLAYER_DY ))
    (( PLAYER_X < 1 )) && PLAYER_X=1
    (( PLAYER_X > COLS-5 )) && PLAYER_X=$((COLS-5))
    (( PLAYER_Y < PLAYER_Y_MIN )) && PLAYER_Y=$PLAYER_Y_MIN
    (( PLAYER_Y > PLAYER_Y_MAX )) && PLAYER_Y=$PLAYER_Y_MAX

    if (( PLAYER_ALIVE )); then
        # 発射
        if (( fire )); then
            for ((i=0; i<3; i++)); do
                (( m_active[i]==0 )) && { m_active[$i]=1; m_y[$i]=$((PLAYER_Y-1)); m_x[$i]=$((PLAYER_X+1)); break; }
            done
            # 護衛機も同時発射
            for ((i=0; i<ESCORT_MAX; i++)); do
                if (( escort_alive[i]==1 && em_active[i]==0 )); then
                    ex_=${ESCORT_OFFSETS[$i]}
                    em_active[$i]=1
                    em_y[$i]=$((PLAYER_Y-1))
                    em_x[$i]=$(( PLAYER_X + ex_ + 1 ))
                fi
            done
        fi

        # キャプチャービームは[B]アイテム取得で自動発動済み
    fi

    # --- 更新 ---
    # 星（ラッシュ・ボス面は逆方向＋高速）
    if (( RUSH_STAGE==1 || BOSS_ACTIVE==1 )); then
        for ((i=0; i<NUM_STARS; i++)); do
            (( star_y[i]-=star_speed[i]*3 ))
            (( star_y[i]<=0 )) && { star_y[$i]=$(( LINES*8 )); star_x[$i]=$((RANDOM%(COLS*2))); star_bright[$i]=$(( RANDOM%3 )); }
        done
    else
        for ((i=0; i<NUM_STARS; i++)); do
            (( star_y[i]+=star_speed[i] ))
            (( star_y[i]>=LINES*8 )) && { star_y[$i]=0; star_x[$i]=$((RANDOM%(COLS*2))); star_bright[$i]=$(( RANDOM%3 )); }
        done
    fi

    # キャプチャービーム処理
    if (( BEAM_ACTIVE==1 )); then
        (( BEAM_TTL-- ))
        (( BEAM_TTL<=0 )) && BEAM_ACTIVE=0

        # ビーム範囲内の敵を捕獲
        # 描画と同じ座標系で判定：cx中心、上部ほど幅広（最大幅=5*2+1=11）
        cx=$(( PLAYER_X + 1 ))
        beam_y1=$(( PLAYER_Y - BEAM_H ))
        beam_y2=$(( PLAYER_Y - 1 ))

        count_escorts  # ecntに現在の護衛機数をセット
        for ((ei=0; ei<E_COUNT; ei++)); do
            if (( e_alive[ei]==1 )); then  # mode問わず捕獲可能
                ey=${e_y[$ei]}; ex=${e_x[$ei]}
                if (( ey>=beam_y1 && ey<=beam_y2 )); then
                    # 行ごとのビーム幅を計算（描画と同じロジック）
                    brow=$(( PLAYER_Y - 1 - ey ))
                    bw=$(( 1 + brow * 5 / BEAM_H ))
                    bx1=$(( cx - bw ))
                    bx2=$(( cx + bw + 1 ))
                    if (( ex>=bx1 && ex<=bx2 )); then
                        # 捕獲！護衛機に変換
                        if (( ecnt < ESCORT_MAX )); then
                            e_alive[$ei]=0
                            e_mode[$ei]=0  # モードリセット
                            add_escort
                            spawn_explosion $ey $ex
                            (( SCORE += 500*LEVEL ))
                            (( ecnt++ ))  # ローカルカウントも更新
                        fi
                    fi
                fi
            fi
        done
    fi

    # ボス更新
    if (( BOSS_ACTIVE==1 )); then
        (( BOSS_FRAME++ ))
        (( BOSS_X+=BOSS_DX ))
        (( BOSS_X<=1 )) && BOSS_DX=${BOSS_DX#-}
        (( BOSS_X>=COLS-20 )) && BOSS_DX=$(( -(${BOSS_DX#-}) ))
        BOSS_Y_MIN=2; BOSS_Y_MAX=$(( LINES/2-4 ))
        (( BOSS_FRAME%3==0 )) && (( BOSS_Y+=BOSS_Y_DIR ))
        (( BOSS_Y>=BOSS_Y_MAX )) && BOSS_Y_DIR=-1
        (( BOSS_Y<=BOSS_Y_MIN )) && BOSS_Y_DIR=1
        bx_c=$(( BOSS_X+9 )); by_b=$(( BOSS_Y+5 ))
        case $BOSS_PHASE in
            0)
                (( BOSS_FRAME%40==0 )) && { fire_boss_bullet $bx_c $by_b -1; fire_boss_bullet $bx_c $by_b 0; fire_boss_bullet $bx_c $by_b 1; }
                (( BOSS_HP<=BOSS_MAX_HP/2 )) && { BOSS_PHASE=1; BOSS_DX=$(( BOSS_DX<0?-3:3 )); BOSS_Y_MAX=$(( LINES*2/3-4 )); }
                ;;
            1)
                (( BOSS_FRAME%25==0 )) && { fire_boss_bullet $bx_c $by_b -2; fire_boss_bullet $bx_c $by_b -1; fire_boss_bullet $bx_c $by_b 0; fire_boss_bullet $bx_c $by_b 1; fire_boss_bullet $bx_c $by_b 2; }
                ;;
        esac
        for ((bi=0; bi<6; bi++)); do
            if (( bb_active[bi]==1 )); then
                hit_escort=0
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( bb_y[bi]>=PLAYER_Y-1 && bb_y[bi]<=PLAYER_Y+1 && bb_x[bi]>=eex-1 && bb_x[bi]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            bb_active[$bi]=0; hit_escort=1; break
                        fi
                    fi
                done
                if (( hit_escort==0 && PLAYER_ALIVE && bb_y[bi]>=PLAYER_Y-1 && bb_y[bi]<=PLAYER_Y+1 && bb_x[bi]>=PLAYER_X && bb_x[bi]<=PLAYER_X+2 )); then
                    spawn_explosion $PLAYER_Y $PLAYER_X; bb_active[$bi]=0
                    (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                    for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                    (( LIVES<=0 )) && { sleep 1; cleanup; }
                fi
                (( bb_active[bi]==1 )) && { (( bb_y[bi]++ )); (( bb_x[bi]+=bb_dx[bi] )); }
                (( bb_y[bi]>=LINES || bb_x[bi]<0 || bb_x[bi]>COLS )) && bb_active[$bi]=0
            fi
        done
        # ボスへの自機弾ヒット
        for ((i=0; i<3; i++)); do
            if (( m_active[i]==1 && m_y[i]<=BOSS_Y+5 && m_y[i]>=BOSS_Y && m_x[i]>=BOSS_X && m_x[i]<=BOSS_X+18 )); then
                m_active[$i]=0; (( BOSS_HP-- ))
                spawn_explosion $((BOSS_Y+2)) $((BOSS_X+9))
                if (( BOSS_HP<=0 )); then
                    BOSS_ACTIVE=0; (( SCORE+=5000*LEVEL )); (( DIFFICULTY++ ))
                    spawn_explosion $((BOSS_Y+1)) $((BOSS_X+4))
                    spawn_explosion $((BOSS_Y+1)) $((BOSS_X+12))
                    spawn_explosion $((BOSS_Y+2)) $((BOSS_X+8))
                    p_active=1; p_y=$((BOSS_Y+3)); p_x=$((BOSS_X+8)); p_type=0
                fi
            fi
        done
        # 護衛機弾もボスに当たる
        for ((i=0; i<ESCORT_MAX; i++)); do
            if (( em_active[i]==1 && em_y[i]<=BOSS_Y+5 && em_y[i]>=BOSS_Y && em_x[i]>=BOSS_X && em_x[i]<=BOSS_X+18 )); then
                em_active[$i]=0; (( BOSS_HP-- ))
                spawn_explosion $((BOSS_Y+2)) $((BOSS_X+9))
                (( BOSS_HP<=0 )) && { BOSS_ACTIVE=0; (( SCORE+=5000*LEVEL )); }
            fi
        done
    fi

    # 総攻撃
    if (( RUSH_STAGE==1 )); then
        (( RUSH_FRAME++ ))
        if (( RUSH_FRAME%3==0 )); then
            for ((i=0; i<E_COUNT; i++)); do
                if (( e_alive[i]==1 && e_mode[i]==0 && RANDOM%4==0 )); then
                    e_mode[$i]=1; e_angle[$i]=0
                    e_radius[$i]=$(( (RANDOM%15)+20 ))
                    (( RANDOM%2==0 )) && e_radius[$i]=$(( -e_radius[i] ))
                    break
                fi
            done
        fi
        (( RUSH_FRAME>300 )) && RUSH_STAGE=0
    fi

    # 敵フォーメーション（チャレンジング中はスキップ）
    alive_count=0
    if (( CHALLENGE_STAGE==0 )); then
    spd=$(( 3+LEVEL ))
    shift_v=$(( (frame*spd)%360 ))
    rad=$(( shift_v%180 ))
    val=$(( 4*rad*(180-rad)*1000/(40500-rad*(180-rad)) ))
    [[ $shift_v -ge 180 ]] && val=$(( -val ))
    swarm_x=$(( (val*(COLS/10)/1000)+(COLS/2)-(ENEMY_COLS*3) ))
    for ((i=0; i<E_COUNT; i++)); do
        (( e_alive[i]==0 )) && continue
        (( alive_count++ ))
        btx=$(( swarm_x+(i%ENEMY_COLS)*5 ))
        bty=$(( (i/ENEMY_COLS)*2+(BOSS_ACTIVE==1?6:2) ))
        mode=${e_mode[$i]}

        if (( mode==0 )); then
            e_y[$i]=$bty; e_x[$i]=$btx
            if (( RUSH_STAGE==0 )); then
                dc=$(( 300 - DIFFICULTY*30 )); (( dc<60 )) && dc=60
                if (( RANDOM%dc==0 )); then
                    pat=$(( RANDOM%5 ))
                    case $pat in
                        0) e_mode[$i]=1; e_angle[$i]=0; e_radius[$i]=$(( (RANDOM%20)+25 )); (( RANDOM%2==0 )) && e_radius[$i]=$(( -e_radius[i] )) ;;
                        1) e_mode[$i]=2; e_angle[$i]=0; e_radius[$i]=$(( (RANDOM%15)+20 )); (( RANDOM%2==0 )) && e_radius[$i]=$(( -e_radius[i] ))
                           for delta in -1 1; do ni=$((i+delta)); (( ni>=0&&ni<E_COUNT&&e_alive[ni]==1&&e_mode[ni]==0 )) && { e_mode[$ni]=2; e_angle[$ni]=0; e_radius[$ni]=$(( -e_radius[i] )); }; done ;;
                        2) e_mode[$i]=3; e_phase[$i]=0; e_target_x[$i]=$PLAYER_X ;;
                        3) e_mode[$i]=5; e_radius[$i]=0
                           for delta in -1 1; do ni=$((i+delta)); (( ni>=0&&ni<E_COUNT&&e_alive[ni]==1&&e_mode[ni]==0 )) && { e_mode[$ni]=5; e_radius[$ni]=$(( delta*8 )); }; done ;;
                        4) e_mode[$i]=4; e_phase[$i]=0; e_side[$i]=$(( RANDOM%2==0?1:-1 )) ;;
                    esac
                fi
            fi

        elif (( mode==1||mode==2 )); then
            if (( PLAYER_ALIVE && e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=PLAYER_X-1 && e_x[i]<=PLAYER_X+3 )); then
                spawn_explosion $PLAYER_Y $PLAYER_X
                (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                (( LIVES<=0 )) && { sleep 1; cleanup; }
            elif (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 )); then
                # 護衛機への体当たりチェック
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( e_x[i]>=eex-1 && e_x[i]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            break
                        fi
                    fi
                done
            fi
            (( e_y[i]++ ))
            (( e_angle[i]=(e_angle[i]+15)%360 ))
            a=${e_angle[i]}
            if (( a<180 )); then sv=$(( 4*a*(180-a)*100/(40500-a*(180-a)) ))
            else a2=$((a-180)); sv=$(( -4*a2*(180-a2)*100/(40500-a2*(180-a2)) )); fi
            e_x[$i]=$(( btx+(e_radius[i]*sv/100) ))
            (( e_y[i]>=LINES )) && e_mode[$i]=0

        elif (( mode==3 )); then
            ph=${e_phase[$i]}
            if (( ph==0 )); then
                (( e_y[i]++ ))
                tx=${e_target_x[$i]}
                (( e_x[i]<tx )) && (( e_x[i]++ )); (( e_x[i]>tx )) && (( e_x[i]-- ))
                if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=PLAYER_X-1 && e_x[i]<=PLAYER_X+3 )); then
                    if (( PLAYER_ALIVE )); then
                        spawn_explosion $PLAYER_Y $PLAYER_X
                        (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                        for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                        (( LIVES<=0 )) && { sleep 1; cleanup; }
                    fi
                else
                # 護衛機への体当たりチェック
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=eex-1 && e_x[i]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            break
                        fi
                    fi
                done
                fi
                if (( e_y[i]>=PLAYER_Y-4 )); then fire_enemy_bullet ${e_x[$i]} ${e_y[$i]} 1; e_phase[$i]=1; fi
            elif (( ph==1 )); then
                (( e_y[i]-- )); (( e_y[i]<=bty )) && { e_phase[$i]=2; e_side[$i]=$(( RANDOM%2==0?1:-1 )); }
            elif (( ph==2 )); then
                (( e_x[i]+=e_side[i]*2 ))
                if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=PLAYER_X-1 && e_x[i]<=PLAYER_X+3 )); then
                    if (( PLAYER_ALIVE )); then
                        spawn_explosion $PLAYER_Y $PLAYER_X
                        (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                        for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                        (( LIVES<=0 )) && { sleep 1; cleanup; }
                    fi
                else
                # 護衛機への体当たりチェック
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=eex-1 && e_x[i]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            break
                        fi
                    fi
                done
                fi
                (( e_x[i]<0||e_x[i]>COLS )) && e_mode[$i]=0
            fi

        elif (( mode==4 )); then
            ph=${e_phase[$i]}
            if (( ph==0 )); then
                target=$(( e_side[i]>0?COLS-3:1 ))
                (( e_x[i]+=e_side[i]*3 )); (( e_y[i]++ ))
                (( (e_side[i]>0&&e_x[i]>=target)||(e_side[i]<0&&e_x[i]<=target) )) && { e_phase[$i]=1; fire_enemy_bullet ${e_x[$i]} ${e_y[$i]} 0; }
            elif (( ph==1 )); then
                (( e_x[i]-=e_side[i]*3 )); (( e_y[i]++ ))
                if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=PLAYER_X-1 && e_x[i]<=PLAYER_X+3 )); then
                    if (( PLAYER_ALIVE )); then
                        spawn_explosion $PLAYER_Y $PLAYER_X
                        (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                        for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                        (( LIVES<=0 )) && { sleep 1; cleanup; }
                    fi
                else
                # 護衛機への体当たりチェック
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=eex-1 && e_x[i]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            break
                        fi
                    fi
                done
                fi
                (( e_y[i]>=LINES )) && e_mode[$i]=0
            fi

        elif (( mode==5 )); then
            # 先に移動してから判定（順序修正）
            (( e_y[i]++ )); (( e_x[i]+=e_radius[i]/4 ))
            if (( PLAYER_ALIVE && e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=PLAYER_X-1 && e_x[i]<=PLAYER_X+3 )); then
                spawn_explosion $PLAYER_Y $PLAYER_X
                (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                (( LIVES<=0 )) && { sleep 1; cleanup; }
            else
                # 護衛機への体当たりチェック
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( e_y[i]>=PLAYER_Y-1 && e_y[i]<=PLAYER_Y+1 && e_x[i]>=eex-1 && e_x[i]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            break
                        fi
                    fi
                done
            fi
            (( e_y[i]>=LINES )) && e_mode[$i]=0
        fi
    done
    fi  # CHALLENGE_STAGE==0 end（フォーメーション）
    if (( alive_count==0&&BOSS_ACTIVE==0&&CHALLENGE_STAGE==0 )); then
        ((LEVEL++))
        # RUSH or BOSSの直後（LEVEL%3==1 かつ LEVEL>1）→チャレンジングステージ
        if (( LEVEL%3==1 && LEVEL>1 )); then
            CHALLENGE_STAGE=1; CHALLENGE_WAVE=0; CHALLENGE_HIT=0
            CHALLENGE_DONE=0; CHALLENGE_END_FRAME=0
            init_challenge_wave
        else
            init_enemies
        fi
    fi

    # ===== チャレンジングステージ処理 =====
    if (( CHALLENGE_STAGE==1 )); then

        # 終了処理
        if (( CHALLENGE_DONE==1 )); then
            if (( CHALLENGE_END_FRAME==0 )); then
                # ボーナス加算
                bonus=$(( CHALLENGE_HIT * 500 ))
                (( SCORE += bonus ))
            fi
            (( CHALLENGE_END_FRAME++ ))
            if (( CHALLENGE_END_FRAME > 120 )); then
                CHALLENGE_STAGE=0; CHALLENGE_DONE=0
                init_enemies
            fi
        else
            # 出現処理
            for ((i=0; i<CH_WAVE_SIZE; i++)); do
                if (( ch_alive[i]==0 && ch_spawn_frame[i]>=0 && frame>=ch_spawn_frame[i] && ch_spawn_frame[i]!=-1 )); then
                    ch_spawn_frame[$i]=-1  # 出現済みマーク
                    ch_alive[$i]=1
                    ch_x16[$i]=$(( CH_WAVE_ORIGIN_X * 16 ))
                    ch_y16[$i]=16   # y=1から出現
                    # 編隊共通の横ベクトル・初速を使用（全機同じ）
                    ch_dx16[$i]=$CH_WAVE_DX
                    ch_dy16[$i]=$CH_WAVE_DY0
                    (( CH_WAVE_SPAWNED++ ))
                fi
            done

            # 物理更新
            for ((i=0; i<CH_WAVE_SIZE; i++)); do
                if (( ch_alive[i]==1 || (ch_spawn_frame[i]==-1 && ch_alive[i]==0) )); then
                    # spawn済みで生存中のみ物理演算
                    (( ch_alive[i]==0 )) && continue
                    # 重力加算
                    (( ch_dy16[i] += CH_GRAVITY ))
                    # 位置更新
                    (( ch_x16[i] += ch_dx16[i] ))
                    (( ch_y16[i] += ch_dy16[i] ))

                    cx16=${ch_x16[$i]}; cy16=${ch_y16[$i]}
                    px=$(( cx16/16 )); py=$(( cy16/16 ))

                    # 左右壁バウンス
                    if (( px<=0 || px>=COLS-3 )); then
                        ch_dx16[$i]=$(( -ch_dx16[i] ))
                        (( px<=0 )) && { ch_x16[$i]=16; } || { ch_x16[$i]=$(( (COLS-4)*16 )); }
                    fi

                    # 自機弾との当たり判定（弾は2px/frame動くので判定幅を広めに）
                    for ((mi=0; mi<3; mi++)); do
                        if (( m_active[mi]==1 )); then
                            my=${m_y[$mi]}; mx=${m_x[$mi]}
                            # py>0（画面内）かつ縦±2・横±3の範囲
                            if (( py>0 && my>=py-2 && my<=py+2 && mx>=px-2 && mx<=px+4 )); then
                                m_active[$mi]=0
                                (( CHALLENGE_HIT++ ))
                                (( ch_hits[i]++ ))
                                # ヒット時はフラッシュ（爆発でなく）
                                ch_flash[$i]=3
                                if (( ch_dy16[i] > 0 )); then
                                    # 下降中：縦は等倍で逆転（高さ維持）、横は1.15倍加速
                                    ch_dy16[$i]=$(( -ch_dy16[i] * 20 / 20 ))
                                    ch_dx16[$i]=$(( -ch_dx16[i] * 23 / 20 ))
                                else
                                    # 上昇中：ペナルティ（横2倍加速・dxは逆転）
                                    ch_dy16[$i]=$(( ch_dy16[i] * 3 / 2 ))
                                    ch_dx16[$i]=$(( -ch_dx16[i] * 3 / 2 ))
                                fi
                            fi
                        fi
                    done

                    # 消滅判定（下端・左右）
                    px=$(( ch_x16[i]/16 )); py=$(( ch_y16[i]/16 ))
                    if (( py>=LINES || px<-5 || px>COLS+5 )); then
                        ch_alive[$i]=0
                        bonus_hit=$(( ch_hits[i] * 200 ))
                        (( SCORE += bonus_hit ))
                    fi
                fi
            done

            # 次の編隊チェック
            gone=$(challenge_all_gone)
            if (( gone==1 )); then
                (( CHALLENGE_WAVE++ ))
                if (( CHALLENGE_WAVE >= CHALLENGE_TOTAL )); then
                    CHALLENGE_DONE=1
                    CHALLENGE_END_FRAME=0
                else
                    init_challenge_wave
                fi
            fi
        fi

        # チャレンジング中は通常敵弾発射をスキップ
        # 通常の敵弾・敵移動もスキップするためここでjump
        # 描画のみ継続（後述）

    fi  # CHALLENGE_STAGE

    # 通常敵弾発射・敵弾移動（チャレンジング中はスキップ）
    if (( CHALLENGE_STAGE==0 )); then
        fc=$(( 200 - DIFFICULTY*20 )); (( fc<40 )) && fc=40
        if (( alive_count>0&&RANDOM%fc==0 )); then
            attempts=0
            while (( attempts<10 )); do
                ri=$(( RANDOM%E_COUNT ))
                if (( e_alive[ri]==1&&e_mode[ri]==0 )); then
                    zz=$(( RANDOM%3==0?1:0 ))
                    fire_enemy_bullet ${e_x[$ri]} ${e_y[$ri]} $zz; break
                fi
                (( attempts++ ))
            done
        fi

        # 敵弾・自機＋護衛機当たり判定（通常ステージのみ）
        for ((bi=0; bi<8; bi++)); do
            if (( eb_active[bi]==1 )); then
                hit_escort=0
                for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do
                    if (( escort_alive[ei2]==1 )); then
                        eex=${escort_draw_x[$ei2]}; (( eex < 0 )) && continue
                        if (( eb_y[bi]>=PLAYER_Y-1 && eb_y[bi]<=PLAYER_Y+1 && eb_x[bi]>=eex-1 && eb_x[bi]<=eex+2 )); then
                            escort_alive[$ei2]=0; em_active[$ei2]=0
                            spawn_explosion $PLAYER_Y $eex
                            eb_active[$bi]=0; hit_escort=1; break
                        fi
                    fi
                done
                if (( hit_escort==0 && PLAYER_ALIVE && eb_y[bi]>=PLAYER_Y-1 && eb_y[bi]<=PLAYER_Y+1 && eb_x[bi]>=PLAYER_X && eb_x[bi]<=PLAYER_X+2 )); then
                    spawn_explosion $PLAYER_Y $PLAYER_X; eb_active[$bi]=0
                    (( LIVES-- )); PLAYER_ALIVE=0; POWER=1; BEAM_ACTIVE=0; PLAYER_DX=0; PLAYER_DY=0; BEAM_UNLOCK=0; RESPAWN_DEAD_FRAME=$frame
                    for ((ei2=0; ei2<ESCORT_MAX; ei2++)); do escort_alive[$ei2]=0; em_active[$ei2]=0; done
                    (( LIVES<=0 )) && { sleep 1; cleanup; }
                fi
            fi
        done
    fi  # CHALLENGE_STAGE==0 end（敵弾発射・当たり判定）

    # 敵弾移動（常時：チャレンジング中も飛行継続・画面外で消滅）
    for ((bi=0; bi<8; bi++)); do
        if (( eb_active[bi]==1 )); then
            (( eb_y[bi]++ ))
            if (( eb_zigzag[bi]==1 )); then
                (( eb_x[bi]+=eb_dx[bi] ))
                (( frame%5==0 )) && eb_dx[$bi]=$(( -eb_dx[bi] ))
            fi
            (( eb_y[bi]>=LINES )) && eb_active[$bi]=0
        fi
    done

    # 自機弾移動（通常・チャレンジング共通：チャレンジング敵へのヒットはCHALLENGE処理内で実施済み）
    if (( CHALLENGE_STAGE==0 )); then
        # 通常ステージ：敵へのヒット判定あり
        for ((i=0; i<3; i++)); do
            if (( m_active[i]==1 )); then
                (( m_y[i]-=2 ))
                for ((ei=0; ei<E_COUNT; ei++)); do
                    if (( e_alive[ei]==1&&m_y[i]<=e_y[ei]+1&&m_y[i]>=e_y[ei]-1 )); then
                        hw=1; (( POWER>=2 )) && hw=3
                        if (( m_x[i]>=e_x[ei]-hw&&m_x[i]<=e_x[ei]+3 )); then
                            (( e_hp[ei]-- )); spawn_explosion ${e_y[$ei]} ${e_x[$ei]}
                            if (( e_hp[ei]<=0 )); then
                                e_alive[$ei]=0; m_active[$i]=0
                                (( SCORE+=(e_type[ei]+1)*100*LEVEL ))
                                if (( p_active==0 )); then
                                    drop=$(( RANDOM%8 ))
                                    if (( drop==0 )); then
                                        p_active=1; p_y=${e_y[$ei]}; p_x=${e_x[$ei]}; p_type=0
                                    elif (( drop==1 && BEAM_UNLOCK==0 )); then
                                        p_active=1; p_y=${e_y[$ei]}; p_x=${e_x[$ei]}; p_type=1
                                    fi
                                fi
                            else
                                m_active[$i]=0
                            fi
                            break
                        fi
                    fi
                done
                (( m_y[i]<1 )) && m_active[$i]=0
            fi
        done

        # 護衛機弾・敵ヒット判定（通常ステージのみ）
        for ((i=0; i<ESCORT_MAX; i++)); do
            if (( em_active[i]==1 )); then
                for ((ei=0; ei<E_COUNT; ei++)); do
                    if (( e_alive[ei]==1&&em_y[i]<=e_y[ei]+1&&em_y[i]>=e_y[ei]-1&&em_x[i]>=e_x[ei]-1&&em_x[i]<=e_x[ei]+3 )); then
                        (( e_hp[ei]-- )); spawn_explosion ${e_y[$ei]} ${e_x[$ei]}
                        if (( e_hp[ei]<=0 )); then e_alive[$ei]=0; (( SCORE+=(e_type[ei]+1)*100*LEVEL )); fi
                        em_active[$i]=0; break
                    fi
                done
            fi
        done
    else
        # チャレンジング中：自機弾は動かすが通常敵ヒット判定なし
        for ((i=0; i<3; i++)); do
            if (( m_active[i]==1 )); then
                (( m_y[i]-=2 ))
                (( m_y[i]<1 )) && m_active[$i]=0
            fi
        done
    fi

    # 護衛機弾移動（常時：チャレンジング中も飛行継続・画面外で消滅）
    for ((i=0; i<ESCORT_MAX; i++)); do
        if (( em_active[i]==1 )); then
            (( em_y[i]-=2 ))
            (( em_y[i]<1 )) && em_active[$i]=0
        fi
    done

    # 復活（チャレンジング中も有効）・リスポーン中は移動可能
    if (( !PLAYER_ALIVE )); then
        if (( frame - RESPAWN_DEAD_FRAME >= RESPAWN_DELAY )); then
            PLAYER_ALIVE=1
        fi
    fi

    # アイテム移動・取得
    if (( p_active==1 )); then
        (( p_y++ ))
        if (( p_y>=PLAYER_Y-1&&p_y<=PLAYER_Y+1&&p_x>=PLAYER_X-1&&p_x<=PLAYER_X+3 )); then
            if (( p_type==0 )); then
                (( POWER<3 )) && (( POWER++ ))
            else
                # [B]取得で即ビーム自動発動（約5秒=125フレーム）
                BEAM_ACTIVE=1; BEAM_TTL=125; BEAM_UNLOCK=1
            fi
            p_active=0
        fi
        (( p_y>=LINES )) && p_active=0
    fi

    # 爆発TTL
    for ((i=0; i<8; i++)); do
        (( ex_active[i]==1 )) && { (( ex_ttl[i]-- )); (( ex_ttl[i]<=0 )) && ex_active[$i]=0; }
    done

    # --- 描画 ---
    out="${C}${CLEAR_ALL}"

    # 星
    for ((si=0; si<NUM_STARS; si++)); do
        sy=$(( star_y[si]/8+1 )); sx=$(( star_x[si]/2+1 ))
        by=$(( (star_y[si]/2)%4 )); bx=$(( star_x[si]%2 ))
        case ${star_bright[$si]} in 0) col=$FG_STAR1;; 1) col=$FG_STAR2;; 2) col=$FG_STAR3;; esac
        out+="${E}[${sy};${sx}H${col}${BRAILLE_TBL[$(( bx*4+by ))]}${R}"
    done

    # 自機移動範囲ライン（薄く表示）
    out+="${E}[$((PLAYER_Y_MIN));1H${E}[2;34m$(printf '─%.0s' $(seq 1 $COLS))${R}"

    # キャプチャービーム描画（竜巻スタイル）
    # 下から上へ広がりながららせん状に
    if (( BEAM_ACTIVE==1 )); then
        cx=$(( PLAYER_X + 1 ))  # 中心X
        # 各行の「幅」と「オフセット」を下→上で変える
        # 下：細い、上：広い（竜巻の広がり）
        # らせん：フレームで左右にゆらゆら
        phase=$(( frame % 8 ))
        for ((row=0; row<BEAM_H; row++)); do
            by=$(( PLAYER_Y - 1 - row ))
            (( by < 1 )) && continue
            # 下ほど細く・暗く、上ほど太く・明るく
            w=$(( 1 + row * 5 / BEAM_H ))   # 幅1〜5
            # らせん：rowとphaseで左右にゆれる
            spiral=$(( (row + phase) % 4 ))
            case $spiral in
                0) off=$(( -w/2 )) ;;
                1) off=$(( 0 )) ;;
                2) off=$(( w/2 )) ;;
                3) off=$(( 0 )) ;;
            esac
            bx_draw=$(( cx + off - w/2 ))
            # 濃さ：下ほど薄く
            density=$(( row * 4 / BEAM_H ))
            case $density in
                0) ch="░" ; col="${E}[2;36m" ;;
                1) ch="▒" ; col="${E}[36m" ;;
                2) ch="▓" ; col="${FG_BEAM}" ;;
                3) ch="█" ; col="${E}[1;97m" ;;
            esac
            beam_line=""
            for ((bw=0; bw<w*2+1; bw++)); do beam_line+="${ch}"; done
            out+="${E}[${by};${bx_draw}H${col}${beam_line}${R}"
        done
        # 残り時間表示
        (( BEAM_TTL>20 )) && beam_st="${FG_BEAM}≋BEAM≋${R}" || beam_st="${FG_ALERT}≋BEAM≋${R}"
        out+="${E}[$((PLAYER_Y));$((PLAYER_X+4))H${beam_st}"
    fi

    # ボス描画
    if (( BOSS_ACTIVE==1 )); then
        hp_pct=$(( BOSS_HP*20/BOSS_MAX_HP ))
        hp_bar=""; for ((k=0; k<hp_pct; k++)); do hp_bar+="█"; done
        hp_empty=""; for ((k=hp_pct; k<20; k++)); do hp_empty+="░"; done
        out+="${E}[2;$((COLS/2-12))H${FG_BOSS}BOSS HP:${FG_ALERT}${hp_bar}${FG_DEAD}${hp_empty}${R}"
        blink=1; (( BOSS_FRAME%4<2||BOSS_HP==BOSS_MAX_HP )) && blink=1 || blink=0
        if (( blink==1 )); then
            (( BOSS_PHASE==0 )) && { c1=$FG_BOSS; c2=$FG_MINIBOSS; c3=$FG_BOSS; c4=$FG_MINIBOSS; c5=$FG_BOSS; } \
                                 || { c1=$FG_ALERT; c2=$FG_DEAD; c3=$FG_ALERT; c4=$FG_DEAD; c5=$FG_ALERT; }
            out+="${E}[$((BOSS_Y+1));$((BOSS_X+1))H${c1}${BOSS_SPRITE_1}${R}"
            out+="${E}[$((BOSS_Y+2));$((BOSS_X+1))H${c2}${BOSS_SPRITE_2}${R}"
            out+="${E}[$((BOSS_Y+3));$((BOSS_X+1))H${c3}${BOSS_SPRITE_3}${R}"
            out+="${E}[$((BOSS_Y+4));$((BOSS_X+1))H${c4}${BOSS_SPRITE_4}${R}"
            out+="${E}[$((BOSS_Y+5));$((BOSS_X+1))H${c5}${BOSS_SPRITE_5}${R}"
        fi
        for ((bi=0; bi<6; bi++)); do
            (( bb_active[bi]==1 )) && out+="${E}[$((bb_y[bi]+1));$((bb_x[bi]+1))H${FG_BBULLET}◇${R}"
        done
    fi

    # 総攻撃アラート
    if (( RUSH_STAGE==1 && BOSS_ACTIVE==0 && RUSH_FRAME<60 )); then
        (( frame%10<5 )) && out+="${E}[$((LINES/2));$((COLS/2-8))H${FG_ALERT}!!! RUSH STAGE !!!${R}"
    fi

    # ボス登場メッセージ
    if (( BOSS_ACTIVE==1 && BOSS_FRAME<80 )); then
        msg="★  BIG BOSS INCOMING  ★"
        mx=$(( COLS/2 - ${#msg}/2 ))
        (( frame%8<5 )) && out+="${E}[$((LINES/2));${mx}H${E}[1;91m${msg}${R}"
    fi

    # スコア
    rush_ind=""; (( RUSH_STAGE==1 )) && rush_ind=" ${FG_ALERT}★RUSH★${R}${FG_SCORE}"
    boss_ind=""; (( BOSS_ACTIVE==1 )) && boss_ind=" ${FG_BOSS}★BOSS★${R}${FG_SCORE}"
    chal_ind=""; (( CHALLENGE_STAGE==1 )) && chal_ind=" ${E}[1;96m★CHALLENGE★${R}${FG_SCORE}"
    pwr_str="PWR:${POWER}"
    beam_str=""; (( BEAM_UNLOCK==1 )) && beam_str=" ${FG_BEAM}[BEAM]${R}${FG_SCORE}"
    out+="${E}[1;1H${FG_SCORE} SCORE:${SCORE}  LV:${LEVEL}  ${pwr_str}${beam_str}  ${LIVES_STR[$LIVES]}${rush_ind}${boss_ind}${chal_ind}${R}"

    # チャレンジングステージ描画
    if (( CHALLENGE_STAGE==1 )); then
        # ヒット数を画面中央に大きく表示
        hit_y=$(( LINES/2 - 1 ))
        hit_label="  HIT  "
        hit_num="  ${CHALLENGE_HIT}  "
        hit_lx=$(( COLS/2 - ${#hit_label}/2 ))
        hit_nx=$(( COLS/2 - ${#hit_num}/2 ))
        out+="${E}[${hit_y};${hit_lx}H${E}[2;96m${hit_label}${R}"
        out+="${E}[$((hit_y+1));${hit_nx}H${E}[1;97m${hit_num}${R}"
        # 編隊情報
        wave_str="WAVE $((CHALLENGE_WAVE+1))/${CHALLENGE_TOTAL}"
        wave_x=$(( COLS/2 - ${#wave_str}/2 ))
        (( CHALLENGE_DONE==0 )) && out+="${E}[$((hit_y+2));${wave_x}H${E}[1;96m${wave_str}${R}"

        # チャレンジング敵描画
        for ((i=0; i<CH_WAVE_SIZE; i++)); do
            if (( ch_alive[i]==1 )); then
                epx=$(( ch_x16[i]/16 )); epy=$(( ch_y16[i]/16 ))
                # フラッシュカウント更新
                (( ch_flash[i]>0 )) && (( ch_flash[i]-- ))
                if (( epy>=1 && epy<LINES && epx>=1 && epx<COLS-2 )); then
                    if (( ch_flash[i]>0 )); then
                        # ヒット直後：白くフラッシュ
                        ech="${E}[1;97m[★]${R}"
                    elif (( ch_dy16[i] < 0 )); then
                        # 上昇中：黄
                        ech="${E}[1;93m(★)${R}"
                    else
                        # 下降中：シアン
                        ech="${E}[1;96m(★)${R}"
                    fi
                    out+="${E}[$((epy+1));$((epx+1))H${ech}"
                    # ヒット数を敵の上に小さく
                    if (( ch_hits[i]>0 && epy>=2 )); then
                        out+="${E}[$((epy));$((epx+1))H${E}[2;93m${ch_hits[$i]}${R}"
                    fi
                fi
            fi
        done

        # 終了ボーナス表示
        if (( CHALLENGE_DONE==1 && CHALLENGE_END_FRAME<=120 )); then
            bonus=$(( CHALLENGE_HIT * 500 ))
            bd1="★ CHALLENGE CLEAR ★"
            bd2="BONUS: +${bonus}"
            bd3="TOTAL HITS: ${CHALLENGE_HIT}"
            bx1=$(( COLS/2 - ${#bd1}/2 ))
            bx2=$(( COLS/2 - ${#bd2}/2 ))
            bx3=$(( COLS/2 - ${#bd3}/2 ))
            by1=$(( LINES/2 - 3 ))
            out+="${E}[$((by1));${bx1}H${E}[1;93m${bd1}${R}"
            out+="${E}[$((by1+1));${bx2}H${E}[1;97m${bd2}${R}"
            out+="${E}[$((by1+2));${bx3}H${E}[1;96m${bd3}${R}"
        fi
    fi

    # 敵
    for ((ei=0; ei<E_COUNT; ei++)); do
        if (( e_alive[ei]==1 )); then
            if (( e_hp[ei]>1 )); then
                (( e_hp[ei]>=3 )) && mb_col="${FG_MINIBOSS}" || (( e_hp[ei]==2 )) && mb_col="${FG_ALERT}" || mb_col="${FG_DEAD}"
                (( frame%6<4 )) && out+="${E}[$((e_y[ei]+1));$((e_x[ei]+1))H${mb_col}«★»${R}" \
                                 || out+="${E}[$((e_y[ei]+1));$((e_x[ei]+1))H${FG_BOSS}«★»${R}"
            else
                out+="${E}[$((e_y[ei]+1));$((e_x[ei]+1))H${SPRITE[${e_type[$ei]}]}"
            fi
        fi
    done

    # 敵弾
    for ((bi=0; bi<8; bi++)); do
        if (( eb_active[bi]==1 )); then
            (( eb_zigzag[bi]==1 )) && out+="${E}[$((eb_y[bi]+1));$((eb_x[bi]+1))H${FG_EZIGZAG}◆${R}" \
                                    || out+="${E}[$((eb_y[bi]+1));$((eb_x[bi]+1))H${FG_EBULLET}▼${R}"
        fi
    done

    # 爆発
    for ((i=0; i<8; i++)); do
        if (( ex_active[i]==1 )); then
            ttl=${ex_ttl[$i]}; ch="${EX_CHARS[$(( 6-ttl ))]}"; ey_=${ex_y[$i]}; ex__=${ex_x[$i]}
            case $ttl in
                6|5) out+="${E}[$((ey_+1));$((ex__+1))H${FG_EX_Y}${ch}${R}" ;;
                4|3) out+="${E}[$((ey_));$((ex__+1))H${FG_EX_R}${ch}${R}${E}[$((ey_+2));$((ex__+1))H${FG_EX_R}${ch}${R}${E}[$((ey_+1));$((ex__))H${FG_EX_R}${ch}${R}${E}[$((ey_+1));$((ex__+2))H${FG_EX_R}${ch}${R}" ;;
                2|1) out+="${E}[$((ey_+1));$((ex__+1))H${FG_EX_D}·${R}" ;;
            esac
        fi
    done

    # アイテム
    if (( p_active==1 )); then
        if (( p_type==1 )); then
            out+="${E}[$((p_y+1));$((p_x+1))H${FG_ITEM_CB}[B]${R}"
        else
            out+="${E}[$((p_y+1));$((p_x+1))H${FG_ITEM}[P]${R}"
        fi
    fi

    # 自機弾
    for ((i=0; i<3; i++)); do
        if (( m_active[i]==1 )); then
            case $POWER in
                1) out+="${E}[$((m_y[i]+1));$((m_x[i]+1))H${FG_BULLET1}|${R}" ;;
                2) out+="${E}[$((m_y[i]+1));$((m_x[i]))H${FG_BULLET2}!!!${R}" ;;
                3|4) out+="${E}[$((m_y[i]+1));$((m_x[i]-1))H${FG_BULLET3}|=#=|${R}" ;;
            esac
        fi
    done

    # 護衛機弾
    for ((i=0; i<ESCORT_MAX; i++)); do
        (( em_active[i]==1 )) && out+="${E}[$((em_y[i]+1));$((em_x[i]+1))H${FG_ESCORT}|${R}"
    done

    # 護衛機（実座標を更新してから描画・当たり判定に使う）
    ecnt=0
    for ((i=0; i<ESCORT_MAX; i++)); do
        if (( escort_alive[i]==1 )); then
            ex_=${ESCORT_OFFSETS[$ecnt]}
            ex_draw=$(( PLAYER_X + ex_ + 1 ))
            escort_draw_x[$i]=$ex_draw
            (( ex_draw>=1 && ex_draw<=COLS-3 )) && out+="${E}[$((PLAYER_Y+1));${ex_draw}H${FG_ESCORT}(·)${R}"
            (( ecnt++ ))
        else
            escort_draw_x[$i]=-1
        fi
    done

    # 自機
    if (( PLAYER_ALIVE )); then
        out+="${E}[$((PLAYER_Y+1));$((PLAYER_X+1))H${FG_PLAYER}(A)${R}"
    else
        respawn_remain=$(( RESPAWN_DELAY - (frame - RESPAWN_DEAD_FRAME) ))
        # 点滅（3フレームON/2フレームOFF）で明るく
        if (( frame%5 < 3 )); then
            out+="${E}[$((PLAYER_Y+1));$((PLAYER_X-1))H${E}[1;93m>(+)<${R}"
        fi
        # 残り時間バー
        bar_len=$(( respawn_remain * 10 / RESPAWN_DELAY ))
        bar=""; for ((k=0;k<bar_len;k++)); do bar+="█"; done
        empty=""; for ((k=bar_len;k<10;k++)); do empty+="░"; done
        out+="${E}[$((PLAYER_Y_MAX+1));$((COLS/2-8))H${E}[1;91m✦RESPAWN ${E}[1;93m${bar}${E}[2;37m${empty}${R}"
    fi

    # 操作説明（画面下端）
    out+="${E}[$((LINES));1H${E}[2;37m ←→↑↓:移動継続  SPACE:停止+射撃  f:射撃  [B]取得でキャプチャービーム自動発動${R}"

    printf "%s" "$out"
    sleep 0.04
    ((frame++))
done
