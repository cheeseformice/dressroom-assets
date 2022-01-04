swfs=("costume" "x_meli_costumes" "x_fourrures" "x_items_chaman")

download_incremental () {
	local link="http://www.transformice.com/images/x_bibliotheques/$1"

	prefix="$2" # link prefix
	start=$(($3+0)) # cast parameter #2 (start) to int
	for (( c=$start; 1>0; c++ ))
	do
		if [[ $c == "1" && $4 == "true" ]]
		then
			file="$prefix.swf"
		else
			file="$prefix$c.swf"
		fi

		response=$(curl --write-out "%{http_code}" --head --silent --output /dev/null "$link$file")

		if [[ $response == "404" ]]
		then
			break
		else
			curl "$link$file" > "./swfs/$file"
		fi
	done
}

export_sprites () {
	mkdir ./sprites

	local costume="Costume_[0-9]+_"
	local fur="_1_[0-9]+_1$"
	local shaman="Objet_[0-9]+"

	for swf in ./swfs/*
	do
		printf "Exporting $(basename -- $swf)\n"
		ffdec -format sprite:svg -export sprite ./sprites "$swf" > /dev/null

		printf "Cleaning up $(basename -- $swf)\n"

		for file in ./sprites/*
		do
			if [[ $file =~ $costume ]]
			then
				mv $file "./costumes/$(basename -- $file)"

			elif [[ $file =~ $fur ]]
			then
				mv $file "./furs/$(basename -- $file)"

			elif [[ $file =~ $shaman ]]
			then
				mv $file "./shaman/$(basename -- $file)"

			else
				rm -rf $file
			fi
		done
	done

	rm -rf ./swfs/ ./sprites/
}

mkdir ./swfs
for swf in "${swfs[@]}"
do
	start=1
	if [[ $swf == "costume" ]]
	then
		ignore="false"
	else
		ignore="true"
	fi

	printf "Downloading $swf\n"
	download_incremental "" "$swf" "$start" "$ignore"
done

printf "Exporting sprites\n"
mkdir ./furs
mkdir ./costumes
mkdir ./shaman
export_sprites

mkdir ./swfs
# fur_regex="_1_([0-9]+)_1$"
# last_fur=0
# for fur in ./furs/*
# do
# 	if [[ $fur =~ $fur_regex ]]
# 	then
# 		id="${BASH_REMATCH[1]}"
# 		if [[ $last_fur -lt $id ]]
# 		then
# 			last_fur=$id
# 		fi
# 	fi
# done

# last_fur=$(($last_fur+1))
# printf "Downloading rest of furs starting from $last_fur\n"
# download_incremental "fourrures/" "f" "$last_fur" "false"
printf "Downloading rest of furs starting from 218\n"
download_incremental "fourrures/" "f" "218" "false"

shaman_regex="Objet_([0-9]+)"
declare -A shaman_items
for item in ./shaman/*
do
	if [[ $item =~ $shaman_regex ]]
	then
		id=$((${BASH_REMATCH[1]}+0))
		if [[ $id -gt 9999 ]]
		then
			base=$(((id-10000)/10000))
			skin=$(((id-10000)%10000))
		elif [[ $id -gt 99 ]]
		then
			base=$((id/100))
			skin=$((id%100))
		else
			base=$id
			skin=0
		fi

		if [[ ${shaman_items[$base]} -lt $skin || $skin == 0 ]]
		then
			shaman_items[$base]=$skin
		fi
	fi
done

for base in "${!shaman_items[@]}"
do
	skin=$((${shaman_items[$base]}+1))
	printf "Downloading rest of skins for $base starting from $skin\n"
	download_incremental "chamanes/" "o$base," "$skin" "false"
done

printf "Exporting sprites\n"
export_sprites

