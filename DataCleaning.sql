select *
from layoffs;

# Steps Taken:
# 1. Remove Duplicates
# 2. Standardize Data
# 3. Look at Null Values
# 4. Remove Any Irrelevant Columns

# Making a copy to not accidently change important info from raw data
Create table layoffs_staging
like layoffs;

select *
from layoffs_staging;
insert layoffs_staging
select *
from layoffs;

### Removing Duplicates --------------------------------------------------------------------------------------

select *,
row_number() over(
partition by company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_milllions) as row_num
from layoffs_staging;

with dup_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select *
from dup_cte
where row_num >1;

# Double Check to make sure they are actually duplicates

select *
from layoffs_staging
where company = 'Casper';







# No duplicates table

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2
where row_num > 1;

insert into layoffs_staging2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

delete 
from layoffs_staging2
where row_num > 1;

select *
from layoffs_staging2
where company = 'Casper';

### Standardizing Data --------------------------------------------------------------------------------

select *
from layoffs_staging2;

# Top 2 companies have a space in front of there name that can be trimmed
select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);
-- ---------------------------------
select distinct industry
from layoffs_staging2
order by 1;

# Crypto, CryptoCurrenc, and Crypto Currency are counted as different industries. Need to make them 1

select *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';
-- ----------------------------------------------------
select distinct country
from layoffs_staging2
order by 1;
# United States and United States. (with a perdiod) need to be standardized
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
where country like 'United St%'
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- --------------------------------------------------------
# Date is a text col, need to set to date col
select `date`
from layoffs_staging2;

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');
# Still condired date col, need to get the text date into this format to convert it
alter table layoffs_staging2
modify column `date` date;

select *
from layoffs_staging2;

### Dealing with null valus ---------------------------------------------------------------------------

select * 
from layoffs_staging2
where total_laid_off is null;

select * 
from layoffs_staging2
where industry is null
or industry = '';

update layoffs_staging2
set industry = null
where industry = '';

select * 
from layoffs_staging2
where company = 'Airbnb';

# Industry section of 1 airbnb layoff is travel while another one is null. Since we know it's considered travel, make the null travel.
select *
from layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

### Removing useless rows/columns ---------------------------------------------------------------------------

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2;
# Don't need row_num column anymore layoffs_staging2
alter table layoffs_staging2
drop column row_num;