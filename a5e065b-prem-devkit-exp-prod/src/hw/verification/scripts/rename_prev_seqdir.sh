#!/bin/bash

count="${2:-1}"

printf -v dname "%02d" "$count"

while [ -d "../sim/$1.$dname" ]
do
  ((count++))
  printf -v dname "%02d" "$count"
done

if [ -d "../sim/$1" ]
then
  printf "renaming last sim/$1 to %s\n" "sim/$1.$dname"
  mv ../sim/$1 ../"sim/$1.$dname"
fi
