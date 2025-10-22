with                            /* team-strength ranking: offensive minus defensive */
home_win as                     /* average goals scored by each team as the home side */
    (
    select
        home_team
        ,sum(home_goals) / count(*)										as home_goals_per_match
    from international_matches
    group by 1
    ),
away_win as                     /* average goals scored by each team as the away side */
    (
    select
        away_team
        ,sum(away_goals) / count(*)										as away_goals_per_match
    from international_matches
    group by 1
    ),
ranking_win as                  /* offensive strength ranking (higher = stronger) */
    (
    select 
        away_team														as team
        ,(home_goals_per_match + away_goals_per_match)/2				as ranking_win
    from home_win h
    join away_win a on h.home_team = a.away_team
    ),
home_lost as                    /* average goals conceded when the team plays at home */
    (
    select
        home_team 
        ,sum(away_goals) / count(*)										as home_lost_goals
    from international_matches
    group by 1
    ),
away_lost as                    /* average goals conceded when the team plays away */
    (
    select
        away_team
        ,sum(home_goals) / count(*)										as away_lost_goals
    from international_matches
    group by 1
    ),
ranking_lost as                 /* defensive strength ranking (lower = stronger) */
    (
    select 
        away_team														as team
        ,(home_lost_goals + away_lost_goals)/2            				as ranking_lost
    from home_lost h
    join away_lost a on h.home_team = a.away_team
    ),
ranking as                      /* final team strength = 1 + max(offense - defense, 0) */
    (
    select 
        w.team
        ,round(1 + case when (w.ranking_win - l.ranking_lost) < 0        /* floor at 1 for negative values */
              then 0 else (w.ranking_win - l.ranking_lost) end,2)		as ranking
    from ranking_lost l
    join ranking_win w on l.team = w.team 
    ),
home_win_points as              /* Poland's weighted home wins (opponent strength applied) */
    (
    select
        sum(home_wins)													as home_win_points
    from 
        (
        select 
            im.away_team
            ,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true' 
                              and im.home_goals > im.away_goals then 1 
                              else 0 end) 								as home_wins
        from international_matches im
        join ranking r on r.team = im.away_team
        ) h
    ),
home_all_points as              /* total Poland home matches (weighted by opponent strength) */
    (
    select
        sum(home_all)													as home_all_points
    from 
        (
        select
            im.away_team
            ,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true'
                              then 1 else 0 end)						as home_all
        from international_matches im
        join ranking r on r.team = im.away_team
        ) h
    ),
away_win_points_a as            /* Poland's away wins from the away_team perspective (weighted) */
    (
    select 
        sum(away_wins_a)												as away_win_points_a
    from 
        (
        select
            im.home_team 
            ,r.ranking * (case when im.away_team = 'poland' and im.away_goals > im.home_goals
                               then 1 else 0 end)						as away_wins_a
        from international_matches im
        join ranking r on im.home_team = r.team
        ) a
    ),
away_win_points_h as            /* Poland's away wins from the home_team perspective (weighted) */
    (
    select 
        sum(away_wins_h)												as away_win_points_h
    from 
        (
        select
            im.away_team
            ,r.ranking * (case when im.home_team = 'poland' and im.home_goals > im.away_goals and im.home_stadium = 'false'
                               then 1 else 0 end)						as away_wins_h
        from international_matches im
        join ranking r on r.team = im.away_team
        ) h
    ),
away_all_points_a as            /* total Poland away matches from the away_team perspective (weighted) */
    (
    select
        sum(away_all_a)													as away_all_points_a
    from 
        (
        select
            im.home_team 
            ,r.ranking * (case when im.away_team = 'poland' 
                               then 1 else 0 end)						as away_all_a
        from international_matches im
        join ranking r on im.home_team = r.team
        ) a
    ),
away_all_points_h as            /* total Poland away matches from the home_team perspective (weighted) */
    (
    select 
        sum(away_all_h)													as away_all_points_h
    from (
        select        
            im.away_team
            ,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'false'
                               then 1 else 0 end)						as away_all_h
        from international_matches im
        join ranking r on r.team = im.away_team
        ) h
    )
select                          /* comparison: weighted win ratios for Poland — home vs away */
    round(home_win_points / home_all_points,2)							as home_win_ratio
    ,round((away_win_points_a + away_win_points_h) / (away_all_points_a + away_all_points_h),2) as away_win_ratio
from away_all_points_h
cross join away_all_points_a
cross join away_win_points_h
cross join away_win_points_a
cross join home_win_points
cross join home_all_points;
