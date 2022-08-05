docker exec -it php-ec bash
if [ $? -eq 0 ]; then
  echo OK
else
  docker exec -it php-ec ash
fi