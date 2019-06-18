BEGIN

  FOR i IN 1..3 LOOP

     DBMS_UTILITY.compile_schema(sys_context('userenv', 'current_schema'), false);
  END LOOP;
DBMS_SESSION.RESET_PACKAGE();
END;
/