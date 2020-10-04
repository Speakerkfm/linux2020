#!/usr/bin/env bash
##
## Usanin Aleksandr
## hidan9812@gmail.com
## 2020 v1
##
## Анализатор логов
##
## Нужен для ...
##
##
## exit code 10 файл не указан
## exit code 20 файл не существует
## exit code 30 скрипт уже запущен

## Проверяем, что скрипт не запущен дважды
if [ $(ps ax | grep $0 | wc -l) -gt 3 ]; then
  echo "Script is already running"
  exit 30
fi

FILE_NAME=$1
DATE_FILE=/tmp/log_analyser_dates.tmp

## Проверка на заданное имя файла
if [ -z $FILE_NAME ]; then
  echo "File name does not set"
  exit 10
fi


## Проверка на существование файла
if [ ! -f $FILE_NAME ]; then
  echo "File $FILE_NAME does not exist"
  exit 20
fi

analyse() {
  CURRENT_DATE=$(date "+%d/%b/%Y:%T")
  CURRENT_DATE_SEC=$(date +"%s")
  LAST_DATE_SEC=0

  echo "Current date: $CURRENT_DATE"
  if [ -f $DATE_FILE ]; then
    LAST_DATE=$(cat $DATE_FILE | tail -n 1)
    LAST_DATE_SEC=$(date -j -f "%d/%b/%Y:%T" $LAST_DATE "+%s")
    echo "Last analyse date: $LAST_DATE"
  fi

  NEW_RECORDS_COUNT=$(cat $1 |
    cut -d ' ' -f 4 |
    awk -v dt=$LAST_DATE_SEC '{ cmd="date -j -f \"[%d/%b/%Y:%T\" "$1" \"+%s\""; cmd | getline var; $1=var ; if (var > dt) { print } else { exit 0 } ; close(cmd); } ' |
    wc -l)

  if [ $NEW_RECORDS_COUNT -eq 0 ]; then
    echo "No new records in $FILE_NAME since $LAST_DATE"
    echo $CURRENT_DATE >> $DATE_FILE
    exit 0
  fi

  echo -e "\nТоп-15 IP-адресов, с которых посещался сайт\n"
  cat $1 |
    head -n $NEW_RECORDS_COUNT |
    cut -d ' ' -f 1 |
    sort |
    uniq -c |
    sort -nr |
    head -n 15 |
    awk ' { t = $1; $1 = $2; $2 = t; print; } '

  echo -e "\nТоп-15 ресурсов сайта, которые запрашивались клиентами\n"
  cat $1 |
    head -n $NEW_RECORDS_COUNT |
    cut -d ' ' -f 7 |
    sort |
    uniq -c |
    sort -nr |
    head -n 15 |
    awk ' { t = $1; $1 = $2; $2 = t; print; } '

  echo -e "\nСписок всех кодов возврата\n"
  cat $1 |
    head -n $NEW_RECORDS_COUNT |
    cut -d ' ' -f 9 |
    sort |
    sed 's/[^0-9]*//g' |
    awk -F '=' '$1 > 100 {print $1}' |
    uniq -c  |
    head -n 15 |
    awk ' { t = $1; $1 = $2; $2 = t; print; } '

  echo -e "\nСписок кодов возврата 4xx и 5xx (только ошибки)\n"
  cat $1 |
    head -n $NEW_RECORDS_COUNT |
    cut -d ' ' -f 9 |
    sort |
    sed 's/[^0-9]*//g' |
    awk -F '=' '$1 > 400 {print $1}' |
    uniq -c  |
    head -n 15 |
    awk ' { t = $1; $1 = $2; $2 = t; print; } '

  echo $CURRENT_DATE >> $DATE_FILE
};

analyse $FILE_NAME