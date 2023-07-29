

--HT_INVOICES PACKAGE
--HT_INVOICES PACKAGE SPECIFICATION
CREATE OR REPLACE PACKAGE HT_INVOICE_CALCULATIONS AS
  -- Calculate the subtotal
  FUNCTION CALCULATE_SUBTOTAL(booking_id IN NUMBER) RETURN NUMBER;
  
  -- Calculate the tax amount
  FUNCTION CALCULATE_TAX(booking_id IN NUMBER) RETURN NUMBER;
  
  -- Calculate the total amount
  FUNCTION CALCULATE_TOTAL(booking_id IN NUMBER) RETURN NUMBER;
END HT_INVOICE_CALCULATIONS;
/

--HT_INVOICES PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY HT_INVOICE_CALCULATIONS AS
  -- Calculate the subtotal
  FUNCTION CALCULATE_SUBTOTAL(booking_id IN NUMBER) RETURN NUMBER IS
    v_subtotal HT_INVOICES.SUBTOTAL%TYPE;
    v_cost_per_night HT_ROOM_TYPES.COST_PER_NIGHT%TYPE;
    v_check_in HT_BOOKINGS.CHECK_IN%TYPE;
    v_check_out HT_BOOKINGS.CHECK_OUT%TYPE;
    v_num_nights NUMBER;
  BEGIN
    -- Get the cost_per_night and check-in/check-out dates for the specific booking
    SELECT COST_PER_NIGHT 
    INTO v_cost_per_night
    FROM (
        SELECT r.COST_PER_NIGHT 
        FROM HT_BOOKINGS b
        JOIN HT_ROOM_TYPES r ON b.ROOM_TY_ID = r.ROOM_TY_ID
        WHERE b.BOOKING_ID = booking_id
        AND ROWNUM = 1
    );


 
    SELECT  CHECK_IN, CHECK_OUT
    INTO v_check_in, v_check_out
    FROM HT_BOOKINGS 
    WHERE BOOKING_ID = booking_id;
    
    -- Calculate the number of nights for the booking
    v_num_nights := v_check_out - v_check_in;
    
    -- Calculate the subtotal by multiplying the cost_per_night with the number of nights
    v_subtotal := v_cost_per_night * v_num_nights;
    
    RETURN v_subtotal;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0; -- Return 0 if no booking is found
  END CALCULATE_SUBTOTAL;
  
  --  Calculate the tax amount
  FUNCTION CALCULATE_TAX(booking_id IN NUMBER) RETURN NUMBER IS
    v_tax_rate CONSTANT NUMBER(5, 2) := 0.13; -- 13% tax rate (assuming Ontario tax rate)
    v_subtotal HT_INVOICES.SUBTOTAL%TYPE;
    v_tax_amount HT_INVOICES.TAX%TYPE;
  BEGIN
    v_subtotal := CALCULATE_SUBTOTAL(booking_id);
    v_tax_amount := v_subtotal * v_tax_rate;
    
    RETURN v_tax_amount;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0; -- Return 0 if no booking is found
  END CALCULATE_TAX;
  
  -- Calculate the total amount
  FUNCTION CALCULATE_TOTAL(booking_id IN NUMBER) RETURN NUMBER IS
    v_subtotal HT_INVOICES.SUBTOTAL%TYPE;
    v_tax_amount HT_INVOICES.TAX%TYPE;
    v_total HT_INVOICES.TOTAL%TYPE;
  BEGIN
    v_subtotal := CALCULATE_SUBTOTAL(booking_id);
    v_tax_amount := CALCULATE_TAX(booking_id);
    v_total := v_subtotal + v_tax_amount;
    
    RETURN v_total;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0; -- Return 0 if no booking is found
  END CALCULATE_TOTAL;
END HT_INVOICE_CALCULATIONS;
/
--End of package --

-- Trigger that inserts data into HT_INVOICES
CREATE OR REPLACE TRIGGER TRG_INSERT_HT_INVOICE
FOR INSERT ON HT_BOOKINGS
COMPOUND TRIGGER

  TYPE t_booking_data IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_booking_ids t_booking_data;
  v_counter PLS_INTEGER := 0;

AFTER EACH ROW IS
BEGIN
  v_counter := v_counter + 1;
  v_booking_ids(v_counter) := :NEW.BOOKING_ID;
END AFTER EACH ROW;

AFTER STATEMENT IS
  v_subtotal HT_INVOICES.SUBTOTAL%TYPE;
  v_tax_amount HT_INVOICES.TAX%TYPE;
  v_total HT_INVOICES.TOTAL%TYPE;
BEGIN
  FOR i IN 1..v_counter LOOP
    -- Calculate the invoice details using the package functions
    v_subtotal := HT_INVOICE_CALCULATIONS.CALCULATE_SUBTOTAL(v_booking_ids(i));
    v_tax_amount := HT_INVOICE_CALCULATIONS.CALCULATE_TAX(v_booking_ids(i));
    v_total := HT_INVOICE_CALCULATIONS.CALCULATE_TOTAL(v_booking_ids(i));
  
    -- Insert the calculated values into HT_INVOICES table
    INSERT INTO HT_INVOICES (INVOICE_ID, BOOKING_ID, SUBTOTAL, TAX, TOTAL)
    VALUES (invoices_invoice#_seq.NEXTVAL, v_booking_ids(i), v_subtotal, v_tax_amount, v_total);
  END LOOP;
END AFTER STATEMENT;
END TRG_INSERT_HT_INVOICE;
/

--END OF TRIGGER
--  Trigger that updates corresponding invoices
CREATE OR REPLACE TRIGGER TRG_UPDATE_HT_INVOICE_BOOKING
AFTER UPDATE ON HT_BOOKINGS
FOR EACH ROW
DECLARE
  v_subtotal HT_INVOICES.SUBTOTAL%TYPE;
  v_tax_amount HT_INVOICES.TAX%TYPE;
  v_total HT_INVOICES.TOTAL%TYPE;
BEGIN
  IF :OLD.NUM_ADULTS <> :NEW.NUM_ADULTS OR
     :OLD.NUM_CHILDREN <> :NEW.NUM_CHILDREN OR
     :OLD.CHECK_IN <> :NEW.CHECK_IN OR
     :OLD.CHECK_OUT <> :NEW.CHECK_OUT THEN

    -- Recalculate the invoice details using the package functions
    v_subtotal := HT_INVOICE_CALCULATIONS.CALCULATE_SUBTOTAL(:NEW.BOOKING_ID);
    v_tax_amount := HT_INVOICE_CALCULATIONS.CALCULATE_TAX(:NEW.BOOKING_ID);
    v_total := HT_INVOICE_CALCULATIONS.CALCULATE_TOTAL(:NEW.BOOKING_ID);

    -- Update the corresponding invoice in HT_INVOICES table
    UPDATE HT_INVOICES
    SET SUBTOTAL = v_subtotal,
        TAX = v_tax_amount,
        TOTAL = v_total
    WHERE BOOKING_ID = :NEW.BOOKING_ID;
  END IF;
END;
/

--Trigger that deletes an invoice when a booking is canceled
CREATE OR REPLACE TRIGGER TRG_CANCEL_BOOKING
AFTER DELETE ON HT_BOOKINGS
FOR EACH ROW
BEGIN
   DELETE FROM HT_INVOICES
   WHERE BOOKING_ID = :OLD.BOOKING_ID;
END;
/



--Trigger to update invoices if a room's price changes 
CREATE OR REPLACE TRIGGER TRG_UPDATE_INVOICES_ROOM_PRICE
AFTER UPDATE OF COST_PER_NIGHT ON HT_ROOM_TYPES
FOR EACH ROW
DECLARE
  v_booking_id HT_BOOKINGS.BOOKING_ID%TYPE;
  v_new_cost_per_night HT_ROOM_TYPES.COST_PER_NIGHT%TYPE;
  v_old_cost_per_night HT_ROOM_TYPES.COST_PER_NIGHT%TYPE;
BEGIN
  -- Get the new and old values of COST_PER_NIGHT
  v_new_cost_per_night := :NEW.COST_PER_NIGHT;
  v_old_cost_per_night := :OLD.COST_PER_NIGHT;
  
  -- Check if there is a change in COST_PER_NIGHT
  IF v_new_cost_per_night != v_old_cost_per_night THEN
    -- Get the booking_id associated with the updated room type
    SELECT b.BOOKING_ID
    INTO v_booking_id
    FROM HT_BOOKINGS b
    WHERE b.ROOM_TY_ID = :NEW.ROOM_TY_ID;
    
    -- Update the corresponding invoice with the new subtotal, tax, and total
    UPDATE HT_INVOICES i
    SET i.SUBTOTAL = HT_INVOICE_CALCULATIONS.CALCULATE_SUBTOTAL(v_booking_id),
        i.TAX = HT_INVOICE_CALCULATIONS.CALCULATE_TAX(v_booking_id),
        i.TOTAL = HT_INVOICE_CALCULATIONS.CALCULATE_TOTAL(v_booking_id)
    WHERE i.BOOKING_ID = v_booking_id;
  END IF;
END;
/

-- Procedure to increase room cost per night by 3%
CREATE OR REPLACE PROCEDURE INCREASE_ROOM_COST AS
BEGIN
  -- Update each row's COST_PER_NIGHT by increasing it by 3%
  UPDATE HT_ROOM_TYPES
  SET COST_PER_NIGHT = COST_PER_NIGHT * 1.03;

DBMS_OUTPUT.PUT_LINE('Room cost updated.');
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END INCREASE_ROOM_COST;
/


--Cancel booking procedure
CREATE OR REPLACE PROCEDURE CANCEL_BOOKING(
  p_booking_id IN HT_BOOKINGS.BOOKING_ID%TYPE
) AS
BEGIN
  
  -- Delete the booking
  DELETE FROM HT_BOOKINGS
  WHERE BOOKING_ID = p_booking_id;
  
  -- Delete the corresponding invoice
  DELETE FROM HT_INVOICES
  WHERE BOOKING_ID = p_booking_id;
  DBMS_OUTPUT.PUT_LINE('Booking '|| p_booking_id || ' cancelled.');
  
  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20001, 'Booking not found.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END CANCEL_BOOKING;
/


--Procedure using cursor to increase salary of each staff by 5%

CREATE OR REPLACE PROCEDURE INCREASE_SALARY AS
  CURSOR c_staffs IS
    SELECT STAFF_ID, STF_NAME, SALARY
    FROM HT_STAFFS
    FOR UPDATE; -- Added FOR UPDATE here

  v_staff_id HT_STAFFS.STAFF_ID%TYPE;
  v_stf_name HT_STAFFS.STF_NAME%TYPE;
  v_old_salary HT_STAFFS.SALARY%TYPE;
  v_new_salary HT_STAFFS.SALARY%TYPE;
BEGIN
  OPEN c_staffs; 

  LOOP
    FETCH c_staffs INTO v_staff_id, v_stf_name, v_old_salary;
    EXIT WHEN c_staffs%NOTFOUND; -- Exit loop when no more rows

    -- Calculate the new salary (increase old salary by 5%)
    v_new_salary := v_old_salary * 1.05;

    -- Update the staff's salary in the table
    UPDATE HT_STAFFS
    SET SALARY = v_new_salary
    WHERE CURRENT OF c_staffs;

    -- Display the old and new salary
    DBMS_OUTPUT.PUT_LINE('Staff ID: ' || v_staff_id || ', Name: ' || v_stf_name ||
                         ', Old Salary: ' || v_old_salary || ', New Salary: ' || v_new_salary);
  END LOOP;

  CLOSE c_staffs; 
END;
/


-- 

--indexes 
CREATE INDEX Invoice_Total_Idx
         on HT_INVOICES(INVOICE_ID, BOOKING_ID, TOTAL);

CREATE INDEX  Room_Availability_idx
      on HT_ROOMS(ROOM_ID, AVAILABILITY);

CREATE INDEX Room_RoomCost_idx
      on HT_ROOM_TYPES(ROOM_TY_ID, TYPE_NAME, COST_PER_NIGHT);

CREATE INDEX Hotel_HotelName_idx
  on HT_HOTELS(HOTEL_ID, HOTEL_NAME);
  



