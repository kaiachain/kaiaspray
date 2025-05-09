source ./properties.sh
cd $HOMEDIR
if [ $# -eq 2 ]; then
  echo ${1} ${2}
  ${1}${2}/bin/k${1} init --datadir ${1}${2}/data homi-output/scripts/genesis.json
  exit
fi

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'cn*' | wc -l`; num++))
do
  cn$num/bin/kcn init --datadir cn$num/data homi-output/scripts/genesis.json
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'pn*' | wc -l`; num++))
do
  pn$num/bin/kpn init --datadir pn$num/data homi-output/scripts/genesis.json
done

for ((num = 1; num <= `find . -maxdepth 1 -type d -name 'en*' | wc -l`; num++))
do
  en$num/bin/ken init --datadir en$num/data homi-output/scripts/genesis.json
done
