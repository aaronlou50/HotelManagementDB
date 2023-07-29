
DROP TABLE HT_INVOICES;
DROP TABLE HT_SERVICE_CHARGES;
DROP TABLE HT_BOOKINGS;
DROP TABLE HT_ROOMS;
DROP TABLE HT_AMENITIES;
DROP TABLE HT_ROOM_TYPES;
DROP TABLE HT_STAFFS;
DROP TABLE HT_STAFF_TYPES;
DROP TABLE HT_SERVICE_CHARGES;
DROP TABLE HT_SERVICES;
DROP TABLE HT_HOTELS;
DROP TABLE HT_MEMBERS;

--DROP SEQUENCES
DROP SEQUENCE HOTELS_HOTEL#_SEQ;
DROP SEQUENCE MEMBERS_MEMBER#_SEQ;
DROP SEQUENCE roomty_roomty#_SEQ;
DROP SEQUENCE staffty_staffty#_SEQ;
DROP SEQUENCE staffs_staff#_SEQ;
DROP SEQUENCE ROOMS_ROOM#_SEQ;
DROP SEQUENCE bookings_booking#_SEQ;
DROP SEQUENCE invoices_invoice#_SEQ;

-- Drop statements for packages, procedures, and indexes

DROP PACKAGE HT_INVOICE_CALCULATIONS;
DROP TRIGGER TRG_INSERT_HT_INVOICE;
DROP TRIGGER TRG_UPDATE_HT_INVOICE_BOOKING;
DROP TRIGGER TRG_CANCEL_BOOKING_UPDATE_INVOICES;
DROP TRIGGER TRG_UPDATE_INVOICES_ROOM_PRICE;
DROP PROCEDURE INCREASE_ROOM_COST;
DROP PROCEDURE CANCEL_BOOKING;
DROP PROCEDURE INCREASE_SALARY;
-- DROP INDEXES
DROP INDEX Invoice_Total_Idx;
DROP INDEX Room_Availability_idx;
DROP INDEX Room_RoomCost_idx;
DROP INDEX Hotel_HotelName_idx;
-- TABLE HT_MEMBERS 
CREATE TABLE HT_MEMBERS(
    MEMBER_ID INT NOT NULL,
    FIRSTNAME VARCHAR2(30) NOT NULL,
    LASTNAME VARCHAR2(30) NOT NULL,
    MEMBER_SINCE DATE NOT NULL,
    STREET_ADDRESS VARCHAR2(30) NOT NULL,
    CITY VARCHAR2(30) NOT NULL,
    STATE VARCHAR2(30) NOT NULL,
    COUNTRY VARCHAR2(30) NOT NULL,
    POSTAL_CODE VARCHAR2(30) NOT NULL,
    PHONE VARCHAR2(30) NOT NULL,
    EMAIL VARCHAR2(30) NOT NULL,
    PRIMARY KEY(MEMBER_ID)
);

-- TABLE HT_HOTELS 
CREATE TABLE HT_HOTELS(
    HOTEL_ID INT NOT NULL,
    HOTEL_NAME VARCHAR2(30) NOT NULL,
    CITY VARCHAR2(30) NOT NULL,
    COUNTRY VARCHAR2(30) NOT NULL,
    REGION VARCHAR2(30) NOT NULL,
    PRIMARY KEY(HOTEL_ID)
);

-- TABLE HT_SERVICES 
-- CREATE TABLE HT_SERVICES(
--     SERVICES_ID INT NOT NULL,
--     NAME VARCHAR2(30) NOT NULL,
--     COST INT NOT NULL,
--     PRIMARY KEY(SERVICES_ID)
-- );

-- TABLE HT_ROOM_TYPES  
CREATE TABLE HT_ROOM_TYPES(
    ROOM_TY_ID INT NOT NULL,
    TYPE_NAME VARCHAR2(100) NOT NULL,
    COST_PER_NIGHT NUMBER(10,2) NOT NULL,
    PRIMARY KEY(ROOM_TY_ID)
);
-- TABLE HT_STAFF_TYPES 
-- TYPE NAME e.g., Cleaning crew, Booking account officer, manager 
CREATE TABLE HT_STAFF_TYPES(
    STAFF_TY_ID INT NOT NULL,
    TYPE_NAME VARCHAR2(100) NOT NULL,
    PRIMARY KEY(STAFF_TY_ID)
);




-- TABLE HT_AMENITIES 
-- CREATE TABLE HT_AMENITIES(
--     AMENITY_ID INT NOT NULL,
--     HOTEL_ID INT,
--     AMT_NAME VARCHAR2(30) NOT NULL,
--     AMT_DESC VARCHAR2(50) NOT NULL,
--     PRIMARY KEY(AMENITY_ID),
--     CONSTRAINT FK_HOTEL_ID FOREIGN KEY(HOTEL_ID) REFERENCES HT_HOTELS(HOTEL_ID)
-- );
--TABLE HT_STAFFS
CREATE TABLE HT_STAFFS(
    STAFF_ID INT NOT NULL,
    STF_NAME VARCHAR2 (100) NOT NULL,
    SALARY NUMBER(10,2), 
    STAFF_TY_ID INT NOT NULL,
    MANAGER_ID INT,

    PRIMARY KEY (STAFF_ID),
    
    CONSTRAINT FK_STAFF_TY_ID_STAFF FOREIGN KEY(STAFF_TY_ID) REFERENCES HT_STAFF_TYPES(STAFF_TY_ID),
    CONSTRAINT FK_MANAGER_ID FOREIGN KEY(MANAGER_ID) REFERENCES HT_STAFFS (STAFF_ID)
);

-- TABLE HT_ROOMS
-- STAFF ID == PEOPLE WHO CLEAN THE ROOM
CREATE TABLE HT_ROOMS(
    ROOM_ID INT NOT NULL,
    HOTEL_ID INT NOT NULL,
    ROOM_TY_ID INT NOT NULL,
    
    AVAILABILITY VARCHAR2(50),
    STAFF_ID INT NOT NULL,
    PRIMARY KEY(ROOM_ID),
    CONSTRAINT FK_HOTEL_ID_ROOMS FOREIGN KEY(HOTEL_ID) REFERENCES HT_HOTELS(HOTEL_ID),
    CONSTRAINT FK_ROOM_TY_ID_ROOMS FOREIGN KEY(ROOM_TY_ID) REFERENCES HT_ROOM_TYPES(ROOM_TY_ID),
    CONSTRAINT FK_STAFF_ID_ROOMS FOREIGN KEY(STAFF_ID) REFERENCES HT_STAFFS(STAFF_ID)


);
-- CREATE TABLE HT_HOTELS_ROOMS(
--     ROOM_ID INT NOT NULL,
--     HOTEL_ID INT NOT NULL,
--     COST_PER_NIGHT NUMBER(5,2) NOT NULL,
--     AVAILABILITY VARCHAR2(20),
--     PRIMARY KEY(ROOM_ID),
--     CONSTRAINT FK_HOTEL_ID_ROOMS FOREIGN KEY(HOTEL_ID) REFERENCES HT_HOTELS(HOTEL_ID)
-- )
-- CREATE TABLE HT_ROOMS_ROOMTYPES(
--     ROOM_ID INT NOT NULL,
--     ROOM_TY_ID INT NOT NULL,
--     COST_PER_NIGHT NUMBER(5,2) NOT NULL,
--     AVAILABILITY VARCHAR2(20),
--     PRIMARY KEY(ROOM_ID),
--     CONSTRAINT FK_ROOM_TY_ID_ROOMS FOREIGN KEY(ROOM_TY_ID) REFERENCES HT_ROOM_TYPES(ROOM_TY_ID)
-- )

-- TABLE HT_BOOKINGS
-- STAFF ID == PEOPLE WHO MANAGE THE BOOKING
CREATE TABLE HT_BOOKINGS(
    BOOKING_ID INT NOT NULL,
    MEMBER_ID INT NOT NULL,
    HOTEL_ID INT NOT NULL,
    ROOM_TY_ID INT NOT NULL,
    CHECK_IN DATE,
    CHECK_OUT DATE,
    NUM_ADULTS INT,
    NUM_CHILDREN INT,
    NUM_PETS INT ,
    STAFF_ID INT NOT NULL,
    PRIMARY KEY(BOOKING_ID),
    CONSTRAINT FK_MEMBER_ID_BOOKINGS FOREIGN KEY(MEMBER_ID) REFERENCES HT_MEMBERS(MEMBER_ID),
    CONSTRAINT FK_HOTEL_ID_BOOKINGS FOREIGN KEY(HOTEL_ID) REFERENCES HT_HOTELS(HOTEL_ID),
    CONSTRAINT FK_ROOM_TY_ID_BOOKINGS FOREIGN KEY(ROOM_TY_ID) REFERENCES HT_ROOM_TYPES(ROOM_TY_ID),
    CONSTRAINT FK_STAFF_ID_BOOKINGS FOREIGN KEY(STAFF_ID) REFERENCES HT_STAFFS(STAFF_ID)
    
);



-- TABLE HT_SERVICE_CHARGES
-- CREATE TABLE HT_SERVICE_CHARGES(
--     SERVICE_CHARGE_ID INT NOT NULL,
--     BOOKING_ID INT NOT NULL,
--     SERVICE_ID INT NOT NULL,
--     PRIMARY KEY(SERVICE_CHARGE_ID),
--     CONSTRAINT FK_BOOKING_ID_CHARGES FOREIGN KEY(BOOKING_ID) REFERENCES HT_BOOKINGS(BOOKING_ID),
--     CONSTRAINT FK_SERVICE_ID_CHARGES FOREIGN KEY(SERVICE_ID) REFERENCES HT_SERVICES(SERVICES_ID)
-- );

-- TABLE HT_INVOICES
CREATE TABLE HT_INVOICES(
    INVOICE_ID INT NOT NULL,
    BOOKING_ID INT NOT NULL,
   

    SUBTOTAL NUMBER(10,2) NOT NULL,
    TAX NUMBER(10,2) NOT NULL,
    TOTAL NUMBER(10,2) NOT NULL,
    PAYMENT_DT DATE ,
    PRIMARY KEY(INVOICE_ID),
    CONSTRAINT FK_BOOKING_ID_INVOICES FOREIGN KEY(BOOKING_ID) REFERENCES HT_BOOKINGS(BOOKING_ID)
   
);



--SEQUENCES
CREATE SEQUENCE hotels_hotel#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
--ALTER SEQUENCE hotels_hotel#_seq RESTART WITH 1001;
CREATE SEQUENCE members_member#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
--ALTER SEQUENCE members_member#_seq RESTART WITH 1001;
CREATE SEQUENCE roomty_roomty#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
---ALTER SEQUENCE roomty_roomty#_seq RESTART WITH 1001;

CREATE SEQUENCE staffty_staffty#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;

--ALTER SEQUENCE staffty_staffty#_seq RESTART WITH 1001;

CREATE SEQUENCE staffs_staff#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
--ALTER SEQUENCE staffs_staff#_seq RESTART WITH 1001;

CREATE SEQUENCE rooms_room#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
--ALTER SEQUENCE rooms_room#_seq RESTART WITH 1001;

CREATE SEQUENCE bookings_booking#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
---ALTER SEQUENCE bookings_booking#_seq RESTART WITH 1001;

CREATE SEQUENCE invoices_invoice#_seq
    INCREMENT BY 1
    START WITH 1001
    NOCACHE
    NOCYCLE
    ;
--ALTER SEQUENCE invoices_invoice#_seq RESTART WITH 1001;


