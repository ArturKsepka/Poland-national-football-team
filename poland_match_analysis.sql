with		/* ranking of countries based on goals scored per match to determine team strength */
home as 	/* calculate the ratio of goals scored to the number of matches for each team as the home team */
	(
	select
		home_team
		,round(sum(home_goals) / count(home_goals),2) 				as home_goals_per_match
	from international_matches
	group by 1
	),
away as 	/* calculate the ratio of goals scored to the number of matches for each team as the away team */
	(
	select
		away_team
		,round(sum(away_goals) / count(away_goals),2) 				as away_goals_per_match
	from international_matches
	group by 1
	order by 2 desc
	),
ranking as /* create a ranking by taking the average of goals scored per match as home and away team */
	(
	select 
		away_team 													as team
		,round((home_goals_per_match + away_goals_per_match)/2,2) 	as ranking
	from home h
	join away a on h.home_team = a.away_team
	),
home_wins as 			/* Poland's home wins considering the opponent's strength */
	(
	select
		im.away_team
		,r.ranking
		,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true' 
		and im.home_goals > im.away_goals then 1 else 0 end) 		as home_wins
	from international_matches im
	join ranking r on r.team = im.away_team
	),
home_win_points as 		/* total points from home wins */
	(
	select
	sum(home_wins) 													as home_win_points
		from home_wins
	),
home_all as 			/* all Poland’s home matches considering the opponent’s strength */
	(
	select
		im.away_team
		,r.ranking
		,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'true'
		then 1 else 0 end) 											as home_all
	from international_matches im
	join ranking r on r.team = im.away_team
	),
home_all_points as 		/* total points from all home matches considering the opponent’s strength */
	(
	select
	sum(home_all) 													as home_all_points
		 from home_all
	),
away_wins_a as			/* Poland's away wins (as away_team) considering the opponent’s strength */
	(
	select
		im.home_team 
		,r.ranking * (case when im.away_team = 'poland' and im.away_goals > im.home_goals then 1 else 0 end) as away_wins_a
		,r.ranking
	from international_matches im
	join ranking r on im.home_team = r.team
	),
away_win_points_a as 	/* total points from away wins (as away_team) */
	(
	select 
		sum(away_wins_a) 											as away_win_points_a
	from away_wins_a 		
	),
away_wins_h as 			/* Poland's away wins (as home_team but playing away) considering the opponent’s strength */
	(
	select
		im.away_team
		,r.ranking * (case when im.home_team = 'poland' and im.home_goals > im.away_goals and im.home_stadium = 'false'
		then 1 else 0 end) 											as away_wins_h
	from international_matches im
	join ranking r on r.team = im.away_team
	),
away_win_points_h as	/* total points from away wins (as home_team but playing away) */
	(
	select 
		sum(away_wins_h) 											as away_win_points_h
	from away_wins_h
	),
away_all_a as			/* all Poland’s away matches (as away_team) considering the opponent’s strength */
	(
	select
		im.home_team 
		,r.ranking * (case when im.away_team = 'poland' then 1 else 0 end) as away_all_a
		,r.ranking
	from international_matches im
	join ranking r on im.home_team = r.team
	),
away_all_points_a as	/* total points from all away matches (as away_team) considering the opponent’s strength */
	(
	select
		sum(away_all_a) 											as away_all_points_a
	from away_all_a
	),
away_all_h as 			/* all Poland’s away matches (as home_team but playing away) considering the opponent’s strength */
	(
	select
		im.away_team
		,r.ranking * (case when im.home_team = 'poland' and im.home_stadium = 'false'
		then 1 else 0 end) 											as away_all_h
	from international_matches im
	join ranking r on r.team = im.away_team
	),
away_all_points_h as	/* total points from all away matches (as home_team but playing away) considering the opponent’s strength */
	(
	select 
		sum(away_all_h) 											as away_all_points_h
	from away_all_h
	)
select 					/* comparison of Poland’s average win ratio at home vs away */
	round(home_win_points / home_all_points,2)						as home_win_ratio
	,round((away_win_points_a + away_win_points_h) / (away_all_points_a + away_all_points_h),2) as away_win_ratio
from away_all_points_h
cross join away_all_points_a
cross join away_win_points_h
cross join away_win_points_a
cross join home_win_points
cross join home_all_points
