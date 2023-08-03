-- ASSUMPTIONS
-- 1. Every address has a unique parcel id. Which means if there are any addresses missing then we can check the database
-- to determine if we have a parcel id in the database already and use the address associated to update the NULL values. 

delete from housing

-- Copying data from CSV file as a table
copy housing
from '/Users/radhika/Desktop/Nashville Housing Data for Data Cleaning.csv'
delimiter ','
csv header

-- Updating the column data types to be in sync with the data types of the columns in CSV file and then running the above 
-- copy command again.
alter table housing alter column parcelid type varchar(500)

alter table housing alter column legalreference type varchar(500)

-- Checking data
select * from housing

-- Populate property address data

select *
from housing
where propertyaddress is null

select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.propertyaddress, b.propertyaddress)
from housing a
join housing b
on a.parcelid = b.parcelid
and a.uniqueid <> b.uniqueid
where a.propertyaddress is null

with getCorrectData as
	(
		select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.propertyaddress, b.propertyaddress) as finalR
		from housing a
		join housing b
		on a.parcelid = b.parcelid
		and a.uniqueid <> b.uniqueid
		where a.propertyaddress is null
	)
update housing
set propertyaddress = getCorrectData.finalR
from getCorrectData
where housing. propertyaddress is null

-- Breaking out property address into individual columns (Using substring and position functions)
select substring(propertyaddress, 1, position(',' in propertyaddress) - 1) as AddressLine,
substring(propertyaddress, position(',' in propertyaddress) + 1, length(propertyaddress))as State
from housing

-- Adding the above split address columsn in table 
alter table housing
add column PropertyAddressLine Varchar(500);

alter table housing
add column PropertState varchar(500)

update housing
set PropertyAddressLine = substring(propertyaddress, 1, position(',' in propertyaddress) - 1),
PropertState = substring(propertyaddress, position(',' in propertyaddress) + 1, length(propertyaddress));

select * from housing

-- Breaking out owner address into individual columns
select propertyaddress 
from housing; 

select split_part(owneraddress, ',', 1) as OwnerAddressLine,
split_part(owneraddress, ',', 2)  as OwnerCityState,
split_part(owneraddress, ',', 3) as OwnerState
from housing

alter table housing
add column OwnerAddressLine varchar(500);

alter table housing
add column OwnerCity varchar(500);

alter table housing
add column OwnerState varchar(500);

update housing
set OwnerAddressLine = split_part(owneraddress, ',', 1),
OwnerCity = split_part(owneraddress, ',', 2),
OwnerState = split_part(owneraddress, ',', 3);

-- Change Y and N to "Yes" and "No" in "Sold as Vacant" field
select distinct soldasvacant, count(*)
from housing
group by soldasvacant

update housing
set soldasvacant = 'Yes'
where soldasvacant = 'Y'

update housing
set soldasvacant = 'No'
where soldasvacant = 'N'

-- Another way to do this is via case statement
update housing
set soldasvacant = 
	(
		case when soldasvacant = 'Yes' then 'YES'
			 when soldasvacant = 'No' then 'NO'
		end
	)


-- Remove duplicates
-- Best practice is not to delete any data. This is just for demo.

delete from housing where uniqueid in (
with cte as 
	(
		select *,
		row_number() over (partition by parcelid,
										propertyaddress,
										saleprice,
										saledate,
										legalreference
							order by uniqueid) row_num
		from housing
	)
select uniqueid from cte
where row_num > 1
)

-- Delete unused columns

alter table housing
drop column propertyaddress, 
drop column taxdistrict, 
drop column owneraddress

select * from housing
