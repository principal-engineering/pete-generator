CREATE OR REPLACE PACKAGE ptp_test_package_generator AS

    /**
    * genereates a testing package to test a given package
    */
    PROCEDURE gen_package(a_package_name_in IN VARCHAR2);

    /**
    * generates a test method to test a given metod - it may be added to an existing testing package
    */
    PROCEDURE gen_method
    (
        a_package_name_in IN VARCHAR2,
        a_method_name_in  IN VARCHAR2
    );
END ptp_test_package_generator;
/
