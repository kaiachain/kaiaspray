if [ $# -eq 2 ]; then
  echo ${1} ${2}
  ./2-1.deletedata.sh ${1} ${2}
  ./2-2.initnodes.sh ${1} ${2}
  exit
fi

./2-1.deletedata.sh
./2-2.initnodes.sh
