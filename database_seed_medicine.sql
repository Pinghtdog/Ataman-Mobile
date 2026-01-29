-- 1. EXTEND FACILITIES TABLE (If not already present)
-- This allows us to flag which facilities are "Pharmacies" vs "Hospitals"
ALTER TABLE public.facilities ADD COLUMN IF NOT EXISTS is_pharmacy BOOLEAN DEFAULT FALSE;

-- 2. SEED MEDICINES MASTER LIST
-- This acts as the "Standard Catalog" that all different systems must map to
INSERT INTO public.medicines (name, description, category, icon_name)
VALUES 
('Amoxicillin', '500mg Capsule', 'Antibiotic', 'medication_rounded'),
('Paracetamol', '500mg Tablet', 'Analgesic', 'grid_view_rounded'),
('Insulin Glargine', '100 units/mL', 'Diabetes', 'colorize_rounded'),
('Salbutamol', '100mcg Inhaler', 'Respiratory', 'air_rounded'),
('Metformin', '500mg Tablet', 'Diabetes', 'medication_rounded'),
('Ascorbic Acid', '500mg Tablet', 'Vitamin', 'medication_rounded')
ON CONFLICT DO NOTHING;

-- 3. SEED FACILITY STOCK (The "Unified Inventory")
-- Even if Pharmacy A and Hospital B use different local software, 
-- ATAMAN acts as the aggregator.
INSERT INTO public.facility_medicines (facility_id, medicine_id, price, stock_count)
VALUES 
-- Assuming facility 1 is a Public BHC
(1, (SELECT id FROM medicines WHERE name = 'Amoxicillin'), 0.00, 150),
(1, (SELECT id FROM medicines WHERE name = 'Paracetamol'), 0.00, 500),

-- Assuming facility 2 is a Private Hospital/Pharmacy
(2, (SELECT id FROM medicines WHERE name = 'Amoxicillin'), 12.50, 45),
(2, (SELECT id FROM medicines WHERE name = 'Insulin Glargine'), 850.00, 12),
(2, (SELECT id FROM medicines WHERE name = 'Salbutamol'), 350.00, 0)
ON CONFLICT (facility_id, medicine_id) DO UPDATE 
SET price = EXCLUDED.price, stock_count = EXCLUDED.stock_count;

-- 4. THE SOLUTION TO THE "DIFFERENT SYSTEMS" CHALLENGE:
-- We create a "Standard Mapping" view. 
-- In a real scenario, we would use an Adapter Pattern or an ETL job to sync 
-- from Mercury Drug, Watson's, or Hospital MIS into this unified table.

COMMENT ON TABLE public.facility_medicines IS 'Unified inventory aggregator. 
Challenge Solution: Different local systems (SAP, Oracle, Excel) export to this 
central schema via the ATAMAN Data Sync API, creating a "Single Source of Truth" 
for Naga City residents.';
