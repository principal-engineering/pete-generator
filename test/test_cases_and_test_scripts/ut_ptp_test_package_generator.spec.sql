CREATE OR REPLACE PACKAGE UT_PTP_TEST_PACKAGE_GENERATOR IS
    --
    -- Automated tests package
    --

    --
    -- Hook method - runs once before all test procedures and other hook methods
    -- 
    PROCEDURE before_all;
    
    --
    -- Hook method - runs once before each test procedure
    -- 
    PROCEDURE before_each;

    --
    -- Hook method - runs once after each test procedure
    --
    PROCEDURE after_each;

    --
    -- Hook method - runs once after all test procedures and other hook methods
    --
    PROCEDURE after_all;

    -- test methods
    procedure test_GET_USABLE_NAME;
    procedure test_GEN_PACKAGE;
    procedure test_GEN_METHOD;
END UT_PTP_TEST_PACKAGE_GENERATOR;
/
