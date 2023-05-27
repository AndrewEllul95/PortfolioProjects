/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM [Project Portfolio].dbo.NashvilleHousing

-------------------------------------------------------------------------------------------------

--Standarise Date Format


SELECT 
  SaleDateConverted, 
  CONVERT(Date, SaleDate)
FROM 
  [Project Portfolio].dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

-------------------------------------------------------------------------------------------------

--Populate Property Address data


SELECT 
  *
FROM 
  [Project Portfolio].dbo.NashvilleHousing
--WHERE
--	PropertyAddress IS NULL
ORDER BY
	ParcelID;


SELECT 
	 a.ParcelID
	,a.PropertyAddress
	,b.ParcelID
	,b.PropertyAddress
	,ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
	[Project Portfolio].dbo.NashvilleHousing AS a
JOIN 
	[Project Portfolio].dbo.NashvilleHousing AS b ON a.ParcelID = b.ParcelID
AND 
	a.[UniqueID ] <> b.[UniqueID ]
WHERE
	a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
	[Project Portfolio].dbo.NashvilleHousing AS a
JOIN 
	[Project Portfolio].dbo.NashvilleHousing AS b ON a.ParcelID = b.ParcelID
AND 
	a.[UniqueID ] <> b.[UniqueID ]
WHERE 
	a.PropertyAddress IS NULL

-------------------------------------------------------------------------------------------------

--Breaking out Property Address into Individual Columns (Address, City, State)
-- Used SUBSTRING

SELECT
	PropertyAddress
FROM 
	[Project Portfolio].dbo.NashvilleHousing
--WHERE
--	PropertyAddress IS NULL
--ORDER BY
--	ParcelID

SELECT
	 SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
	,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM 
	[Project Portfolio].dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255); 

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255); 

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));



-------------------------------------------------------------------------------------------------

--Breaking out Owner Address into Individual Columns (Address, City, State)
-- Used PARSENAME



SELECT
	OwnerAddress
FROM
	[Project Portfolio].dbo.NashvilleHousing


SELECT
	 PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3) AS Address
	,PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2) AS City
	,PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1) AS State
FROM
	[Project Portfolio].dbo.NashvilleHousing



ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3);

ALTER TABLE NashvilleHousing
ADD OwnerSpliCity Nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerSpliCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255); 

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1);


-------------------------------------------------------------------------------------------------

--Change Y & N  to Yes & No in 'Sold as Vacant' field

SELECT
	 DISTINCT(SoldAsVacant)
	,COUNT(SoldAsVacant) AS Count
FROM
	[Project Portfolio].dbo.NashvilleHousing
GROUP BY
	SoldAsVacant
ORDER BY
	COUNT(SoldAsVacant)


SELECT
	 SoldAsVacant
	,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	      WHEN SoldAsVacant = 'N' THEN 'No'
		  ELSE SoldAsVacant
		  END
FROM
	[Project Portfolio].dbo.NashvilleHousing


UPDATE [Project Portfolio].dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


-------------------------------------------------------------------------------------------------

--Remove Duplicates


WITH RowNumCTE AS
(
SELECT
	 *
	,ROW_NUMBER() OVER(PARTITION BY  
							 ParcelID
							,PropertyAddress
							,SalePrice
							,SaleDate
							,LegalReference		
						ORDER BY 
							UniqueID
						) AS row_num
FROM 
	[Project Portfolio].dbo.NashvilleHousing
--ORDER BY
--	ParcelID
)

SELECT
	*	
FROM
	RowNumCTE
WHERE 
	row_num >1
ORDER BY
	PropertyAddress



-------------------------------------------------------------------------------------------------

--Delete Unused Columns


SELECT
	*
FROM
	[Project Portfolio].dbo.NashvilleHousing


ALTER TABLE [Project Portfolio].dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE [Project Portfolio].dbo.NashvilleHousing
DROP COLUMN SaleDate