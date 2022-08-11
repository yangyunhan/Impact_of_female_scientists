-- 删除log文件
RESET MASTER;

-- 改变缓存的空间大小
SHOW VARIABLES LIKE "%_buffer%";
SET GLOBAL innodb_buffer_pool_size=1073741824;

-- 筛选和合并所有原数据中有性别识别的作者数据
CREATE TABLE author AS
SELECT * FROM gender_0_7 WHERE gender='male' OR gender='mostly_male' OR gender='female' OR gender='mostly_female'

INSERT INTO author (paper_id, author_id, gender)
SELECT * FROM gender_48_55 WHERE gender='male' OR gender='mostly_male' OR gender='female' OR gender='mostly_female'

-- 检查某个level的field
SELECT * FROM field_of_study WHERE `level`=2;

-- 筛选level 1 的field的信息：field_id, normalized_name, citation_count
CREATE TABLE level_1_fields AS
SELECT field_id, normalized_name, citation_count FROM field_of_study WHERE `level`=1;

-- 通过paper_id, field_id的对应关系找到level 1 中的所有paper_id，paper_field是分表处理
CREATE TABLE level_1_paper_id AS
SELECT field_id, paper_id FROM paper_field_a_ab WHERE field_id IN (SELECT field_id FROM level_1_fields) AND score>0;

INSERT INTO level_1_paper_id (field_id, paper_id)
SELECT field_id, paper_id FROM paper_field_b_cd WHERE field_id IN (SELECT field_id FROM level_1_fields) AND score>0;

-- 通过paper_id找到level 1 对应的author的所有基本信息：author_id, gender
CREATE TABLE level_1_field_paperId_author AS
SELECT f.field_id, a.paper_id, a.author_id, a.gender FROM author a JOIN level_1_paper_id f ON a.paper_id=f.paper_id;

-- 通过paper_id找到level 1 对应的paper的所有基本信息：year、citation_count
CREATE TABLE level_1_field_paper_author AS
SELECT l.field_id, l.paper_id, l.author_id, l.gender, p.`year`, p.citation_count 
FROM level_1_field_paperId_author l JOIN paper p ON l.paper_id=p.paper_id;

-- 按领域计算level 1 中男女性科学家的人数、产量、citation
CREATE TABLE level_1_prod_impact_by_field AS
SELECT
	field_id,
	COUNT(DISTINCT author_id) AS author_number, 
	COUNT(DISTINCT IF(gender='male' OR gender='mostly_male',author_id,NULL)) AS male_num, 
	COUNT(DISTINCT IF(gender='female' OR gender='mostly_female',author_id,NULL)) AS female_num,
	COUNT(IF(gender='male' OR gender='mostly_male', paper_id, NULL)) AS male_prod,
	COUNT(IF(gender='female' OR gender='mostly_female', paper_id, NULL)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citation_count, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citation_count, 0)) AS female_citation
FROM level_1_field_paper_author GROUP BY field_id;

-- 计算level 1 每个领域的人均产量、人均影响力
CREATE TABLE level_1_prod_impact_by_field_avg
SELECT field_id, author_number, male_num, female_num, male_prod, female_prod, male_citation, female_citation,
	male_prod/male_num AS male_prod_avg,
	female_prod/female_num AS female_prod_avg,
	male_citation/male_num AS male_impact_avg,
	female_citation/female_num AS female_impact_avg
FROM level_1_prod_impact_by_field;

-- 根据条件“女性人均影响力大于男性人均影响力”筛选level 1 中的目标领域
SELECT * FROM level_1_prod_impact_by_field_avg WHERE female_impact_avg>male_impact_avg;

-- 筛选level 2 的，并且包含10000篇文章以上的field的信息：field_id, normalized_name, citation_count
CREATE TABLE level_2_fields_10000p AS
SELECT field_id, normalized_name, citation_count FROM field_of_study WHERE `level`=2 AND paper_count>10000;

-- 通过paper_id, field_id的对应关系找到level 2 中的所有paper_id，paper_field是分表处理
CREATE TABLE level_2_paper_id_10000 AS
SELECT field_id, paper_id FROM paper_field_a_ab WHERE field_id IN (SELECT field_id FROM level_2_fields_10000p) AND score>0;

INSERT INTO level_2_paper_id_10000 (field_id, paper_id)
SELECT field_id, paper_id FROM paper_field_a_cd WHERE field_id IN (SELECT field_id FROM level_2_fields_10000p) AND score>0;

-- 通过paper_id找到level 2 对应的author的所有基本信息：author_id, gender
CREATE TABLE level_2_field_paperId_author AS
SELECT f.field_id, a.paper_id, a.author_id, a.gender FROM author a JOIN level_2_paper_id_10000 f ON a.paper_id=f.paper_id

-- 通过paper_id找到level 2 对应的paper的所有基本信息：year、citation_count
CREATE TABLE level_2_field_paper_author AS
SELECT l.field_id, l.paper_id, l.author_id, l.gender, p.`year`, p.citation_count 
FROM level_2_field_paperId_author l JOIN paper p ON l.paper_id=p.paper_id

-- 按领域计算level 2 中男女性科学家的人数、产量、citation
CREATE TABLE level_2_prod_impact_by_field AS
SELECT
	field_id,
	COUNT(DISTINCT author_id) AS author_number, 
	COUNT(DISTINCT IF(gender='male' OR gender='mostly_male',author_id,NULL)) AS male_num, 
	COUNT(DISTINCT IF(gender='female' OR gender='mostly_female',author_id,NULL)) AS female_num,
	COUNT(IF(gender='male' OR gender='mostly_male', paper_id, NULL)) AS male_prod,
	COUNT(IF(gender='female' OR gender='mostly_female', paper_id, NULL)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citation_count, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citation_count, 0)) AS female_citation
FROM level_2_field_paper_author GROUP BY field_id

-- 计算level 2 每个领域的人均产量、人均影响力
CREATE TABLE level_2_prod_impact_by_field_avg
SELECT field_id, author_number, male_num, female_num, male_prod, female_prod, male_citation, female_citation,
	male_prod/male_num AS male_prod_avg,
	female_prod/female_num AS female_prod_avg,
	male_citation/male_num AS male_impact_avg,
	female_citation/female_num AS female_impact_avg
FROM level_2_prod_impact_by_field

-- 根据条件“女性人均影响力大于男性人均影响力”筛选level 2 中的目标领域
SELECT * FROM level_2_prod_impact_by_field_avg WHERE female_impact_avg>male_impact_avg*1.1