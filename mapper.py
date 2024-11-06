#!/usr/bin/env python3

import sys

# Indeksy kolumn w pliku datasource1
PRICE_COL = 0
MANUFACTURER_COL = 2
GEO_ID_COL = 17

for line in sys.stdin:
    # Podziel linie przy pomocy separatora '^'
    values = line.strip().split("^")
    
    # Odczytaj wartości dla potrzebnych pól
    try:
        price = float(values[PRICE_COL])
        manufacturer = values[MANUFACTURER_COL]
        geo_id = values[GEO_ID_COL]
        
        # Emituj klucz i wartość: klucz (geo_id, manufacturer), wartość = price
        print(f"{geo_id}|{manufacturer}\t{price}")
    
    except ValueError:
        # Obsługuje potencjalne błędy w formacie danych
        continue
