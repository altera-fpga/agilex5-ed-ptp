#!/bin/bash

count="${2:-1}"

printf -v dname "%02d" "$count"

while [ -d "../sim.$dname" ]
do
  ((count++))
  printf -v dname "%02d" "$count"
done

if [ -d "../sim" ]
then
  printf "renaming last sim to %s\n" "sim.$dname"
  mv ../sim ../"sim.$dname"
fi
