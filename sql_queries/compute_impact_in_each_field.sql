-- 删除log文件
RESET MASTER;

-- 1.1 根据 field 找 field 信息
SELECT DISTINCT * FROM field_of_study WHERE field_id='185544564'; -- Nuclear physics

-- 1.2 从level2的paper中找到field的所有paper author 信息，构建 xxx_paper_author
CREATE TABLE nuclear_physics_paper_author AS
SELECT DISTINCT * FROM level_1_field_paper_author WHERE field_id='185544564';

-- 2. 以作者为单位计算产量和影响力，SPSS中比较差异的显著性，不显著到此为止，显著接着计算
CREATE TABLE nuclear_physics_paper_author_pro_impact AS
SELECT DISTINCT b.author_id, a.gender, b.career_length, b.paper_count, b.citations 
FROM nuclear_physics_paper_author a JOIN (
	SELECT DISTINCT
		author_id,
		MAX(`year`)-MIN(`year`)+1 AS career_length,
		COUNT(DISTINCT paper_id) AS paper_count,
		SUM(citation_count) AS citations
	FROM nuclear_physics_paper_author GROUP BY author_id
) AS b ON a.author_id=b.author_id;

-- 3. 去除career length为1的作者之后，到SPSS看差异显著性
CREATE TABLE kraft_paper_author_pro_impact_career2 AS
SELECT DISTINCT * FROM kraft_paper_author_pro_impact WHERE career_length>1;

-- 4. 比较career length为1的作者，到SPSS看差异显著性
CREATE TABLE kraft_paper_author_pro_impact_career1 AS
SELECT DISTINCT * FROM kraft_paper_author_pro_impact WHERE career_length=1;

-- 5. 计算early stage 补充citation_5years, 先执行Paper_citation_five_years和Get_author_early_stage_papers, 之后update the table name as xxx_paper_author
CREATE TABLE kraft_paper_paper_author_5years AS
SELECT DISTINCT c.field_id, c.paper_id, c.author_id, c.gender, c.`year`, c.citation_count, c.pre_5years, p.citation_5years
FROM kraft_paper_paper_author c JOIN paper p ON c.paper_id=p.paper_id;

-- 6.1 获取该领域early stage
CREATE TABLE kraft_paper_paper_author_early_stage AS
SELECT DISTINCT * FROM kraft_paper_paper_author WHERE pre_5years='yes';

-- 6.2 early stage的产量和影响力
CREATE TABLE kraft_paper_author_pro_impact_early_stage AS
SELECT DISTINCT b.author_id, a.gender, b.career_length, b.paper_count, b.citations 
FROM kraft_paper_paper_author_early_stage a JOIN (
	SELECT
		author_id,
		MAX(`year`)-MIN(`year`)+1 AS career_length,
		COUNT(DISTINCT paper_id) AS paper_count,
		SUM(citation_count) AS citations
	FROM kraft_paper_paper_author_early_stage GROUP BY author_id
) AS b ON a.author_id=b.author_id;

-- 6.3 early stage的另一种计算方式，即所有early stage的paper的PRE-5years citation
CREATE TABLE kraft_paper_author_pro_impact_early_stage5 AS
SELECT DISTINCT b.author_id, a.gender, b.citations 
FROM kraft_paper_paper_author_early_stage a JOIN (
	SELECT
		author_id,
		SUM(citation_5years) AS citations
	FROM kraft_paper_paper_author_early_stage GROUP BY author_id
) AS b ON a.author_id=b.author_id;

-- 7.1 获取该领域的late stage
CREATE TABLE kraft_paper_paper_author_late_stage AS
SELECT DISTINCT * FROM kraft_paper_paper_author WHERE author_id IN (
	SELECT DISTINCT author_id FROM kraft_paper_author_pro_impact WHERE career_length>5
) AND pre_5years='no';

-- 7.2 获取该领域late stage的产量、影响力
CREATE TABLE kraft_paper_author_pro_impact_late_stage AS
SELECT DISTINCT b.author_id, a.gender, b.career_length, b.paper_count, b.citations 
FROM kraft_paper_paper_author_late_stage a JOIN (
	SELECT
		author_id,
		MAX(`year`)-MIN(`year`)+6 AS career_length,
		COUNT(DISTINCT paper_id) AS paper_count,
		SUM(citation_count) AS citations
	FROM kraft_paper_paper_author_late_stage GROUP BY author_id
) AS b ON a.author_id=b.author_id;

-- 7.3 获取该领域的late stage的另一种计算方式，即early stage 5年后的citation加上late stage的文章的citation
CREATE TABLE kraft_paper_paper_author_late_stage_pre_5 AS
SELECT DISTINCT * FROM kraft_paper_paper_author WHERE author_id IN (
	SELECT DISTINCT author_id FROM kraft_paper_author_pro_impact WHERE career_length>5
);

-- 7.4 获取late stage 另一种计算方式的产量、影响力
CREATE TABLE kraft_paper_author_pro_impact_late_stage5 AS
SELECT DISTINCT b.author_id, a.gender, b.citations 
FROM kraft_paper_paper_author_late_stage_pre_5 a JOIN (
	SELECT
		author_id,
		SUM(IF(pre_5years='yes', citation_count-citation_5years, citation_count)) AS citations
	FROM kraft_paper_paper_author_late_stage_pre_5 GROUP BY author_id
) AS b ON a.author_id=b.author_id;

-- 观察领域内总人数、男女人数、男女产量、男女影响力
SELECT 
	COUNT(DISTINCT author_id) AS author_num,
	COUNT(DISTINCT IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(DISTINCT IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	COUNT(IF(gender='male' OR gender='mostly_male', paper_id, NULL)) AS male_prod,
	COUNT(IF(gender='female' OR gender='mostly_female', paper_id, NULL)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citation_count, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citation_count, 0)) AS female_citation
FROM propane_paper_author;

-- 另一种计算总人数、男女人数、男女产量、男女影响力的方式
SELECT 
	COUNT(author_id) AS author_num,
	COUNT(IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	SUM(IF(gender='male' OR gender='mostly_male', paper_count, 0)) AS male_prod,
	SUM(IF(gender='female' OR gender='mostly_female', paper_count, 0)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact;

-- 找到该领域数据的年份起始范围
SELECT MIN(`year`), MAX(`year`) FROM kraft_paper_paper_author;

-- 观察人数、产量、citation by year
CREATE TABLE propane_prod_impact_by_year AS
SELECT 
	`year`, male_num, female_num, male_prod, female_prod, male_citation, female_citation,
	IF(male_num>0,male_prod/male_num,0) AS male_prod_avg,
	IF(female_num>0,female_prod/female_num,0) AS female_prod_avg,
	IF(male_num>0,male_citation/male_num,0) AS male_impact_avg,
	IF(female_num>0,female_citation/female_num,0) AS female_impact_avg
FROM (
	SELECT 
		`year`, 
		COUNT(DISTINCT author_id) AS author_num,
		COUNT(DISTINCT IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
		COUNT(DISTINCT IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
		COUNT(DISTINCT paper_id) AS prod,
		COUNT(IF(gender='male' OR gender='mostly_male', paper_id, NULL)) AS male_prod,
		COUNT(IF(gender='female' OR gender='mostly_female', paper_id, NULL)) AS female_prod,
		SUM(IF(gender='male' OR gender='mostly_male', citation_count, 0)) AS male_citation,
		SUM(IF(gender='female' OR gender='mostly_female', citation_count, 0)) AS female_citation
	FROM propane_paper_author GROUP BY `year`
) AS B;

-- 观察career length 在2以上的作者的总体人数、男女人数、男女产量、男女影响力
SELECT 
	COUNT(author_id) AS author_num,
	COUNT(IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	SUM(IF(gender='male' OR gender='mostly_male', paper_count, 0)) AS male_prod,
	SUM(IF(gender='female' OR gender='mostly_female', paper_count, 0)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact_career2;

-- 观察early stage的人数、男女人数、男女产量、男女影响力
SELECT 
	COUNT(author_id) AS author_num,
	COUNT(IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	SUM(IF(gender='male' OR gender='mostly_male', paper_count, 0)) AS male_prod,
	SUM(IF(gender='female' OR gender='mostly_female', paper_count, 0)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact_early_stage;

-- 观察early stage另一种计算方式的影响力
SELECT 
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact_early_stage5;

-- 观察late stage的人数、男女人数、男女产量、男女影响力
SELECT 
	COUNT(author_id) AS author_num,
	COUNT(IF(gender='male' OR gender='mostly_male', author_id, NULL)) AS male_num,
	COUNT(IF(gender='female' OR gender='mostly_female', author_id, NULL)) AS female_num,
	SUM(IF(gender='male' OR gender='mostly_male', paper_count, 0)) AS male_prod,
	SUM(IF(gender='female' OR gender='mostly_female', paper_count, 0)) AS female_prod,
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact_late_stage;

-- 观察late stage 另一种计算方式的人数、男女人数、男女产量、男女影响力
SELECT
	SUM(IF(gender='male' OR gender='mostly_male', citations, 0)) AS male_citation,
	SUM(IF(gender='female' OR gender='mostly_female', citations, 0)) AS female_citation
FROM cilium_author_pro_impact_late_stage5;

-- 查找level 2对应的level 1及level 0的领域信息
SELECT * FROM FieldofStudyChildren WHERE child_field_id='99148416';
-- 42360764
-- 159985019
SELECT * FROM field_of_study WHERE field_id='159985019';
-- 159985019
SELECT * FROM FieldofStudyChildren WHERE child_field_id='159985019';
-- 192562407
SELECT * FROM field_of_study WHERE field_id='192562407';

