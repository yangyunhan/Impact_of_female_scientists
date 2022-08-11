-- RESET MASTER;

SHOW VARIABLES LIKE '%innodb_buffer_pool_size%';
SET GLOBAL innodb_buffer_pool_size=2147483648;

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile=1;
LOAD DATA LOCAL INFILE '/Volumes/One\ Touch/MAG_data/PaperReference/xar' INTO TABLE paper_reference_xar;
SHOW VARIABLES LIKE '%secure%';

-- previous eight female domain fields
-- 20625102 Corrosion
-- 2778019345 Hepatocellular carcinoma
-- 28858896 Special education
-- 502991105 Clinical research
-- 2779726688 Mast cell
-- 2778576202 Sample preparation
-- 137270730 Detection theory
-- 2778707650 P glycoprotein 3

SELECT * FROM field_of_study WHERE field_id='2778707650';

CREATE TABLE p_glycoprotein_paper_id AS
SELECT DISTINCT paper_id FROM paper_field_a_ab WHERE field_id='2778707650' AND score>0;

DELETE FROM sample_preparation_paper_id WHERE paper_id IN (
	SELECT DISTINCT paper_id FROM paper_field_a_cd WHERE field_id='137270730' AND score>0;
)

SELECT COUNT(*) FROM sample_preparation_paper_id;
-- 52401 

INSERT INTO gender_0_7 (paper_id, author_id, gender)
SELECT * FROM gender_8_15_60_61;

SELECT * FROM paper WHERE paper_id='2953327271';

DROP PROCEDURE _Navicat_Temp_Stored_Proc;

SELECT COUNT(*) FROM corrosion_paper_id;

CREATE TABLE paper_reference_ab AS
SELECT * FROM paper_reference;

SELECT * FROM paper_reference_xaa_2 WHERE paper_reference_id='2243522839'
CREATE TABLE paper_reference_xaa_2 AS SELECT * FROM paper_reference_xaa;

UPDATE paper_reference_xar SET paper_reference_id = REPLACE(paper_reference_id, char(13), '');

SELECT * FROM paper_reference_xa_e WHERE paper_reference_id='643248926';

SELECT COUNT(*) FROM special_education_paper;

CREATE TABLE special_education_paper AS
SELECT paper_id, `year`, citation_count, citation_5years FROM paper WHERE paper_id IN (SELECT paper_id FROM special_education_paper_id);

SELECT * FROM paper_reference WHERE paper_reference_id='102353022';

SELECT COUNT(DISTINCT paper_id) FROM clinical_research_author;

SELECT * FROM paper WHERE paper_id='2090683065';

SELECT COUNT(*) FROM clinical_research_paper_id;

SELECT * FROM clinical_research_author WHERE paper_id='2798188958';

SELECT COUNT(paper_id) FROM clinical_research_paper;

SELECT MIN(`year`) FROM clinical_research_paper;

CREATE TABLE special_education_author AS
SELECT paper_id, author_id, gender FROM gender_0_7 WHERE paper_id IN (SELECT paper_id FROM special_education_paper_id);

INSERT INTO special_education_author (paper_id, author_id, gender)
SELECT paper_id, author_id, gender FROM gender_48_55 WHERE paper_id IN (SELECT paper_id FROM special_education_paper_id);

SELECT COUNT(DISTINCT author_id) FROM p_glycoprotein_author;

SELECT MIN(`year`), MAX(`year`) FROM p_glycoprotein_paper;

SELECT * FROM corrosion_author WHERE paper_id IN (
	SELECT paper_id FROM corrosion_paper WHERE `year`=0
)

SELECT * FROM paper WHERE paper_id='228214609';

CREATE TABLE special_education_paper_author AS
SELECT p.paper_id, p.`year`, p.citation_count, p.citation_5years, a.author_id, a.gender 
FROM special_education_paper p JOIN special_education_author a ON p.paper_id=a.paper_id AND (a.gender LIKE '%male%' OR a.gender LIKE '%female%');

SELECT COUNT(DISTINCT author_id) FROM special_education_paper_author;
SELECT COUNT(DISTINCT author_id) FROM special_education_author;
SELECT COUNT(DISTINCT author_id) FROM clinical_research_paper_author;

SELECT 
	COUNT(DISTINCT author_id) AS author_number, -- 28234
	COUNT(DISTINCT IF(gender='male' OR gender='mostly_male',author_id,NULL)) AS male_num, -- 16724
	COUNT(DISTINCT IF(gender='female' OR gender='mostly_female',author_id,NULL)) AS female_num, -- 11510
	COUNT(IF(gender='male' OR gender='mostly_male', paper_id, NULL)) AS male_prod, -- 20995
	COUNT(IF(gender='female' OR gender='mostly_female', paper_id, NULL)) AS female_prod, -- 13751
	SUM(IF(gender='male' OR gender='mostly_male', citation_count, 0)) AS male_citation, -- 687216
	SUM(IF(gender='female' OR gender='mostly_female', citation_count, 0)) AS female_citation -- 335679
FROM special_education_paper_author;

CREATE TABLE special_education_author_pro_impact AS
SELECT b.author_id, a.gender, b.career_length, b.paper_count, b.citations 
FROM special_education_paper_author a JOIN (
	SELECT 
		author_id,
		MAX(`year`)-MIN(`year`)+1 AS career_length,
		COUNT(DISTINCT paper_id) AS paper_count,
		SUM(citation_count) AS citations
	FROM special_education_paper_author GROUP BY author_id
) AS b ON a.author_id=b.author_id;


-- author_id, gender, career_length, paper_count, citations
CREATE TABLE special_education_author_pro_impact2 AS
SELECT * FROM special_education_author_pro_impact WHERE career_length>1;

SELECT 
	COUNT(author_id) AS author_num,
	COUNT(IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	SUM(IF(gender='male' OR gender='mostly_male', paper_count, 0)) AS male_prod,
	SUM(IF(gender='female' OR gender='mostly_female', paper_count, 0)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM special_education_author_pro_impact2;
	
