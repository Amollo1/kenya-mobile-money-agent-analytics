-- =========================================================================
-- Phase 3: Kenyan Reference Data Seed Script
-- Populates DimLocation and DimProvider
-- Run AFTER schema.sql has created the database and tables.
-- =========================================================================

USE kenya_mobile_money;

-- -------------------------------------------------------------------------
-- DimLocation: 103 rows across 47 counties
-- -------------------------------------------------------------------------
INSERT INTO DimLocation (County, SubCounty, UrbanRural, Region) VALUES
    ('Nairobi', 'Westlands', 'Urban', 'Nairobi'),
    ('Nairobi', 'Dagoretti North', 'Urban', 'Nairobi'),
    ('Nairobi', 'Langata', 'Urban', 'Nairobi'),
    ('Nairobi', 'Kasarani', 'Urban', 'Nairobi'),
    ('Nairobi', 'Embakasi East', 'Urban', 'Nairobi'),
    ('Nairobi', 'Kamukunji', 'Urban', 'Nairobi'),
    ('Kiambu', 'Thika Town', 'Urban', 'Central'),
    ('Kiambu', 'Ruiru', 'Rural', 'Central'),
    ('Kiambu', 'Kiambu Town', 'Rural', 'Central'),
    ('Kiambu', 'Limuru', 'Rural', 'Central'),
    ('Murang''a', 'Murang''a Town', 'Urban', 'Central'),
    ('Murang''a', 'Kangema', 'Rural', 'Central'),
    ('Nyeri', 'Nyeri Town', 'Urban', 'Central'),
    ('Nyeri', 'Mathira', 'Rural', 'Central'),
    ('Kirinyaga', 'Kerugoya', 'Urban', 'Central'),
    ('Kirinyaga', 'Mwea', 'Rural', 'Central'),
    ('Nyandarua', 'Ol Kalou', 'Urban', 'Central'),
    ('Nyandarua', 'Ol Joro Orok', 'Rural', 'Central'),
    ('Mombasa', 'Mvita', 'Urban', 'Coast'),
    ('Mombasa', 'Nyali', 'Urban', 'Coast'),
    ('Mombasa', 'Likoni', 'Urban', 'Coast'),
    ('Kwale', 'Kwale Town', 'Urban', 'Coast'),
    ('Kwale', 'Msambweni', 'Rural', 'Coast'),
    ('Kilifi', 'Kilifi Town', 'Urban', 'Coast'),
    ('Kilifi', 'Malindi', 'Rural', 'Coast'),
    ('Tana River', 'Hola', 'Urban', 'Coast'),
    ('Tana River', 'Garsen', 'Rural', 'Coast'),
    ('Lamu', 'Lamu Town', 'Urban', 'Coast'),
    ('Lamu', 'Faza', 'Rural', 'Coast'),
    ('Taita-Taveta', 'Voi', 'Urban', 'Coast'),
    ('Taita-Taveta', 'Taveta', 'Rural', 'Coast'),
    ('Machakos', 'Machakos Town', 'Urban', 'Eastern'),
    ('Machakos', 'Athi River', 'Rural', 'Eastern'),
    ('Makueni', 'Wote', 'Urban', 'Eastern'),
    ('Makueni', 'Kibwezi', 'Rural', 'Eastern'),
    ('Kitui', 'Kitui Town', 'Urban', 'Eastern'),
    ('Kitui', 'Mwingi', 'Rural', 'Eastern'),
    ('Embu', 'Embu Town', 'Urban', 'Eastern'),
    ('Embu', 'Runyenjes', 'Rural', 'Eastern'),
    ('Tharaka-Nithi', 'Chuka', 'Urban', 'Eastern'),
    ('Tharaka-Nithi', 'Marimanti', 'Rural', 'Eastern'),
    ('Meru', 'Meru Town', 'Urban', 'Eastern'),
    ('Meru', 'Nkubu', 'Rural', 'Eastern'),
    ('Isiolo', 'Isiolo Town', 'Urban', 'Eastern'),
    ('Isiolo', 'Merti', 'Rural', 'Eastern'),
    ('Marsabit', 'Marsabit Town', 'Urban', 'Eastern'),
    ('Marsabit', 'Moyale', 'Rural', 'Eastern'),
    ('Garissa', 'Garissa Town', 'Urban', 'North Eastern'),
    ('Garissa', 'Dadaab', 'Rural', 'North Eastern'),
    ('Wajir', 'Wajir Town', 'Urban', 'North Eastern'),
    ('Wajir', 'Habaswein', 'Rural', 'North Eastern'),
    ('Mandera', 'Mandera Town', 'Urban', 'North Eastern'),
    ('Mandera', 'El Wak', 'Rural', 'North Eastern'),
    ('Kisumu', 'Kisumu Central', 'Urban', 'Nyanza'),
    ('Kisumu', 'Kisumu West', 'Rural', 'Nyanza'),
    ('Kisumu', 'Nyando', 'Rural', 'Nyanza'),
    ('Siaya', 'Siaya Town', 'Urban', 'Nyanza'),
    ('Siaya', 'Bondo', 'Rural', 'Nyanza'),
    ('Homa Bay', 'Homa Bay Town', 'Urban', 'Nyanza'),
    ('Homa Bay', 'Mbita', 'Rural', 'Nyanza'),
    ('Migori', 'Migori Town', 'Urban', 'Nyanza'),
    ('Migori', 'Rongo', 'Rural', 'Nyanza'),
    ('Kisii', 'Kisii Town', 'Urban', 'Nyanza'),
    ('Kisii', 'Nyamache', 'Rural', 'Nyanza'),
    ('Nyamira', 'Nyamira Town', 'Urban', 'Nyanza'),
    ('Nyamira', 'Borabu', 'Rural', 'Nyanza'),
    ('Nakuru', 'Nakuru Town East', 'Urban', 'Rift Valley'),
    ('Nakuru', 'Nakuru Town West', 'Rural', 'Rift Valley'),
    ('Nakuru', 'Naivasha', 'Rural', 'Rift Valley'),
    ('Uasin Gishu', 'Eldoret East', 'Urban', 'Rift Valley'),
    ('Uasin Gishu', 'Eldoret West', 'Rural', 'Rift Valley'),
    ('Trans Nzoia', 'Kitale', 'Urban', 'Rift Valley'),
    ('Trans Nzoia', 'Kwanza', 'Rural', 'Rift Valley'),
    ('Kericho', 'Kericho Town', 'Urban', 'Rift Valley'),
    ('Kericho', 'Bureti', 'Rural', 'Rift Valley'),
    ('Bomet', 'Bomet Central', 'Urban', 'Rift Valley'),
    ('Bomet', 'Chepalungu', 'Rural', 'Rift Valley'),
    ('Nandi', 'Kapsabet', 'Urban', 'Rift Valley'),
    ('Nandi', 'Nandi Hills', 'Rural', 'Rift Valley'),
    ('Baringo', 'Kabarnet', 'Urban', 'Rift Valley'),
    ('Baringo', 'Marigat', 'Rural', 'Rift Valley'),
    ('Laikipia', 'Nanyuki', 'Urban', 'Rift Valley'),
    ('Laikipia', 'Rumuruti', 'Rural', 'Rift Valley'),
    ('Narok', 'Narok Town', 'Urban', 'Rift Valley'),
    ('Narok', 'Kilgoris', 'Rural', 'Rift Valley'),
    ('Kajiado', 'Kajiado Town', 'Urban', 'Rift Valley'),
    ('Kajiado', 'Ngong', 'Rural', 'Rift Valley'),
    ('Turkana', 'Lodwar', 'Urban', 'Rift Valley'),
    ('Turkana', 'Kakuma', 'Rural', 'Rift Valley'),
    ('West Pokot', 'Kapenguria', 'Urban', 'Rift Valley'),
    ('West Pokot', 'Sigor', 'Rural', 'Rift Valley'),
    ('Samburu', 'Maralal', 'Urban', 'Rift Valley'),
    ('Samburu', 'Baragoi', 'Rural', 'Rift Valley'),
    ('Elgeyo-Marakwet', 'Iten', 'Urban', 'Rift Valley'),
    ('Elgeyo-Marakwet', 'Kapsowar', 'Rural', 'Rift Valley'),
    ('Kakamega', 'Kakamega Town', 'Urban', 'Western'),
    ('Kakamega', 'Mumias', 'Rural', 'Western'),
    ('Bungoma', 'Bungoma Town', 'Urban', 'Western'),
    ('Bungoma', 'Webuye', 'Rural', 'Western'),
    ('Busia', 'Busia Town', 'Urban', 'Western'),
    ('Busia', 'Malaba', 'Rural', 'Western'),
    ('Vihiga', 'Vihiga Town', 'Urban', 'Western'),
    ('Vihiga', 'Luanda', 'Rural', 'Western');

-- -------------------------------------------------------------------------
-- DimProvider: market-share weights are documentation only (not a DB
-- column) -- they drive the Python transaction-volume generator in
-- Phase 4, so provider mix in the fact table matches real Kenyan share.
-- -------------------------------------------------------------------------
INSERT INTO DimProvider (ProviderName, ProviderCategory) VALUES
    ('M-Pesa', 'Mobile Money'),
    ('Airtel Money', 'Mobile Money'),
    ('Bank Agency Banking', 'Bank Agency Banking');
    
-- Test
SELECT COUNT(*) FROM DimLocation;   -- should return 103
SELECT * FROM DimProvider;          -- should return 3 rows