

/* ============================================================
    DATABASE  : sports
    SCHEMA    : sports
   ============================================================ */
CREATE DATABASE sports;
CREATE SCHEMA SPORTS;
GO

/* ============================================================
   DATABASE  : sports
   PURPOSE   : Core OLTP schema for managing sports data
               including leagues, teams, players, and matches,
               plus staging tables for raw data ingestion.
   NOTE      : Comments below document purpose of each table,
               key columns, relationships, and staging usage.
   ============================================================ */

USE sports;
GO

/* ============================================================
   TABLE     : sports.leagues
   PURPOSE   : Master data for sports leagues.
               Each row represents a unique league (e.g., EPL, NBA).
   KEY FIELDS:
     - league_id   : Surrogate key, primary identifier.
     - league_name : Business name of the league.
   BUSINESS NOTES:
     - sport_type can be used to separate different sports
       (e.g., Football, Cricket, Basketball).
     - is_active indicates whether the league is currently in use.
     - created_at captures when the row was inserted.
   RELATIONSHIPS:
     - Referenced by:
         sports.teams.league_id
         sports.matches.league_id
   ============================================================ */

CREATE TABLE sports.leagues (
    league_id     INT           NOT NULL,                      -- PK: unique league identifier
    league_name   VARCHAR(100)  NOT NULL,                      -- League name
    country       VARCHAR(100)  NULL,                          -- Country/region of the league
    sport_type    VARCHAR(50)   NOT NULL,                      -- Type of sport (Football, Cricket, etc.)
    founded_year  INT           NULL,                          -- Year league was founded
    is_active     BIT           NOT NULL DEFAULT (1),          -- 1 = active, 0 = inactive
    created_at    DATETIME2(7)  NOT NULL DEFAULT SYSUTCDATETIME(), -- UTC creation timestamp

    CONSTRAINT PK_leagues PRIMARY KEY (league_id)
);
GO


/* ============================================================
   TABLE     : sports.matches
   PURPOSE   : Stores match-level information such as date,
               teams involved, scores, and attendance.
   KEY FIELDS:
     - match_id    : Surrogate key, primary identifier for each match.
   BUSINESS NOTES:
     - league_id links the match to a specific league and season.
     - home_team_id and away_team_id distinguish the two sides.
     - match_status can capture states like 'Scheduled',
       'In Progress', 'Completed', 'Postponed'.
     - attendance records the number of spectators (if known).
     - created_at is the UTC timestamp of when the match record
       was inserted into the system.
   DATA QUALITY:
     - CK_matches_home_away_diff ensures home_team_id != away_team_id
       to avoid a team playing itself.
   RELATIONSHIPS:
     - league_id     -> sports.leagues.league_id
     - home_team_id  -> sports.teams.team_id
     - away_team_id  -> sports.teams.team_id
   ============================================================ */

CREATE TABLE sports.matches (
    match_id      INT           NOT NULL,                      -- PK: unique match identifier
    league_id     INT           NOT NULL,                      -- FK -> leagues.league_id
    season        VARCHAR(20)   NOT NULL,                      -- Season identifier (e.g., '2024-2025')
    match_date    DATE          NOT NULL,                      -- Match date
    home_team_id  INT           NOT NULL,                      -- FK -> teams.team_id (home)
    away_team_id  INT           NOT NULL,                      -- FK - teams.team_id (away)
    home_score    INT           NULL,                          -- Home team score
    away_score    INT           NULL,                          -- Away team score
    stadium       VARCHAR(100)  NULL,                          -- Stadium where match is played
    match_status  VARCHAR(20)   NOT NULL DEFAULT ('Completed'),-- e.g., 'Scheduled', 'Completed'
    attendance    INT           NULL,                          -- Number of spectators
    created_at    DATETIME2(7)  NOT NULL DEFAULT SYSUTCDATETIME(), -- UTC creation timestamp

    CONSTRAINT PK_matches PRIMARY KEY (match_id),
    CONSTRAINT FK_matches_leagues FOREIGN KEY (league_id)
        REFERENCES sports.leagues (league_id),
    CONSTRAINT FK_matches_home_team FOREIGN KEY (home_team_id)
        REFERENCES sports.teams (team_id),
    CONSTRAINT FK_matches_away_team FOREIGN KEY (away_team_id)
        REFERENCES sports.teams (team_id),
    CONSTRAINT CK_matches_home_away_diff CHECK (home_team_id <> away_team_id) -- prevent same team vs itself
);
GO



/* ============================================================
   TABLE     : sports.players
   PURPOSE   : Master data for players.
               Each row represents an individual player and
               captures personal and football-related attributes.
   KEY FIELDS:
     - player_id : Surrogate key for the player.
   BUSINESS NOTES:
     - team_id links a player to their current team.
     - date_of_birth is useful for age-based analytics.
     - jersey_number is optional; may be NULL if not assigned.
     - is_active can indicate currently playing vs retired.
     - created_at is the UTC creation timestamp.
   RELATIONSHIPS:
     - team_id -> sports.teams.team_id
   ============================================================ */

CREATE TABLE sports.players (
    player_id     INT           NOT NULL,                      -- PK: unique player identifier
    team_id       INT           NOT NULL,                      -- FK -> teams.team_id
    first_name    VARCHAR(100)  NOT NULL,                      -- Player first name
    last_name     VARCHAR(100)  NOT NULL,                      -- Player last name
    position      VARCHAR(50)   NULL,                          -- Playing position (e.g., Forward, GK)
    nationality   VARCHAR(100)  NULL,                          -- Country of the player
    date_of_birth DATE          NULL,                          -- Date of birth
    jersey_number INT           NULL,                          -- Shirt number
    is_active     BIT           NOT NULL DEFAULT (1),          -- 1 = active, 0 = inactive/retired
    created_at    DATETIME2(7)  NOT NULL DEFAULT SYSUTCDATETIME(), -- UTC creation timestamp

    CONSTRAINT PK_players PRIMARY KEY (player_id),
    CONSTRAINT FK_players_teams FOREIGN KEY (team_id)
        REFERENCES sports.teams (team_id)
);
GO


/* ============================================================
   TABLE     : sports.teams
   PURPOSE   : Master data for teams/clubs.
               Each row represents a team that participates
               in one of the leagues.
   KEY FIELDS:
     - team_id   : Surrogate key for the team.
   BUSINESS NOTES:
     - league_id associates the team with a particular league.
     - city and stadium provide location context.
     - founded_year captures historical establishment.
     - is_active indicates whether the team is currently
       participating or available in the system.
     - created_at is the UTC timestamp of creation.
   RELATIONSHIPS:
     - league_id -> sports.leagues.league_id
     - Referenced by:
         sports.players.team_id
         sports.matches.home_team_id
         sports.matches.away_team_id
   ============================================================ */

CREATE TABLE sports.teams (
    team_id       INT           NOT NULL,                      -- PK: unique team identifier
    league_id     INT           NOT NULL,                      -- FK -> leagues.league_id
    team_name     VARCHAR(100)  NOT NULL,                      -- Official team name
    city          VARCHAR(100)  NULL,                          -- Home city of the team
    stadium       VARCHAR(100)  NULL,                          -- Home stadium
    founded_year  INT           NULL,                          -- Year the team was founded
    is_active     BIT           NOT NULL DEFAULT (1),          -- 1 = active, 0 = inactive
    created_at    DATETIME2(7)  NOT NULL DEFAULT SYSUTCDATETIME(), -- UTC creation timestamp

    CONSTRAINT PK_teams PRIMARY KEY (team_id),
    CONSTRAINT FK_teams_leagues FOREIGN KEY (league_id)
        REFERENCES sports.leagues (league_id)
);
GO




/* ============================================================
   STAGING TABLES OVERVIEW
   PURPOSE   :
     - Used as a landing area for raw data (e.g., from CSV, API).
     - Keep incoming data flexible by storing many fields as
       VARCHAR (even if final type is DATE or BIT).
     - Allow data quality checks, transformations, and mappings
       BEFORE loading into the main production tables.

   COMMON PATTERNS:
     - is_active stored as VARCHAR to accommodate variants like
       'Yes/No', 'True/False', '1/0'.
     - date fields stored as VARCHAR and later converted with
       TRY_CONVERT or similar in ETL logic.
     - No primary keys or foreign keys -> makes ingestion tolerant
       to bad or duplicate data; validations are done in ETL.

   USAGE:
     1. Load raw data into *_stg tables.
     2. Run validation / transformation logic.
     3. Insert / MERGE cleaned rows into main tables.
     4. Optionally archive or truncate staging tables after load.
   ============================================================ */

USE sports;
GO


/* ============================================================
   TABLE     : sports.leagues_stg
   PURPOSE   : Staging version of sports.leagues.
               Holds raw league data prior to validation and
               type conversion.
   COLUMN NOTES:
     - is_active is VARCHAR to accept any textual representation
       from the source; later mapped to BIT in sports.leagues.
   ============================================================ */

DROP TABLE IF EXISTS sports.leagues_stg;

CREATE TABLE sports.leagues_stg (
    league_id      INT,           -- Raw league identifier
    league_name    VARCHAR(100),  -- Raw league name
    country        VARCHAR(100),  -- Raw country name/text
    sport_type     VARCHAR(50),   -- Raw sport type text
    founded_year   INT,           -- Raw founded year
    is_active      VARCHAR(50)    -- Raw active flag as text (e.g., 'Yes', '1', 'True')
);


/* ============================================================
   TABLE     : sports.teams_stg
   PURPOSE   : Staging version of sports.teams.
               Used to ingest raw team data before cleaning
               and enforcing referential integrity.
   COLUMN NOTES:
     - league_id is not enforced as FK here; the ETL process
       should validate existence against sports.leagues.
     - is_active remains VARCHAR for flexible source formats.
   ============================================================ */

DROP TABLE IF EXISTS sports.teams_stg;

CREATE TABLE sports.teams_stg (
    team_id        INT,           -- Raw team identifier
    league_id      INT,           -- Raw reference to league
    team_name      VARCHAR(100),  -- Raw team name
    city           VARCHAR(100),  -- Raw city name
    stadium        VARCHAR(100),  -- Raw stadium name
    founded_year   INT,           -- Raw founded year
    is_active      VARCHAR(50)    -- Raw active flag as text
);


/* ============================================================
   TABLE     : sports.players_stg
   PURPOSE   : Staging version of sports.players.
               Holds raw player records from source systems.
   COLUMN NOTES:
     - date_of_birth is VARCHAR to allow heterogeneous date
       string formats; converted to DATE during ETL.
     - is_active as VARCHAR to accommodate multiple source
       encodings for active/inactive flags.
   ============================================================ */

DROP TABLE IF EXISTS sports.players_stg;

CREATE TABLE sports.players_stg (
    player_id      INT,           -- Raw player identifier
    team_id        INT,           -- Raw team reference
    first_name     VARCHAR(100),  -- Raw first name
    last_name      VARCHAR(100),  -- Raw last name
    position       VARCHAR(50),   -- Raw playing position
    nationality    VARCHAR(100),  -- Raw nationality text
    date_of_birth  VARCHAR(50),   -- Raw date text, to be converted to DATE
    jersey_number  INT,           -- Raw jersey number
    is_active      VARCHAR(50)    -- Raw active flag as text
);


/* ============================================================
   TABLE     : sports.matches_stg
   PURPOSE   : Staging version of sports.matches.
               Used for loading raw match data before applying
               validations (dates, FKs, scores, etc.).
   COLUMN NOTES:
     - match_date is VARCHAR to support multiple raw date formats
       and later converted to DATE in sports.matches.
     - match_status stored as VARCHAR, later validated against
       expected statuses in ETL logic.
   ============================================================ */

DROP TABLE IF EXISTS sports.matches_stg;

CREATE TABLE sports.matches_stg (
    match_id           INT,           -- Raw match identifier
    league_id          INT,           -- Raw league reference
    season             VARCHAR(20),   -- Raw season text
    match_date         VARCHAR(50),   -- Raw date text, to be converted to DATE
    home_team_id       INT,           -- Raw home team reference
    away_team_id       INT,           -- Raw away team reference
    home_score         INT,           -- Raw home score
    away_score         INT,           -- Raw away score
    stadium            VARCHAR(100),  -- Raw stadium name
    match_status       VARCHAR(20),   -- Raw match status text
    attendance         INT            -- Raw attendance figure
);
GO











