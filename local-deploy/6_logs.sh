if [ $# -eq 1 ]; then
  tail -f ${1}1/data/logs/k$1d.out
else
  tail -f ${1}${2}/data/logs/k$1d.out
fi