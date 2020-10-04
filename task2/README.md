Написать bash-скрипт, который анализирует лог-файл. Ссылка на лог-файл приложена.
Скрипт должен:
1. принимать путь до анализируемого файла как параметр и завершаться, отдавая сообщение об ошибке с кодом 10, если параметр не задан;
2. анализировать доступность файла по заданному пути и завершаться, отдавая сообщение об ошибке с кодом 20, если файл не существует;
3. формировать в stdout аналитической отчёт с момента последнего(!!!) запуска скрипта, который содержит:
  - обработанный скриптом временной диапазон;
  - топ-15 IP-адресов, с которых посещался сайт в виде пар "IP-адрес и количество запросов";
  - топ-15 ресурсов сайта, которые запрашивались клиентами (например, /downloads/product_1) в виде пар "ресурс и количество запросов";
  - список всех кодов возврата с указанием их количества в виде пар "код возврата и количество";
  - список кодов возврата 4xx и 5xx (только ошибки) с указанием их количества в виде пар "код возврата и количество".
4. содержать защиту от мультизапуска;
5. автоматически завершаться, если в теле скрипта будет обнаружена ошибка при его выполнении;
6. сопровождаться документацией (комментарии в теле скрипта или отдельный README).
Не обязательно, но попробуйте использовать внутри скрипта trap, sed и функции.