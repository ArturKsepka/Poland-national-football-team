# Poland-national-football-team

**Data Analytics Portfolio – Artur Ksepka**

---

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

---

## Match Classification

In the analysis, matches involving Poland were classified according to the following rules:

- If `home_team = 'Poland'` and `home_stadium = true`, Poland is the **home team**.  
- If `away_team = 'Poland'`, Poland is the **away team**.  
- If `home_team = 'Poland'` and `home_stadium = false`, Poland is the **away team**.

This ensures that every analysis of Poland's performance takes into account whether the team played as host or guest.

---

## Purpose of Analysis

**Analytical Question:**  
Does the Polish national team perform better at home or away, considering the strength of the opponent?

The analysis focuses on matches involving Poland and compares their results as the home team and as the away team.  
To make the analysis more reliable, Poland's results are weighted by the strength of the opponent — calculated as the average number of goals scored by each team.

---

## Methodology

1. **Opponent Ranking** – for each team, the average number of goals scored per match as a home team and as an away team was calculated, and then the average was taken as the team's strength ranking.  
2. **Weighted Victories** – each Polish victory (at home or away) was multiplied by the opponent's strength ranking to determine the "value" of the win.  
3. **Win Ratios** – the ratio of the sum of weighted victories to the sum of all matches played (separately for home and away matches) was calculated.

---

## SQL Query

The full query used to calculate the weighted win ratios can be found in  
[`/sql/poland_home_vs_away_weighted.sql`](./sql/poland_home_vs_away_weighted.sql)

*(The detailed SQL steps are included in the previous version of the README.)*

---

## Results

The final query returned the following values:

| Metric | Value |
|:--|:--:|
| **Home Win Ratio (weighted)** | **0.43** |
| **Away Win Ratio (weighted)** | **0.29** |

### Interpretation

Poland’s weighted home win ratio (0.43) is noticeably higher than the away win ratio (0.29).  
This indicates that the Polish national team performs significantly better when playing **at home**, even after adjusting for the relative strength of opponents.  
In other words, **home advantage** clearly translates into better results for the Polish team.

---

## Conclusions

The result of the query (`home_win_ratio` vs `away_win_ratio`) shows whether Poland wins more often (and against stronger opponents) as the home team or away team.  
This allows us to answer the question of whether home advantage really translates into better results for the Polish national team.

---

## Repository Structure

- `/sql/poland_home_vs_away_weighted.sql` – SQL query for analysis  
- `/dane/international_matches.csv` – source data file  
- `README.md` – project description

---

## Author

**Artur Ksepka**  
📎 [LinkedIn](https://www.linkedin.com/in/artur-ksepka-77b3ba180/?trk=public-profile-join-page)  
📧 Email: [Your email address]
