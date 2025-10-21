# Poland-national-football-team

Data Analytics Portfolio – Artur Ksepka

## Database Description

This repository contains data on international football matches between various national teams, collected in the **international matches** file.  
The dataset includes matches played by the Polish national team as well as other national teams.

Main columns in the file:
- **Tournament** – name of the tournament or competition
- **Date** – date the match was played
- **Home Team** – home team
- **Home Goals** – number of goals scored by the home team
- **Away Goals** – number of goals scored by the away team
- **Away Team** – away team
- **Home_Stadium** – boolean value (true/false); indicates whether the home team played at their own stadium (`true`) or not (`false`)

## Match Classification

In the analysis, matches involving Poland were classified according to the following rules:

- If `home_team = 'Poland'` and `home_stadium = true`, Poland is the **home team**.
- If `away_team = 'Poland'`, Poland is the **away team**.
- If `home_team = 'Poland'` and `home_stadium = false`, Poland is the **away team**.

This ensures that every analysis of Poland's performance takes into account whether the team played as host or guest.

## Purpose of Analysis

**Analytical Question:**  
Does the Polish national team perform better at home or away, considering the strength of the opponent?

The analysis focuses on matches involving Poland and compares their results as the home team and as the away team.  
To make the analysis more reliable, Poland's results are weighted by the strength of the opponent — calculated as the average number of goals scored by each team.

## Methodology

1. **Opponent Ranking** – for each team, the average number of goals scored per match as a home team and as an away team was calculated, and then the average was taken as the team's strength ranking.
2. **Weighted Victories** – each Polish victory (at home or away) was multiplied by the opponent's strength ranking to determine the "value" of the win.
3. **Win Ratios** – the ratio of the sum of weighted victories to the sum of all matches played (separately for home and away matches) was calculated.

## SQL Query

### 1. Creating team strength ranking based on average goals per match

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

### 2. Calculating number of matches won by Poland as home team, weighted by opponent strength

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

### 3. Calculating number of matches played by Poland as home team, weighted by opponent strength

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

### 4. Calculating number of matches won by Poland as away team, weighted by opponent strength

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

### 5. Calculating number of matches played by Poland as away team, weighted by opponent strength

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

### 6. Summary: final calculation of win ratios for all matches played (Poland as home team vs Poland as away team)

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

## Conclusions

The result of the query (`home_win_ratio` vs `away_win_ratio`) shows whether Poland wins more often (and against stronger opponents) as the home team or away team.  
This allows us to answer the question of whether home advantage really translates into better results for the Polish national team.

## Repository Structure

- `/sql/poland_home_vs_away_weighted.sql` – SQL query for analysis
- `/dane/international_matches.csv` – source data file
- `README.md` – project description

## Author

Artur Ksepka  
LinkedIn: [https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page](https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page)
