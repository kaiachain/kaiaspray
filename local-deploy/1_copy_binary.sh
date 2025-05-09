source ./properties.sh

if [ $# -eq 2 ]; then
  echo ${1} ${2}
  rm -rf $HOMEDIR/${1}${2}/bin/k${1}
  cp $KAIACODE/build/bin/k${1} $HOMEDIR/${1}${2}/bin/k${1}
  exit
fi

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'cn*' | wc -l`; num++))
do
  rm -rf $HOMEDIR/cn$num/bin/kcn
  cp $KAIACODE/build/bin/kcn $HOMEDIR/cn$num/bin/kcn
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'pn*' | wc -l`; num++))
do
  rm -rf $HOMEDIR/pn$num/bin/kpn
  cp $KAIACODE/build/bin/kpn $HOMEDIR/pn$num/bin/kpn
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'en*' | wc -l`; num++))
do
  rm -rf $HOMEDIR/en$num/bin/ken
  cp $KAIACODE/build/bin/ken $HOMEDIR/en$num/bin/ken
done
