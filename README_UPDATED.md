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

1. **Opponent Ranking** – for each team, offensive strength was calculated as the average number of goals scored per match (separately as home and away team), and defensive strength as the average number of goals conceded per match (also separately as home and away team).
The team’s ranking was then computed as the difference between offensive and defensive strength.
To avoid negative values, if the result of this difference was below zero, it was set to 0, and 1 was added to every value.
As a result, Poland receives 1 point for a win against a very weak opponent, and more points for stronger rivals, e.g. 2.27 points for a win against England.
2. **Weighted Victories** – each Polish victory (at home or away) was multiplied by the opponent's strength ranking to determine the "value" of the win.
3. **Win Ratios** – the ratio of the sum of weighted victories to the sum of all matches played (separately for home and away matches) was calculated.

## SQL Query

### 1. Creating team strength ranking based on offensive minus defensive strength

```sql
WITH
-- 1) Average goals scored (home/away)
home_scored AS (
  SELECT
    lower(home_team) AS team,
    AVG(home_goals)::numeric(10,4) AS gpm_home_scored
  FROM international_matches
  GROUP BY 1
),
away_scored AS (
  SELECT
    lower(away_team) AS team,
    AVG(away_goals)::numeric(10,4) AS gpm_away_scored
  FROM international_matches
  GROUP BY 1
),

-- 2) Offensive strength (higher = better)
ranking_win AS (
  SELECT
    h.team,
    ROUND( (h.gpm_home_scored + a.gpm_away_scored) / 2.0 , 2) AS ranking_win
  FROM home_scored h
  JOIN away_scored a USING (team)
),

-- 3) Average goals conceded (home/away)
home_conceded AS (
  SELECT
    lower(home_team) AS team,
    AVG(away_goals)::numeric(10,4) AS gpm_home_conceded
  FROM international_matches
  GROUP BY 1
),
away_conceded AS (
  SELECT
    lower(away_team) AS team,
    AVG(home_goals)::numeric(10,4) AS gpm_away_conceded
  FROM international_matches
  GROUP BY 1
),

-- 4) Defensive strength (lower = better)
ranking_lost AS (
  SELECT
    h.team,
    ROUND( (h.gpm_home_conceded + a.gpm_away_conceded) / 2.0 , 2) AS ranking_lost
  FROM home_conceded h
  JOIN away_conceded a USING (team)
),

-- 5) Final team ranking = 1 + max(offense - defense, 0)
ranking AS (
  SELECT
    w.team,
    1 + GREATEST( (w.ranking_win - l.ranking_lost), 0 ) AS ranking
  FROM ranking_win w
  JOIN ranking_lost l USING (team)
)
SELECT * FROM ranking ORDER BY ranking DESC;
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

- `poland_match_analysis.sql` – SQL query for analysis
- `international_matches.csv` – source data file
- `README.md` – project description

## Results

The final query returned the following values:

| Metric | Value |
|:--|:--:|
| **Home Win Ratio** | **0.43** |
| **Away Win Ratio** | **0.29** |

### Interpretation

Poland’s weighted home win ratio (0.43) is noticeably higher than the away win ratio (0.29).  
This indicates that the Polish national team performs significantly better when playing **at home**, even after adjusting for the relative strength of opponents.  
In other words, **home advantage** clearly translates into better results for the Polish team.

## Author

Artur Ksepka  
LinkedIn: [https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page](https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page)
