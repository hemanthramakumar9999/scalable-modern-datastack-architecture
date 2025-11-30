USE sports;
GO

/* ================================================================
   BULK LOADING SECTION
   Purpose:
     - Load raw CSV files directly into *_stg tables.
     - These staging tables have flexible datatypes (mostly VARCHAR)
       allowing ingestion of unclean or inconsistent source data.
   Notes:
     - FIRSTROW = 2 skips header row.
     - FIELDTERMINATOR is comma since files are CSV.
     - ROWTERMINATOR set to '0x0d0a' for Windows CRLF.
     - MAXERRORS allows limited bad rows without failing entire load.
   ================================================================ */


---------------------------------------------------------------
-- LOAD leagues.csv -> leagues_stg
---------------------------------------------------------------
BULK INSERT sports.leagues_stg
FROM 'C:\Users\heman\Downloads\sample_data_files\leagues.csv'
WITH (
    FIRSTROW = 2,              -- skip header
    FIELDTERMINATOR = ',',     -- fields separated by comma
    ROWTERMINATOR = '0x0d0a',  -- Windows-style line ending
    TABLOCK,
    MAXERRORS = 1000           -- allow limited load errors
);


---------------------------------------------------------------
-- LOAD teams.csv -> teams_stg
---------------------------------------------------------------
BULK INSERT sports.teams_stg
FROM 'C:\Users\heman\Downloads\sample_data_files\teams.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK,
    MAXERRORS = 1000
);


---------------------------------------------------------------
-- LOAD players.csv -> players_stg
---------------------------------------------------------------
BULK INSERT sports.players_stg
FROM 'C:\Users\heman\Downloads\sample_data_files\players.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK,
    MAXERRORS = 1000
);


---------------------------------------------------------------
-- LOAD matches.csv -> matches_stg
---------------------------------------------------------------
BULK INSERT sports.matches_stg
FROM 'C:\Users\heman\Downloads\sample_data_files\matches.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK,
    MAXERRORS = 1000
);
GO



/* =====================================================================
   DATA LOAD FROM STAGING -> FINAL TABLES
   Purpose:
     - Convert raw text into the correct datatypes.
     - Apply default values, basic cleansing, and transformations.
     - Map raw is_active text (Yes/No/True/False/1/0) into BIT values.
     - Convert date text to DATE using TRY_CONVERT().
   Notes:
     - These INSERT statements assume NO duplicates in STG.
     - If duplicates exist, MERGE should be used instead.
   ===================================================================== */


/* ------------------------------------------------------------
   INSERT: leagues_stg -> leagues
   Cleansing Performed:
     - Convert is_active VARCHAR to BIT using CASE mapping.
   ------------------------------------------------------------ */
INSERT INTO sports.leagues (
    league_id,
    league_name,
    country,
    sport_type,
    founded_year,
    is_active
)
SELECT
    league_id,
    league_name,
    country,
    sport_type,
    founded_year,
    CASE 
        WHEN LTRIM(RTRIM(is_active)) IN ('1','Y','Yes','YES','True','TRUE','true')
             THEN 1
        ELSE 0
    END AS is_active
FROM sports.leagues_stg;



/* ------------------------------------------------------------
   INSERT: teams_stg -> teams
   Cleansing Performed:
     - Map raw is_active -> BIT
     - Assumes foreign keys (league_id) already valid.
   ------------------------------------------------------------ */
INSERT INTO sports.teams (
    team_id,
    league_id,
    team_name,
    city,
    stadium,
    founded_year,
    is_active
)
SELECT
    team_id,
    league_id,
    team_name,
    city,
    stadium,
    founded_year,
    CASE 
        WHEN LTRIM(RTRIM(is_active)) IN ('1','Y','Yes','YES','True','TRUE','true')
             THEN 1
        ELSE 0
    END AS is_active
FROM sports.teams_stg;



/* ------------------------------------------------------------
   INSERT: players_stg -> players
   Cleansing Performed:
     - Convert date_of_birth from text -> DATE using TRY_CONVERT.
     - Convert is_active to BIT.
     - Handles NULL or wrongly formatted dates safely.
   ------------------------------------------------------------ */
INSERT INTO sports.players (
    player_id,
    team_id,
    first_name,
    last_name,
    position,
    nationality,
    date_of_birth,
    jersey_number,
    is_active
)
SELECT
    player_id,
    team_id,
    first_name,
    last_name,
    position,
    nationality,
    TRY_CONVERT(DATE, date_of_birth, 120),  -- Safe conversion from text
    jersey_number,
    CASE 
        WHEN LTRIM(RTRIM(is_active)) IN ('1','Y','Yes','YES','True','TRUE','true')
             THEN 1
        ELSE 0
    END AS is_active
FROM sports.players_stg;



/* ------------------------------------------------------------
   INSERT: matches_stg -> matches
   Cleansing Performed:
     - Convert match_date VARCHAR -> DATE
     - No is_active field in matches; direct load.
     - Assumes foreign keys (team/league) must exist in final tables.
   ------------------------------------------------------------ */
INSERT INTO sports.matches (
    match_id,
    league_id,
    season,
    match_date,
    home_team_id,
    away_team_id,
    home_score,
    away_score,
    stadium,
    match_status,
    attendance
)
SELECT
    match_id,
    league_id,
    season,
    TRY_CONVERT(DATE, match_date, 120),  -- convert raw date text -> DATE
    home_team_id,
    away_team_id,
    home_score,
    away_score,
    stadium,
    match_status,
    attendance
FROM sports.matches_stg;
GO
