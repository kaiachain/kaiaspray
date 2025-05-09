source ./properties.sh
cd $HOMEDIR
if [ $# -eq 2 ]; then
  echo ${1} ${2}
  ${1}${2}/bin/k${1}d stop
  exit
fi
for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'cn*' | wc -l`; num++))
do
  cn$num/bin/kcnd stop
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'pn*' | wc -l`; num++))
do
  pn$num/bin/kpnd stop
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'en*' | wc -l`; num++))
do
  en$num/bin/kend stop
done
