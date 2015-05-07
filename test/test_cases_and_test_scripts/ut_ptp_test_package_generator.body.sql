CREATE OR REPLACE PACKAGE BODY UT_PTP_TEST_PACKAGE_GENERATOR IS

    PROCEDURE before_all
    is
    begin
      null;
    end;
    
    PROCEDURE before_each
    is
    begin
      null;
    end;

    PROCEDURE after_each
    is
    begin
      null;
    end;

    PROCEDURE after_all
    is
    begin
      null;
    end;

    -- test methods
    procedure GET_USABLE_NAME is
      l_actual VARCHAR2(1000);
      l_expected VARCHAR2(1000);
    begin

      pete_assert.eq(a_expected_in => 'not_long', a_actual_in => ptp_test_package_generator.get_usable_name('not_long'), a_comment_in => 'Short name stays the same');


      l_expected := 'longer_name_than_30_gts_shrtnd';
      --call tested code
      l_actual := PTP_TEST_PACKAGE_GENERATOR.GET_USABLE_NAME(A_NAME_IN => 'longer_name_than_30_gets_shortened');

      pete_assert.eq(a_expected_in => l_expected, a_actual_in => l_actual, a_comment_in => 'longer_name_than_30_gets_shortened');

      pete_assert.eq('p01234567890123456789012345678', ptp_test_package_generator.get_usable_name('p01234567890123456789012345678asdfladk_lkj'));
    end GET_USABLE_NAME;

    procedure GEN_PACKAGE is
    begin
      --call tested code
--      PTP_TEST_PACKAGE_GENERATOR.GEN_PACKAGE(A_PACKAGE_NAME_IN => '');
null;
     -- pete_Assert.fail('not implemented');
    end GEN_PACKAGE;
    procedure GEN_METHOD is
    begin
      --call tested code
  --    PTP_TEST_PACKAGE_GENERATOR.GEN_METHOD(A_PACKAGE_NAME_IN => '',A_METHOD_NAME_IN => '');
null;
      --pete_Assert.fail('not implemented');
    end GEN_METHOD;
END UT_PTP_TEST_PACKAGE_GENERATOR;
/
