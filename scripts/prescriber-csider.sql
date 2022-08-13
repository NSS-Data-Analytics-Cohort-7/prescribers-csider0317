-- Medicare Prescriptions Data
-- In this exercise, you will be working with a database created from the 2017 Medicare Part D Prescriber Public Use File, available at https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider-and-drug.

-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT
       p1.NPI,
       p2.total_claim_count 
  FROM prescriber AS p1
  LEFT JOIN prescription AS p2
  ON p1.npi=p2.npi
  WHERE p2.total_claim_count IS NOT NULL
  GROUP BY p1.NPI, p2.total_claim_count
  ORDER BY p2.total_claim_count DESC;
  --1912011792	
  --total claims 4538
  
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT
       p1.nppes_provider_first_name,
       p1.nppes_provider_last_org_name, 
       p1.specialty_description,
       p2.total_claim_count 
  FROM prescriber AS p1
  LEFT JOIN prescription AS p2
  ON p1.npi=p2.npi
  WHERE p2.total_claim_count IS NOT NULL
  ORDER BY p2.total_claim_count DESC;
  
 -- "DAVID"	"COFFEY"	"Family Practice"	4538
-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT
    p1.specialty_description,
    SUM(p2.total_claim_count)
    FROM prescriber AS p1
  LEFT JOIN prescription AS p2
  ON p1.npi=p2.npi
  WHERE p2.total_claim_count IS NOT NULL
  GROUP BY p1.specialty_description
  ORDER BY SUM(p2.total_claim_count) DESC
  --"Family Practice"	9752347


--     b. Which specialty had the most total number of claims for opioids?

SELECT
    prescriber.specialty_description,
    COUNT(drug.opioid_drug_flag) AS opioid_count
    FROM prescriber 
    LEFT JOIN prescription 
    USING(NPI)
    LEFT JOIN drug 
    USING(drug_name)
    WHERE total_claim_count IS NOT null AND UPPER(opioid_drug_flag) = 'Y'
    GROUP BY prescriber.specialty_description
    ORDER BY opioid_count DESC;
    -- NURSE PRAC 9551

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT 
    p1.specialty_description,
    SUM(p2.total_claim_count)
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING(NPI)
WHERE p2.total_claim_count IS NULL
GROUP BY p1.specialty_description
-- 92 providers 


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. a. Which drug (generic_name) had the highest total drug cost?
SELECT
    drug.generic_name,
    MAX(prescription.total_drug_cost)
 FROM drug
   LEFT JOIN prescription
   USING(drug_name)
WHERE prescription.total_drug_cost IS NOT NULL
GROUP BY drug.generic_name
ORDER BY MAX(prescription.total_drug_cost)desc
 --"PIRFENIDONE"	2829174.3   

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT
    drug.generic_name,          ROUND(prescription.total_drug_cost/NULLIF(prescription.total_day_supply,0),2) AS cost_per_day,
    prescription.total_day_supply
FROM drug
   LEFT JOIN prescription
   USING(drug_name)
   WHERE ROUND(prescription.total_drug_cost/NULLIF(prescription.total_day_supply,0))>0
    GROUP BY drug.generic_name,prescription.total_day_supply,                       cost_per_day
    ORDER BY cost_per_day DESC
    --"IMMUN GLOB G(IGG)/GLY/IGA OV50"	7141.11

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT
    drug.drug_name, 
    opioid_drug_flag,
    antibiotic_drug_flag,
CASE
    WHEN opioid_drug_flag='Y' THEN 'opioid'
    WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
    ELSE 'neither' 
 END AS drug_type
 FROM drug
--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT
   SUM(total_drug_cost)AS money,
   subquery.drug_type
   FROM
(SELECT
    drug.drug_name, 
    CASE
    WHEN opioid_drug_flag='Y' THEN 'opioid'
    WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
    ELSE 'neither' 
 END AS drug_type
 FROM drug) AS subquery
 LEFT JOIN prescription
        ON subquery.drug_name=prescription.drug_name
        WHERE drug_type IS NOT null
        GROUP BY drug_type
        ORDER BY money DESC
 -- opioid
 
     
-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
    COUNT(cbsa),
    cbsaname AS TN
FROM cbsa 
 WHERE cbsaname LIKE '%TN%'
 group by cbsaname
 --10
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT 
    DISTINCT(cbsa.cbsaname),
    SUM(population.population)AS total_pop
 FROM cbsa
 left join population
 ON cbsa.fipscounty=population.fipscounty
 WHERE cbsaname LIKE '%TN%' AND population is NOT NULL
 GROUP BY  DISTINCT(cbsa.cbsaname)
 ORDER BY total_pop DESC
 -- large=Nashville Small=Morristown
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT
   p.fipscounty,
    sum(p.population)AS total_pop,
    f.county
FROM population as p
    LEFT JOIN cbsa AS c
        ON c.fipscounty=p.fipscounty
    LEFT JOIN fips_county AS f
        ON p.fipscounty=f.fipscounty
        WHERE cbsaname like '%TN%'
        GROUP BY p.fipscounty, c.cbsaname, f.county
        ORDER BY total_pop DESC
 --SUMNER
        
-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT
    total_claim_count,
    drug_name
 FROM prescription 
 WHERE total_claim_count >= 3000
--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT
    p.total_claim_count,
    p.drug_name,
    d.opioid_drug_flag
 FROM prescription AS p
 LEFT JOIN drug as d
    ON p.drug_name=d.drug_name
 WHERE d.opioid_drug_flag='Y' AND total_claim_count >= 3000

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

    

