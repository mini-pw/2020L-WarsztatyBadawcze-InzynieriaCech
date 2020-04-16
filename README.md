# 2020L-WarsztatyBadawcze-InzynieriaCech

## Plan zajęć

* 2020-02-28 - O co chodzi z artykułami naukowymi?

    - [Efficient and Accurate Methods for Updating Generalized Linear Models with Multiple Feature Additions](http://jmlr.org/papers/volume15/dhurandhar14a/dhurandhar14a.pdf) 
    
    - [OpenML: networked science in machine learning](https://arxiv.org/pdf/1407.7722.pdf) 
    
    Warto zobaczyć:
    - [Limitations of Interpretable Machine Learning Methods](https://compstat-lmu.github.io/iml_methods_limitations/)

* 2020-03-06 - OpenML - wybór i analiza zbiorów danych

    Warto zobaczyć:
    - [Stop Explaining Black Box Machine Learning Models for High Stakes Decisions and Use Interpretable Models Instead](https://arxiv.org/pdf/1811.10154.pdf)
   
* 2020-03-13 - prezentacje zdalnie:

1. Problem klasyfikacji dla klas uporządkowanych: Karol Saputa, Małgorzata Wachulec, Aleksandra Wichrowska
2. GBM: Wojciech Bogucki, Tomasz Makowski, Dominik Rafacz
3. Metody imputacji danych: Mateusz Bakala, Michał Pastuszka, Karol Pysiak

* 2020-03-20 prezentacje zdalnie przez Zoom: https://us04web.zoom.us/j/2254905395

4. randomForest: Bartłomiej Granat, Szymon Maksymiuk
5. XAI: Wojciech Kretowicz, Łukasz Brzozowski, Kacper Siemaszko
6. XGboost: Rydelek, Merkel, Stawikowski

* 2020-03-27 - prezentacje zdalnie: https://us04web.zoom.us/j/2254905395

7. SAFE/modelStudio: Hubert Baniecki, Mateusz Polakowski
8. Prezentacja artykułu: https://arxiv.org/pdf/1811.10154.pdf: Olaf Werner, Bogdan Jastrzębski

* 2020-04-03 - problem niezbalansowanych klas + bookdown + praca domowa 1

* 2020-04-17 - prezentacja PD1 + praca domowa 2

* 2020-04-24 - projekt

* 2020-04-29 - prezentacja PD2 + projekt

* 2020-05-01 - projekt

* 2020-05-08 - projekt

* 2020-05-12 - projekt

* 2020-05-15 - projekt

* 2020-05-22 - projekt

* 2020-05-29 - ?

* 2020-06-05 - ?

## Prezentacje (15 pkt.)

Należy przygotować prezentację na jeden z uzgodnionych tematów.

## Prace domowe (15 pkt.)

### Praca domowa 1 

* Pracę domową należy wykonać pojedynczo. Na podstawie zbioru danych „sick" dostępnych w zbiorze OpenML należy wykonać analizę eksploracyjną oraz zbudować interpretowalny model klasyfikacyjny przewidujący czy pacjent jest chory czy zdrowy. Powinna zostać użyta 5-krotna kroswalidacja do znalezienia odpowiedniego modelu na zbiorze treningowym i wyliczone dwie miary na zbiorze testowym: AUC i AUPRC. Do podziału zbioru na zbiór treningowy i testowy, proszę użyć dostępnych indeksów zbioru treningowego w folderze 'Praca domowa 1'.

* Praca w formie raportu .pdf i .Rmd w języku angielskim powinna być zamieszczona w folderze https://github.com/mini-pw/2020L-WarsztatyBadawcze-InzynieriaCech/tree/master/PracaDomowa1/ImieNazwisko do 17.04 do godz. 10 oraz zaprezentowana (max. 10 minut) podczas zajęć 17.04. 

### Praca domowa 2

## Projekt (55 pkt.)

Celem projektu jest zbudowanie jak najlepszego interpretowalnego modelu oraz porównanie go z modelem czarnej skrzynki.
W celu zbudowania bardzo dobrego modelu interpretowalnego powinna być zastosowana m.in.:
- selekcja cech
- inżynieria cech
- transformacje zmiennych
- analiza braków danych
- wiedza ekspercka
- wykorzystanie modelu czarnej skrzynki do budowy modelu interpretowalnego (np. PDP do transformacji zmiennych, metoda SAFE)

W projekcie należy przedstawić kolejne kroki - historię pokazującą ile do wyniku modelu wniosła np. inżynieria cech, potem ile wniosła imputacja danych, itd... . 
Na koniec powinno być zestawienie, że goły modelu interpretowalnego ma wynik A%, automL B%, a kolejne wersje modeli interpretowalnych mają C%, D% i tak dalej.

Końcowy model interpretowalny powininen być przynajmniej tak dobry jak model czarnej skrzynki (automl). W artykule należy przedstawić etapy pracy nad modelami oraz ich porówanie (wybranymi miarami służacymi do oceny jakości modeli).

Rezultatem prac powinien być krótki artykuł naukowy napisany w języku angielskim (40 pkt.), minimum 3 strony umieszczony jako rozdział książki online, która powstanie w ramach przedmiotu. Podział punktów w ramach artykułu
* Abstrakt: 5 pkt.
* Wstęp + Motywacja: 10 pkt
* Opis metodologii i wyników: 15 pkt.
* Wnioski: 10 pkt.

Projekt nalezy zaprezentować w postaci Lightning Talka na jednym z ostatnich wykładów (15 pkt.).

## Blog (15 pkt.)
Informacje w [repzytorium Wykładu](https://github.com/mini-pw/2020L-WarsztatyBadawcze)
