#!/bin/bash

swfs=("x_meli_costumes" "x_fourrures")
link="http://www.transformice.com/images/x_bibliotheques/"

printf "Downloading swfs\n"
mkdir ./swfs

for swf in "${swfs[@]}"
do
	for (( c=1; 1>0; c++))
	do
		if [[ $c == "1" ]]
		then
			file="$swf.swf"
		else
			file="$swf$c.swf"
		fi

		response=$(curl --write-out "%{http_code}" --head --silent --output /dev/null "$link$file")

		if [[ $response == "404" ]]
		then
			break
		else
			curl "$link$file" > "./swfs/$file"
		fi
	done
done

printf "Exporting sprites\n"
mkdir ./sprites
mkdir ./furs
mkdir ./costumes

costume="Costume_[0-9]+_"
fur="_1_[0-9]+_1$"

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

	  else
	    rm -rf $file
	  fi
	done
done

rm -rf ./swfs/ ./sprites/
