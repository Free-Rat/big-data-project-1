#!/usr/bin/env python3

import sys

# Aktualny klucz i zmienne sumujące
current_geo_id = None
current_manufacturer = None
current_count = 0
current_price_sum = 0

for line in sys.stdin:
    # Podziel dane wejściowe
    geo_id, manufacturer, price = line.strip().split("\t")
    price = float(price)
    
    # Sprawdź, czy przetwarzamy nowy klucz (geo_id, manufacturer)
    if (geo_id, manufacturer) == (current_geo_id, current_manufacturer):
        # Aktualizuj sumę i licznik
        current_price_sum += price
        current_count += 1
    else:
        # Jeśli to nowy klucz i poprzedni spełnia warunek >= 10, wyświetl wynik
        if current_geo_id and current_count >= 10:
            print(f"{current_geo_id}\t{current_manufacturer}\t{current_count}\t{current_price_sum}")
        
        # Zresetuj zmienne dla nowego klucza
        current_geo_id = geo_id
        current_manufacturer = manufacturer
        current_price_sum = price
        current_count = 1

# Wydrukuj ostatni wynik, jeśli spełnia warunek >= 10
if current_geo_id and current_count >= 10:
    print(f"{current_geo_id}\t{current_manufacturer}\t{current_count}\t{current_price_sum}")
