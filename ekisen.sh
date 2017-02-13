#!/bin/sh

# 易占スクリプト
# Ver2.x 実装方法変更
# 略筮法（コイン3枚・コイン6枚）

# 初期化 ------------------------------
set -u
umask 0022
PATH='/usr/bin:/bin'
IFS=$(printf ' \t\n_'); IFS=${IFS%_}
export IFS LC_ALL=C LANG=C PATH
# -------------------------------------
# 引数処理 ----------------------------
if [ $# = 1 ]; then
	if [ "$1" = "-3" ]; then
		coins=3
	elif [ "$1" = "-6" ]; then
		coins=6
	fi
else
	coins=3
fi

# -------------------------------------
# 乱数を得る（コインを振る・サイコロを振る【変数coinsに依存】
rand_coin_dice() {
	RANDNUM=$(od -A n -t u4 -N 4 /dev/urandom | sed 's/[^0-9]//g')

	if [ $coins -eq 3 ]; then
		return $(($RANDNUM % 2))
	elif [ $coins -eq 6 ]; then
		return $(($RANDNUM % 6 + 1))
	else
		return $(($RANDNUM % 2))
	fi
}

# 爻を求める
# 表が出たコインの枚数で決める
# 0: 老陽（陽爻が変ずる）、1:少陰、2:少陽、3:老陰（陰爻が変ずる）
divine_kou_coin3() {
	sum=0
	for i in 1 2 3
	do
		rand_coin_dice
		sum=$(expr $sum + $?)
	done
	return $sum
}

# コイン6枚
divine_kou_coin6() {
	rand_coin_dice
	if [ "$?" = 0 ]; then
		return 1
	else
		return 2
	fi
}

# 結果を図で表示する
# 0: 老陽（陽爻が変ずる）、1:少陰、2:少陽、3:老陰（陰爻が変ずる）
result_view() {
	ka_view=$(cat /tmp/ekisen_ka |
			  sed -e 's/0/━・/g' -e 's/1/--/g' -e 's/2/━/g' -e 's/3/--・/g' |
			  awk '{printf("%s\n%s\n%s\n%s\n%s\n%s\n",$6,$5,$4,$3,$2,$1)}'
	)
	echo "$ka_view"
}

result=$(
	if [ "$coins" = 3 ]; then
		for i in 1 2 3 4 5 6
		do
			divine_kou_coin3
			echo $?
		done
	elif [ "$coins" = 6 ]; then
		for i in 1 2 3 4 5 6
		do
			divine_kou_coin6
			echo $?
		done
	fi
)

# resultには、1～6爻まで順に空白区切りで入る
echo $result > /tmp/ekisen_ka

# コイン6枚の場合、この段階で変爻を求める
if [ "$coins" = 6 ]; then
	rand_coin_dice
	henkou=$?
	result=$(awk -v hen=$henkou '{if($hen==1) $hen=3; else if($hen==2) $hen=0;}1' < /tmp/ekisen_ka)
	echo $result > /tmp/ekisen_ka
fi

# 本卦を求める
# コインの表の枚数の0・1と、陰爻・陽爻の0・1を分ける
honka=$(cat /tmp/ekisen_ka |
		sed -e 's/0/5/g' -e 's/1/6/g' -e 's/2/5/g' -e 's/3/6/g' |
		sed -e 's/5/1/g' -e 's/6/0/g')
echo $honka > /tmp/ekisen_honka

honka_geka_t=$(cat /tmp/ekisen_honka | awk '{print $1,$2,$3}' | sed 's/ //g' )
honka_geka=$(grep $honka_geka_t "eki_8ka.txt" | awk '{print $1}')
honka_jouka_t=$(cat /tmp/ekisen_honka | awk '{print $4,$5,$6}' | sed 's/ //g' )
honka_jouka=$(grep $honka_jouka_t "eki_8ka.txt" | awk '{print $1}')
echo "本卦：$(cat eki_64ka.txt | awk -v ge=$honka_geka -v jou=$honka_jouka '$2==jou && $3==ge {print $1,$4,$5}')"
result_view

# 変爻を表示する
echo "変爻：$(cat /tmp/ekisen_ka |
			  awk '{for(i=1;i<=NF;i++){if($i==0) printf("%d九 ",i); else if($i==3) printf("%d六 ",i);}}' |
			  sed -e 's/1/初/' -e 's/2/二/' -e 's/3/三/' -e 's/4/四/' -e 's/5/五/' -e 's/6/上/')"

# 之卦を求める
shika=$(cat /tmp/ekisen_ka |
		sed -e 's/0/6/g' -e 's/1/6/g' -e 's/2/5/g' -e 's/3/5/g' |
		sed -e 's/5/1/g' -e 's/6/0/g')
echo $shika > /tmp/ekisen_shika
shika_geka_t=$(cat /tmp/ekisen_shika | awk '{print $1,$2,$3}' | sed 's/ //g' )
shika_geka=$(grep $shika_geka_t "eki_8ka.txt" | awk '{print $1}')
shika_jouka_t=$(cat /tmp/ekisen_shika | awk '{print $4,$5,$6}' | sed 's/ //g' )
shika_jouka=$(grep $shika_jouka_t "eki_8ka.txt" | awk '{print $1}')
echo "之卦：$(cat eki_64ka.txt | awk -v ge=$shika_geka -v jou=$shika_jouka '$2==jou && $3==ge {print $1,$4,$5}')"

# 互卦を求める
goka=$(cat /tmp/ekisen_ka |
	   awk '{print $2,$3,$4,$3,$4,$5}' |
	   sed -e 's/0/5/g' -e 's/1/6/g' -e 's/2/5/g' -e 's/3/6/g' |
	   sed -e 's/5/1/g' -e 's/6/0/g')
echo $goka > /tmp/ekisen_goka
goka_geka_t=$(cat /tmp/ekisen_goka | awk '{print $1,$2,$3}' | sed 's/ //g' )
goka_geka=$(grep $goka_geka_t "eki_8ka.txt" | awk '{print $1}')
goka_jouka_t=$(cat /tmp/ekisen_goka | awk '{print $4,$5,$6}' | sed 's/ //g' )
goka_jouka=$(grep $goka_jouka_t "eki_8ka.txt" | awk '{print $1}')
echo "互卦：$(cat eki_64ka.txt | awk -v ge=$goka_geka -v jou=$goka_jouka '$2==jou && $3==ge {print $1,$4,$5}')"

## 裏卦を求める（未修正）
#rika_t=$(awk '$1==0{$1=6}$1==1{$1=5}$1==2{$1=6}$1==3{$1=5}1'< /tmp/ekisen_ka |
#		  sed -e 's/5/1/' -e 's/6/0/')
#rika=$(echo $rika_t | sed 's/ //g')
#echo "裏卦：$(grep $rika "ekikyo.txt" | awk '{print $1,$2,$3}')"
#
## 賓卦を求める（未修正）
#hinka_t=$(awk '{print NR,$0}' < /tmp/ekisen_ka | 
#		  sort -k 1nr,1 |
#		  sed 's/^[0-9]* //' |
#		  awk '$1==0{$1=5}$1==1{$1=6}$1==2{$1=5}$1==3{$1=6}1' |
#		  sed -e 's/5/1/' -e 's/6/0/')
#hinka=$(echo $hinka_t | sed 's/ //g')
#echo "賓卦：$(grep $hinka "ekikyo.txt" | awk '{print $1,$2,$3}')"
#
## 一時ファイルを削除
rm -f /tmp/ekisen_ka
rm -f /tmp/ekisen_honka
rm -f /tmp/ekisen_shika
