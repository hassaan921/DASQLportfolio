-- steps marked by double dash
# conclusions marked by pound symbol

create database murder_case;

use murder_case;

select * from crime_scene_report;
select * from accused_person;
select * from interviews;
select * from drivers_license;
select * from atom_fit;
select * from atomcamp_annualdinner;
select * from annual_income;

-- making primary keys
alter table crime_scene_report
add primary key (index_report);

alter table atomcamp_annualdinner
add primary key (person_id);

alter table interviews
add primary key (person_id);

alter table accused_person
add primary key (person_id);

alter table drivers_license
add primary key (license_id);

alter table annual_income
add primary key (ssn);

-- In atom_fit, apparently there are duplicates in membership_id and person_id both

select person_id, count(person_id)
from atom_fit
group by person_id
having count(person_id) >1; 

select membership_id, count(membership_id)
from atom_fit
group by membership_id
having count(membership_id) >1; 

# duplicates can't be removed as rows carry different info, and without removing, I cannot define a primary key

-- defining composite keys

alter table atom_fit
modify membership_id varchar (255),
add primary key (person_id, membership_id);

-- changing date formats

update crime_scene_report
set date = 
case
when length(date) = 8 then
str_to_date(concat(substring(date, 1, 2), '/', 
                   SUBSTRING(date, 3, 2), '/', 
				   SUBSTRING(date, 5)), '%m/%d/%Y')
when length(date) = 7 then
    str_to_date(concat(substring(date, 1, 1), '/',
					   substring(date, 2, 2), '/', 
					   substring(date, 4)), '%m/%d/%Y')
else null
end;

-- updating atom_fit

alter table atom_fit
modify check_in_date varchar (255);

update atom_fit
set check_in_date = 
case
when length(check_in_date) = 8 then
str_to_date(concat(substring(check_in_date, 1, 2), '/', 
                   SUBSTRING(check_in_date, 3, 2), '/', 
				   SUBSTRING(check_in_date, 5)), '%m/%d/%Y')
when length(check_in_date) = 7 then
    str_to_date(concat(substring(check_in_date, 1, 1), '/',
					   substring(check_in_date, 2, 2), '/', 
					   substring(check_in_date, 4)), '%m/%d/%Y')
else null
end;

-- lastly, updating atomcamp_annualdinner

alter table atomcamp_annualdinner
modify date varchar (255);

update atomcamp_annualdinner
set date = 
case
when length(date) = 8 then
str_to_date(concat(substring(date, 1, 2), '/', 
                   SUBSTRING(date, 3, 2), '/', 
				   SUBSTRING(date, 5)), '%m/%d/%Y')
when length(date) = 7 then
    str_to_date(concat(substring(date, 1, 1), '/',
					   substring(date, 2, 2), '/', 
					   substring(date, 4)), '%m/%d/%Y')
else null
end;




-- Now, we try to solve the mystery

SELECT 
    *
FROM
    crime_scene_report
WHERE
    date = '2023-03-09'
        AND city = 'atom-city';

# check_in_date in the gym data base atom_fit returns a single person_id 184448 who checked in and out in 22 minutes

SELECT 
    *
FROM
    atom_fit
WHERE
    check_in_date = '2023-03-09';

-- therefore, we look for details for the same person_id in accused person and drivers license databases
SELECT 
    ap.person_id,
    ap.name,
    ap.ssn,
    dl.age,
    dl.gender,
    dl.eye_color,
    dl.license_id,
    dl.plate_number,
    dl.car_make,
    dl.car_model
FROM
    accused_person AS ap
        JOIN
    drivers_license AS dl ON ap.license_id = dl.license_id
WHERE
    ap.person_id = 184448;

-- person_id 184448 was interviewed after the murder. He did not have an alibi. He outrightly confessed to being a hired gun

SELECT 
    ap.person_id, ap.name, i.transcript
FROM
    accused_person AS ap
        JOIN
    interviews AS i ON ap.person_id = i.person_id
WHERE
    ap.person_id = 184448;

-- ssn did not return any useful information about the accused, except that his income does not match the car that he drives 

SELECT 
    ap.name, ap.license_id, ai.ssn, ai.annual_income
FROM
    accused_person AS ap
        JOIN
    annual_income AS ai ON ap.ssn = ai.ssn
WHERE
    ap.ssn = 480409449;

# Hired Gun: Ali Haider, 55 M, 5'9'', light-blue-eyed \n
# who drives a Lahore-registered Audi (license_id = 171424) was accused of murder 


-- But who hired him?
-- the interviewee has no alibi. But he gave away some info on who hired him

-- the crime report talked of two witnesses. Witness 1 was named Sanam Akhtar

# she was at the annual dinner on the said date. Person ID = 541190
SELECT 
    *
FROM
    atomcamp_annualdinner
WHERE
    date = '2023-03-09';

-- person_id 541190 is in fact Sanam Akhtar who "lives somewhere on 'Gulshan-e-Ravi Lahore,'" (as per crime scene report) 
-- taking a look at her interview transcript

SELECT 
    ap.person_id,
    ap.name,
    ap.address_street_name,
    ap.license_id,
    i.transcript
FROM
    accused_person AS ap
        JOIN
    interviews AS i ON ap.person_id = i.person_id
WHERE
    ap.person_id = 541190;

-- Person ID 541190 is one Shabnam Akhtar, who denies being at the murder site but went there afterwards the murder for 42 minutes on 2023-03-09, \n
-- and later, went to the annual dinner too, which checks against what the murderer's told the police

SELECT 
    af.person_id,
    af.membership_id,
    af.check_in_date,
    af.check_in_time,
    af.check_out_time,
    ad.person_id,
    ad.event_name,
    ad.date
FROM
    atom_fit AS af
        JOIN
    atomcamp_annualdinner AS ad
WHERE
    af.person_id = 541190
        AND ad.date = '2023-03-09';

# she is most probably our 2nd unnamed witness in the crime scene report and lives "at the last house in 'Saddar Bazaar Rawalpindi'".

-- checking her profile against the murderer's sketch of his employer: "I was hired by a woman...a millionaire...she has blue eyes \n
-- and her age is 60 and she drives a mercedes benz. She also told me that she will attend a dinner of a data company on 3/9/2023."

SELECT 
    ap.person_id,
    ap.name,
    ap.ssn,
    dl.age,
    dl.gender,
    dl.eye_color,
    dl.license_id,
    dl.plate_number,
    dl.car_make,
    dl.car_model
FROM
    accused_person AS ap
        JOIN
    drivers_license AS dl ON ap.license_id = dl.license_id
WHERE
    ap.person_id = 541190;

# Shabnam Akhtar, 60F, blue-eyed, who drives a Lahore-registered Mercedez Benz nearly fits our profile.

-- we just need to check if she's a millionaire
SELECT 
    ap.name, ap.license_id, ai.ssn, ai.annual_income
FROM
    accused_person AS ap
        JOIN
    annual_income AS ai ON ap.ssn = ai.ssn
WHERE
    ap.ssn = 967694038;

# 5.5 Million, voila! 

-- Finding out more about the 1st witness Sanam Akhtar to see if she was involved or can be absolved beyond reasonable doubt

-- crime scene report tells us she lives in Gulshan-e-Ravi Lahore

-- since the police only has her name and address (not personal ID), so we go this way

SELECT 
    *
FROM
    accused_person
WHERE
    name = 'Sanam Akhtar'
        AND address_street_name = 'Gulshan-e-Ravi, Lahore';

SELECT 
    ap.name,
    ap.license_id,
    ap.ssn,
    i.person_id,
    i.transcript,
    ap.ssn
FROM
    accused_person AS ap
        JOIN
    interviews AS i ON ap.person_id = i.person_id
WHERE
    ap.name = 'Sanam Akhtar'
        AND ap.person_id = 205019;


-- since she says she was working out at the gym on 2023-03-09

select * from atom_fit
where person_id = 205019 or membership_id = "AT3318";

 -- checking if she was in at the dinner on 2023-03-09

SELECT 
    af.person_id,
    af.membership_id,
    af.check_in_date,
    af.check_in_time,
    af.check_out_time,
    ad.person_id,
    ad.date,
    ad.event_name
FROM
    atom_fit AS af
        JOIN
    atomcamp_annualdinner AS ad
WHERE
    af.person_id = 205019
        AND ad.date = '2023-03-09';

# she was not in the gym or the dinner on 2023-03-09, but her whereabouts are shady 

-- lastly, checking for her biological info, the car she drives, and her income

SELECT 
    ap.name,
    ap.license_id,
    dl.age,
    dl.gender,
    dl.eye_color,
    dl.license_id,
    dl.plate_number,
    dl.car_make,
    dl.car_model,
    ap.ssn,
    ai.annual_income
FROM
    accused_person AS ap
        JOIN
    drivers_license AS dl ON ap.license_id = dl.license_id
        INNER JOIN
    annual_income AS ai ON ap.ssn = ai.ssn
WHERE
    ap.license_id = 641569
        AND ap.ssn = 146551420;

# Conclusion

# this solves our case satisfactorily but not optimally, satisfactorily since the killer confessed and his employer was in fact at the gym
# I doubt the case will hold up in the court since the evidence is circumstantial and not conclusive. 
# I'm dissatisfied since Sanam Akhtar's alibi does not clear her of doubt, but I couldn't find evidence whatsoever that she was involved