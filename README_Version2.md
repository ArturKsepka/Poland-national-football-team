# Poland-national-football-team

Portfolio analityka danych – Artur Ksepka

## Opis bazy danych

Repozytorium zawiera dane dotyczące międzynarodowych meczów piłkarskich różnych reprezentacji, zgromadzone w pliku **international matches**.  
Baza obejmuje spotkania polskiej reprezentacji oraz innych drużyn narodowych.

Główne kolumny w pliku:
- **Tournament** – nazwa turnieju lub rozgrywek
- **Date** – data rozegrania meczu
- **Home Team** – drużyna gospodarzy
- **Home Goals** – liczba bramek zdobytych przez gospodarzy
- **Away Goals** – liczba bramek zdobytych przez gości
- **Away Team** – drużyna gości
- **Home_Stadium** – wartość logiczna (true/false); określa, czy gospodarze grali na własnym stadionie (`true`), czy nie (`false`)

## Klasyfikacja meczów

W analizie mecze z udziałem Polski zostały sklasyfikowane według następujących zasad:

- Jeśli `home_team = 'Poland'` i `home_stadium = true`, Polska jest **gospodarzem**.
- Jeśli `away_team = 'Poland'`, Polska jest **gościem**.
- Jeśli `home_team = 'Poland'` i `home_stadium = false`, Polska jest **gościem**.

Dzięki temu każda analiza skuteczności polskiej reprezentacji uwzględnia, czy grała ona jako gospodarz, czy jako gość.

## Cel analizy

**Pytanie analityczne:**  
Czy polska reprezentacja gra lepiej będąc gospodarzem czy gościem, z uwzględnieniem siły przeciwnika?

W analizie wyodrębniono mecze z udziałem Polski i porównano jej wyniki jako gospodarza oraz jako gościa.By analiza była bardziej miarodajna, wyniki Polski są ważone siłą przeciwnika — wyliczaną jako średnia liczba goli zdobywanych przez każdy zespół.

## Metodyka

1. **Ranking przeciwników** – dla każdej drużyny obliczono średnią liczbę strzelonych goli na mecz jako gospodarz i jako gość, a następnie wyciągnięto średnią jako ranking siły zespołu.
2. **Ważenie zwycięstw** – każde zwycięstwo Polski (jako gospodarz lub gość) zostało pomnożone przez ranking siły przeciwnika, by określić "wartość" wygranej.
3. **Współczynniki zwycięstw** – wyliczono stosunek sumy wartości wygranych do sumy wartości wszystkich rozegranych meczów (osobno dla meczów domowych i wyjazdowych).

## Zapytanie SQL

### 1. Tworzenie rankingu siły drużyn na podstawie średniej liczby zdobytych goli na mecz

```sql
with home as (
    select
        home_team,
        round(sum(home_goals) / count(home_goals),2) as home_goals_per_match
    from international_matches
    group by 1
),
away as (
    select
        away_team,
        round(sum(away_goals) / count(away_goals),2) as away_goals_per_match
    from international_matches
    group by 1
),
ranking as (
    select 
        away_team as team,
        round((home_goals_per_match + away_goals_per_match)/2,2) as ranking
    from home h
    join away a on h.home_team = a.away_team
),
```

---

### 2. Wyznaczanie liczby wygranych meczów przez Polskę jako gospodarza z uwzględnieniem siły przeciwnika

```sql
home_wins as (
    select
        im.away_team,
        r.ranking,
        r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true' 
            and im.home_goals > im.away_goals then 1 else 0 end) as home_wins
    from international_matches im
    join ranking r on r.team = im.away_team
),
home_win_points as (
    select sum(home_wins) as home_win_points from home_wins
),
```

---

### 3. Wyznaczanie liczby rozegranych meczów przez Polskę jako gospodarza z uwzględnieniem siły przeciwnika

```sql
home_all as (
    select
        im.away_team,
        r.ranking,
        r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true'
            then 1 else 0 end) as home_all
    from international_matches im
    join ranking r on r.team = im.away_team
),
home_all_points as (
    select sum(home_all) as home_all_points from home_all
),
```

---

### 4. Wyznaczanie liczby wygranych meczów przez Polskę jako gościa z uwzględnieniem siły przeciwnika

```sql
away_wins_a as (
    select
        im.home_team,
        r.ranking * (case when im.away_team = 'poland' and im.away_goals > im.home_goals then 1 else 0 end) as away_wins_a,
        r.ranking
    from international_matches im
    join ranking r on im.home_team = r.team
),
away_win_points_a as (
    select sum(away_wins_a) as away_win_points_a from away_wins_a
),
away_wins_h as (
    select
        im.away_team,
        r.ranking * (case when im.home_team = 'poland' and im.home_goals > im.away_goals and im.home_stadium = 'false'
            then 1 else 0 end) as away_wins_h
    from international_matches im
    join ranking r on r.team = im.away_team
),
away_win_points_h as (
    select sum(away_wins_h) as away_win_points_h from away_wins_h
),
```

---

### 5. Wyznaczanie liczby rozegranych meczów przez Polskę jako gościa z uwzględnieniem siły przeciwnika

```sql
away_all_a as (
    select
        im.home_team,
        r.ranking * (case when im.away_team = 'poland' then 1 else 0 end) as away_all_a,
        r.ranking
    from international_matches im
    join ranking r on im.home_team = r.team
),
away_all_points_a as (
    select sum(away_all_a) as away_all_points_a from away_all_a
),
away_all_h as (
    select
        im.away_team,
        r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'false'
            then 1 else 0 end) as away_all_h
    from international_matches im
    join ranking r on r.team = im.away_team
),
away_all_points_h as (
    select sum(away_all_h) as away_all_points_h from away_all_h
)
```

---

### 6. Podsumowanie: ostateczne obliczenie współczynnika wygranych względem wszystkich rozegranych meczów (Polska jako gospodarz vs Polska jako gość)

```sql
select
    round(home_win_points / home_all_points,2) as home_win_ratio,
    round((away_win_points_a + away_win_points_h) / (away_all_points_a + away_all_points_h),2) as away_win_ratio
from away_all_points_h
cross join away_all_points_a
cross join away_win_points_h
cross join away_win_points_a
cross join home_win_points
cross join home_all_points;
```

## Wnioski

Wynik zapytania (`home_win_ratio` vs `away_win_ratio`) pokazuje, czy Polska wygrywa częściej (i z silniejszymi przeciwnikami) jako gospodarz czy gość.  
Pozwala to odpowiedzieć na pytanie, czy przewaga własnego boiska rzeczywiście przekłada się na lepsze wyniki reprezentacji Polski.

## Struktura repozytorium

- `/sql/poland_home_vs_away_weighted.sql` – zapytanie SQL do analizy
- `/dane/international_matches.csv` – plik źródłowy z danymi
- `README.md` – opis projektu

## Autor

Artur Ksepka  
LinkedIn: [https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page](https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page)  
Email: [Twój adres e-mail]