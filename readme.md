# Описание
Набор скриптов для обработки большого количества медиафайлов.

Фичи
- возможность избавиться от дубликатов и похожих файлов,
- низкие риски удаления важных файлов (возможность работать с диском для чтения, проверки потенциально опасных операций)
- возможность автоматически скорректировать метки времени для файлов (mtime, время модификации)
- индексация для ускорения повторной обработки


# Инструкция

1) Подготовка файлов (необязательно)
2) Индексация (необязательно)
3) Реорганизация (формирование команд переноса файлов)
4) Проверка (необязательно)
5) Перенос файлов


## Подготовка файлов
### Даты файлов
Сначала желательно убедиться, что у файлов стоят корректные метки времени. Это
важно, потому что приложения просмотра фото, типа облака mail файлы в ленте упорядочены по дате.
Метки времени могут быть некорректными, если файлы были отредактированы или 
были скачаны из google takeout.

## Индексация
```bash
docker run --rm -it --name media_tools \
  -v /home/user/media/files:/vt/media \
  -v /home/user/media/cache:/vt/cache \
  -e LOG_LEVEL=Logger::DEBUG \
  -u=$UID:$UID \
  vovan/media_tools ./cache_meta.sh
```

- `/home/user/media/files` содержит видео и изображения.
- `/home/user/media/cache` - в этой папке будут созданы файлы с метаданными
для каждого файла.

## Реорганизация
```bash
docker run --rm -it --name media_tools \ 
  -v /home/user/media/existing:/vt/existing \
  -v /home/user/media/new:/vt/new \
  -v /home/user/media/dups:/vt/dups \
  -v /home/user/media/new_broken:/vt/new_broken \  
  -u=$UID:$UID \
  vovan/media_tools ./reorganize.sh
```

- `/home/user/media/existing` - папка с файлами, которые уже есть в коллекции.
- `/home/user/media/new` - папка с новыми файлами.
- `/home/user/media/dups` - папка, куда будут перемещены дубликаты.
- `/home/user/media/new_broken` - папка, куда планируется перемещать файлы, которые не удалось обработать.
- `/home/user/media/cache` - в этой папке будут созданы файлы с метаданными
  для каждого файла, либо будут использованы существующие файлы.

## Проверка
Нужно просмотреть сгенерированный командный файл и убедиться, что он корректный.

## Перенос файлов
Программа не удаляет дубликаты, а только подготавливает командный файл, в котором
записаны команды перемещения дубликатов в отдельную папку папку. Это сделано для того,
чтобы при наличии сомнений можно было вручную проверить, что файлы действительно дубликаты.

# Примечания
**perceptual hash**

Для сравнения файлов используется perceptual hash. Это позволяет находить дубликаты, 
даже если у медиа-файлов отличаются разрешения (ширина и высота), форматы (jpg, png, mp4, mov, avi, mkv, ...),
битрейт, кодеки, и т.д.

**ложноположительные срабатывания**

В некоторых редких случаях программа может ошибаться и считать разные файлы одинаковыми.
Например, оригинальное видео и сделанный из него таймлэпс программа может посчитать
одинаковыми. Это связано с особенностью алгоритма сравнения видео. Или если видео-файлы
имеют одинаковый размер и одинаковые первые 16 КБ данных, то программа может посчитать
их одинаковыми.


## Examples of video for testing
http://samples.mplayerhq.hu/


