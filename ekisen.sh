#!/bin/sh

# 易占スクリプト
# 略筮法（コイン3枚・コイン6枚）

# 初期化 ------------------------------
set -u
umask 0022
PATH='/usr/bin:/bin'
IFS=$(printf ' \t\n_'); IFS=${IFS%_}
export IFS LC_ALL=C LANG=C PATH

tmp_ekisen_ka="/tmp/ekisen_ka"
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
# コインを振る（乱数）
coin_toss() {
	RANDNUM=$(od -A n -t u4 -N 4 /dev/urandom | sed 's/[^0-9]//g')
	return $(($RANDNUM % 2))
}

# サイコロを振る（乱数）
dice() {
	RANDNUM=$(od -A n -t u4 -N 4 /dev/urandom | sed 's/[^0-9]//g')
	return $(($RANDNUM % 6 + 1))
}

# 爻を求める
# 表が出たコインの枚数で決める
# 0: 老陽（陽爻が変ずる）、1:少陰、2:少陽、3:老陰（陰爻が変ずる）
divine_kou_coin3() {
	sum=0
	for i in 1 2 3
	do
		coin_toss
		sum=$(expr $sum + $?)
	done
	return $sum
}

# コイン6枚
divine_kou_coin6() {
	coin_toss
	if [ "$?" = 0 ]; then
		return 1
	else
		return 2
	fi
}

# 結果を図で表示する（老陽の表示と老陰の表示が不正）
# 0: 老陽（陽爻が変ずる）、1:少陰、2:少陽、3:老陰（陰爻が変ずる）
result_view() {
	ka_view=$(awk '$1==0{$1="━・"}$1==1{$1="--"}$1==2{$1="━"}$1==3{$1="--・"} {print NR,$0}' < $tmp_ekisen_ka |
			  sort -k 1nr,1 |
			  sed 's/^[0-9]* //')
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

# resultには、1～6爻まで順に改行区切りで入る
echo "$result" > $tmp_ekisen_ka

# コイン6枚の場合、この段階で変爻を求める
if [ "$coins" = 6 ]; then
	dice
	henkou=$?
	result=$(
	awk -v hen=$henkou 'NR==hen{
			if($1==1) $1=3;
			else if ($1==2) $1=0;
		}1' < /tmp/ekisen_ka
	)
	echo "$result" > $tmp_ekisen_ka
fi

# 本卦を求める
# コインの表の枚数の0・1と、陰爻・陽爻の0・1を分ける
honka_t=$(awk '$1==0{$1=5}$1==1{$1=6}$1==2{$1=5}$1==3{$1=6}1'< $tmp_ekisen_ka |
		  sed -e 's/5/1/' -e 's/6/0/')
honka=$(echo $honka_t | sed 's/ //g')
echo "本卦：$(grep $honka "ekikyo.txt" | awk '{print $1,$2,$3}')"
result_view

# 変爻を表示する
echo "変爻：$(awk '$1 == 0{printf "%d九 ",NR} $1 == 3{printf "%d六 ",NR}' < $tmp_ekisen_ka | 
			  sed -e 's/1/初/' -e 's/2/二/' -e 's/3/三/' -e 's/4/四/' -e 's/5/五/' -e 's/6/上/')"

# 之卦を求める
shika_t=$(awk '$1==0{$1=6}$1==1{$1=6}$1==2{$1=5}$1==3{$1=5}1'< $tmp_ekisen_ka |
		  sed -e 's/5/1/' -e 's/6/0/')
shika=$(echo $shika_t | sed 's/ //g')
echo "之卦：$(grep $shika "ekikyo.txt" | awk '{print $1,$2,$3}')"

# 互卦を求める
goka_t1=$(sed -n '2,4p' $tmp_ekisen_ka)
goka_t2=$(sed -n '3,5p' $tmp_ekisen_ka)
goka_t=$(printf "$goka_t1\n$goka_t2" |
		 awk '$1==0{$1=5}$1==1{$1=6}$1==2{$1=5}$1==3{$1=6}1' |
		 sed -e 's/5/1/' -e 's/6/0/')
goka=$(printf $goka_t | sed 's/ //g')
echo "互卦：$(grep $goka "ekikyo.txt" | awk '{print $1,$2,$3}')"

# 裏卦を求める
rika_t=$(awk '$1==0{$1=6}$1==1{$1=5}$1==2{$1=6}$1==3{$1=5}1'< $tmp_ekisen_ka |
		  sed -e 's/5/1/' -e 's/6/0/')
rika=$(echo $rika_t | sed 's/ //g')
echo "裏卦：$(grep $rika "ekikyo.txt" | awk '{print $1,$2,$3}')"

# 賓卦を求める
hinka_t=$(awk '{print NR,$0}' < $tmp_ekisen_ka | 
		  sort -k 1nr,1 |
		  sed 's/^[0-9]* //' |
		  awk '$1==0{$1=5}$1==1{$1=6}$1==2{$1=5}$1==3{$1=6}1' |
		  sed -e 's/5/1/' -e 's/6/0/')
hinka=$(echo $hinka_t | sed 's/ //g')
echo "賓卦：$(grep $hinka "ekikyo.txt" | awk '{print $1,$2,$3}')"

# 一時ファイルを削除
rm -f $tmp_ekisen_ka
