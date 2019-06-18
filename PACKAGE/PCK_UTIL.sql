create or replace PACKAGE "PCK_UTIL" AUTHID CURRENT_USER IS


  e_assertion_error EXCEPTION;
  ASSERTION_ERROR_NUMBER CONSTANT NUMBER := -20255;
  PRAGMA EXCEPTION_INIT(e_assertion_error, -20255);

  e_custom_error EXCEPTION;
  CUSTOM_ERROR_NUMBER CONSTANT NUMBER := -20256;
  PRAGMA EXCEPTION_INIT(e_custom_error, -20256);
  
  MODULE CONSTANT VARCHAR2(30) := 'ADM_UTIL';

  --------------------------------------------------------------------------------
  -- TABLES
  --------------------------------------------------------------------------------

  /**
  * Returns TRUE if given table exists in the current user's schema; FALSE otherwise.
  *
  * @param pTableName Name of the table to be checked.
  * @return           TRUE if the table exists; FALSE otherwise.
  */
  FUNCTION TABLE_EXISTS(pTableName IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Returns TRUE if given table exists in the current user's schema; FALSE otherwise.
  *
  * @param pViewName Name of the table to be checked.
  * @return           TRUE if the table exists; FALSE otherwise.
  */
  FUNCTION VIEW_EXISTS(pViewName IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Creates a table with the given name and columns and optionally sets the INITIAL STORAGE clause
  *  for CLOB columns to 64K.
  *
  * Safe to call more than once - if the table with given name already exists, it is assummed
  *  that the table has already been created.
  *
  * The initial lob storage clause is  LOB (columns_list) STORE AS (STORAGE (INITIAL 64K)).
  *
  * @param pTableName                     The table name.
  * @param pColumnsAndDatatypeList        Comma-separated list of columns and their datatypes.
  * @param pClobColumnsListForInitStorage Optional comma-separated list of CLOB columns for which
  *                                        the INITIAL STORAGE clause should be set. This parameter
  *                                        is only required if there will be CLOB columns in the created table.
  * @param pIsIOT                         If table is index organize set to TRUE
  * @param pCompress                      If table is compressed set the level of compression in integer value
  * @raises e_assertion_error   Assertion exception if the table name has more than 30 characters.
  * @raises other               Different Oracle-specific exceptions.
  */
  PROCEDURE CREATE_TABLE(pTableName IN VARCHAR2,
                         pColumnsAndDatatypeList IN VARCHAR2,
                         pClobColumnsListForInitStorage IN VARCHAR2 DEFAULT NULL,
                         pIsIOT IN BOOLEAN DEFAULT FALSE,
                         pCompress IN INTEGER DEFAULT 0);

  /**
  *
  * Safe to call more than once - if the index with given name already exists, it is assummed
  *  that the index has already been created.
  *
  *
  * @param pIndexName                     The index name.
  * @param pTableName                     The table name.
  * @param pColumnsList                   List of indexed columns
  * @param pIndexType                     If null value then normal index is created, if BITMAP then bimtamp index is created
  * @param pLocalIdx                      Only for partition table, if true then local index is created
  * @param pCompress                      If index is compressed set the level of compression in integer value
  *
  * @raises e_assertion_error   Assertion exception if the table name has more than 30 characters.
  * @raises other               Different Oracle-specific exceptions.
  */
  PROCEDURE CREATE_INDEX(pIndexName IN VARCHAR2,
                         pTableName IN VARCHAR2,
                         pColumnsList IN VARCHAR2,
                         pIndexType IN VARCHAR2 := NULL,
                         pLocalIdx IN BOOLEAN := FALSE,
                         pCompress IN INTEGER DEFAULT 0
                         );
  /**
  * Creates a partitioned (by list) table with the given name, columns, partition key and optionally
  *  sets the INITIAL STORAGE clause for CLOB columns to 64K.
  *
  * The pPartitionSetKey argument mustn't be NULL and must be equal to one of the constants from ADM_UTIL:
  *   SET_TYPE_CONFIG, SET_TYPE_DATA, SET_TYPE_CALC, SET_TYPE_EXPORT
  *
  * Call example:
  *   ADM_UTIL.CREATE_PARTITIONED_TABLE('TEST_TABLE', 'ID_CALC_SET NUMBER, NAME VARCHAR2(30)', ADM_UTIL.SET_TYPE_CALC);
  *
  * The partition key column must be on the pColumnsAndDatatypeList list.
  *
  * Created table has one initial partition - value 0.
  *
  * Safe to call more than once - if the table with given name already exists, it is assummed
  *  that the table has already been created.
  *
  * The initial lob storage clause is: LOB (columns_list) STORE AS (STORAGE (INITIAL 64K)).
  *
  * @param pTableName                     The table name.
  * @param pColumnsAndDatatypeList        Comma-separated list of columns and their datatypes.
  * @param pPartitionSetKey               Partition key column.
  * @param pClobColumnsListForInitStorage Optional comma-separated list of CLOB columns for which
  *                                        the INITIAL STORAGE clause should be set. This parameter
  *                                        is only required if there will be CLOB columns in the created table.
  * @param pIsIOT                         If table is index organize set to TRUE
  * @param pPartitionType                 Accepted value : "LIST", "HASH", "RANGE"
  * @param pInterval                      Used only for "RANGE" partition
  * @param pNoLogging                     To disable logging (redo and undo change vector) on insert and ctas operation set 1
  * @param pCompress                      If table is compressed set the level of compression in integer value
  * @param pHashPartitionClause           The clause for hashing partition
  * @raises e_assertion_error   Assertion exception if the table name has more than 30 characters.
  * @raises e_assertion_error   Assertion exception if the partition key is invalid.
  * @raises other               Different Oracle-specific exceptions.
  */
  PROCEDURE CREATE_PARTITIONED_TABLE(pTableName IN VARCHAR2,
                                     pColumnsAndDatatypeList IN VARCHAR2,
                                     pPartitionSetKey IN VARCHAR2,
                                     pClobColumnsListForInitStorage IN VARCHAR2 DEFAULT NULL,
                                     pPartitionType IN VARCHAR2 DEFAULT 'LIST',
                                     pInterval INTEGER DEFAULT 1,
                                     pNoLogging INTEGER DEFAULT 0,
                                     pCompress INTEGER DEFAULT 0,
                                     pIsIOT IN BOOLEAN DEFAULT FALSE,
                                     pHashPartitionClause IN VARCHAR2 DEFAULT NULL);

  /**
  * Renames the given table to have the specified name.
  *
  * *Important*
  * 1. Procedure DOES NOT change names of objects referenced by synonyms - this
  *     has to be accomplished using other procedures!
  * 2. Grants to the changed table aren't lost! Oracle automatically handles
  *     them - the privileges don't have to be granted again manually.
  *
  * Safe to call more than once - if the original table doesn't exist, and a table
  *  with the new name exist, it is assummed that the name has already been changed.
  *
  * @param pOldTableName        Name of the existing table.
  * @param pNewTableName        The new name.
  * @raises e_assertion_error   If either:
  *                               - tables with both old and new names already exist
  *                               - there are no tables with either the old or the new name
  */
  PROCEDURE RENAME_TABLE(pOldTableName VARCHAR2,
                         pNewTableName VARCHAR2);

  /**
  * Renames the given table to have the specified name.
  *
  * *Important*
  * 1. Procedure DOES NOT change names of objects referenced by synonyms - this
  *     has to be accomplished using other procedures!
  * 2. Grants to the changed table aren't lost! Oracle automatically handles
  *     them - the privileges don't have to be granted again manually.
  *
  * Safe to call more than once - if the original table doesn't exist, and a table
  *  with the new name exist, it is assummed that the name has already been changed.
  *
  * @param pOldViewName        Name of the existing table.
  * @param pNewViewName        The new name.
  * @raises e_assertion_error   If either:
  *                               - tables with both old and new names already exist
  *                               - there are no tables with either the old or the new name
  */
  PROCEDURE RENAME_VIEW(pOldViewName VARCHAR2,
                        pNewViewName VARCHAR2);

  /**
  * Sets comment on specified table.
  * The pComment parameter may be NULL to remove the comment from the table.
  * Safe to call more than once.
  *
  * @param  pTableName         The table name.
  * @param  pComment           Comment for the table; may be NULL.
  * @raises e_assertion_error  When the table doesn't exist.
  */
  PROCEDURE SET_COMMENT_ON_TABLE(pTableName IN VARCHAR2,
                                 pComment IN VARCHAR2);

  --------------------------------------------------------------------------------
  -- COLUMNS
  --------------------------------------------------------------------------------

  /**
  * Returns TRUE if given column exists in the specified table in the current user's schema; FALSE otherwise.
  *
  * @param pTableName   Table in which the column should exist.
  * @param pColumnName  Name of the column to be checked.
  * @return             TRUE if the column exists in the table; FALSE otherwise.
  */
  FUNCTION COLUMN_EXISTS(pTableName IN VARCHAR2,
                         pColumnName IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Adds given column to the specified table.
  * The pDataType parameter should NOT contain the NOT NULL clause, but it may have the DEFAULT clause.
  *
  * *Important* - if the pDataType contains CLOB character string, a LOB STORAGE CLAUSE
  *               will be appended to the ALTER statement while adding the new column.
  *               This clause is meant to save space required by LOB segments.
  *
  * Safe to call more than once - if the target table already has a column with the given name,
  *  exception will not be thrown. The data type is not checked in this operation - only the column's name.
  *
  * @param pTableName         The table name.
  * @param pColumnName        The column to be added.
  * @param pDataType          Type of the new column. Mustn't contain the NOT NULL clause,
  *                             but may contain the DEFAULT clause.
  * @param e_assertion_error  If the table does not exist or the data type contains the NOT NULL clause.
  * @param Oracle-specific exception if the data type or column's name is invalid.
  */
  PROCEDURE ADD_COLUMN(pTableName IN VARCHAR2,
                       pColumnName IN VARCHAR2,
                       pDataType IN VARCHAR2);

  /**
  * Adds given column to the specified table, plus
  *   if table already contain some column then modyfy this column type and try copy data from base
  *   if column data modyfications failed then exceptions is raised, data should be fixed and run again manually
  *
  * @param pTableName   The table name.
  * @param pColumnName  The column to be added.
  * @param pDataType    Type of the new column.
  */
  PROCEDURE CHANGE_COLUMN_TYPE(pTableName  IN VARCHAR2,
                               pColumnName IN VARCHAR2,
                               pDataType   IN VARCHAR2);

  /**
  * Drops given column from the specified table.
  *
  * *Important* You mustn't drop columns from configuration tables (i. e. tables which have the ID_CONFIG_SET column):
  *               it will cause an exception to be thrown.
  *
  * Safe to call more than once - if the column does not exist, an exception will not be thrown.
  *
  * @raises e_assertion_error When the table does not exist or it is a configuration table.
  * @raises -12983            When the column is the only column in the table
  * @raises -12991            When the column is a part of a multi column constraint
  * @raises -12992            When the column is used in a foreign key constraint
  */
  PROCEDURE DROP_COLUMN(pTableName IN VARCHAR2,
                        pColumnName IN VARCHAR2);

  /**
  * Renames the column to have the specified name.
  * Safe to call more than once - if the column with the old name doesn't exist,
  *  and there is a column with the new name, exception will NOT be thrown.
  *
  * @param  pTableName          The table name.
  * @param  pOldColumnName      Current name of the column.
  * @param  pNewColumnName      New name for the column.
  * @raises e_assertion_error   If either:
  *                               - the table does not exist or
  *                               - columns with both old and new names already exist in the table
  *                               - there are no columns with either the old or the new name in the table
  *                               - the new name is too long
  */
  PROCEDURE RENAME_COLUMN(pTableName IN VARCHAR2,
                          pOldColumnName IN VARCHAR2,
                          pNewColumnName IN VARCHAR2);

  /**
  * Sets the default value for the given column in the specified table.
  *
  * *Important*
  * 1. Numerical values must be specified with a dot (.) as the decimal separator.
  * 2. Character strings must be enclosed in apostrophes ('), for example: 'YES'
  * 3. If a column had a default value, it is not possible to remove it
  *     completely - it may be overriden with a NULL default value
  *     if NULL is passed as the pDefaultValue parameter.
  *
  * Safe to call more than once.
  *
  * @param pTableName          The table name.
  * @param pColumnName         The column name.
  * @param pDefaultValue       Default value. May be NULL to make the column receive NULL value by default.
  * @raises e_assertion_error  When the table or the column doesn't exist.
  */
  PROCEDURE SET_COLUMN_DEFAULT_VALUE(pTableName IN VARCHAR2,
                                     pColumnName IN VARCHAR2,
                                     pDefaultValue IN VARCHAR2);

  /**
  * Sets comment on the given column in the specified table.
  * The pComment parameter may be NULL to remove the comment from the column.
  * Safe to call more than once.
  *
  * @param  pTableName         The table name.
  * @param  pColumnName        The column name.
  * @param  pComment           Comment for the column; may be NULL.
  * @raises e_assertion_error  When the table or the column doesn't exist.
  */
  PROCEDURE SET_COMMENT_ON_COLUMN(pTableName IN VARCHAR2,
                                  pColumnName IN VARCHAR2,
                                  pComment IN VARCHAR2);

  --------------------------------------------------------------------------------
  -- SYNONYMS
  --------------------------------------------------------------------------------

  /**
  * Drop the specified synonym from invoker's schema.
  * Safe to call more than once - if the synonym doesn't exist, it is assummed
  *  that is has already been dropped.
  *
  * @param pSynonymName The synonym name.
  */
  PROCEDURE DROP_SYNONYM(pSynonymName IN VARCHAR2);

  /**
  * Creates synonym with given name for target object owned by pOwnerShortName.
  * The target object doesn't have to exist for this procedure to succeed.
  *
  * *Important* - this procedure does not move synonyms - if there is a synonym
  *               with given name, but the owner or the target object name differs,
  *               the synonym WILL NOT be switched to the specified object.
  *               Use the MOVE_SYNONYM procedure instead for this purpose.
  *
  * Safe to call more than once - if the synonym exists, nothing happens.
  *
  * @param pSynonymName     The name of the synonym to be created.
  * @param pOwnerShortName  Short name of the target object's owner, for example DSA or FIN.
  * @param pTargetName      The name of the target object.
  */
  PROCEDURE CREATE_SYNONYM(pSynonymName IN VARCHAR2,
                           pOwnerShortName IN VARCHAR2,
                           pTargetName IN VARCHAR2);

  /**
  * Moves existing synonym to point to the target object owned by pOwnerShortName.
  * The target object doesn't have to exist for this procedure to succeed.
  *
  * *Important* - the synonym has to exist, otherwise, an assertion error will be thrown.
  *
  * Safe to call more than once.
  *
  * @param pSynonymName        The name of the synonym to be created.
  * @param pOwnerShortName     Short name of the target object's owner, for example DSA or FIN.
  * @param pTargetName         The name of the target object.
  * @raises e_assertion_error  When the synonym doesn't exist.
  */
  PROCEDURE MOVE_SYNONYM(pSynonymName IN VARCHAR2,
                         pOwnerShortName IN VARCHAR2,
                         pTargetName IN VARCHAR2);

  --------------------------------------------------------------------------------
  -- CONSTRAINTS
  --------------------------------------------------------------------------------

  /**
  * Returns TRUE if the given column is NULLABLE (allows NULLs) in the specified table, FALSE otherwise.
  * Does NOT check the existence of either the table or the column.
  *
  * @param pTableName   Name of the table.
  * @param pColumnName  Name of the column to be checked.
  * @return             TRUE if the column is NULLable; FALSE otherwise.
  */
  FUNCTION IS_COLUMN_NULLABLE(pTableName  IN VARCHAR2,
                              pColumnName IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Makes specified column NULLable.
  *
  * Safe to call more than once - if the column is already NULLable,
  *  the procedure will not throw an exception.
  *
  * @param  pTableName         The table name.
  * @param  pColumnName        The column name.
  * @raises e_assertion_error  If either the table or the column does not exist.
  * @raises -01451             If it is not possible to change the column to allow NULLs,
  *                             for example, when it is a part of a PRIMARY KEY.
  */
  PROCEDURE MAKE_COLUMN_NULLABLE(pTableName  IN VARCHAR2,
                                 pColumnName IN VARCHAR2);

  /**
  * Makes specified column NOT NULLable.
  *
  * Safe to call more than once - if the column is already NOT NULLable,
  *  the procedure will not throw an exception.
  *
  * @param  pTableName         The table name.
  * @param  pColumnName        The column name.
  * @raises e_assertion_error  If either the table or the column does not exist.
  * @raises -02296             If NULL values were found in the column.
  */
  PROCEDURE MAKE_COLUMN_NOT_NULLABLE(pTableName  IN VARCHAR2,
                                     pColumnName IN VARCHAR2);

  /**
  * Returns the name of the NOT NULL constraint on the given column in the specified table.
  * If it doesn't exist, NULL is returned.
  * To find out the name of the constraint:
  *   - all constraints on the specified table are selected that are checking exactly one column
  *   - then, the SEARCH_CONDITION is checked using the LIKE pattern: %pColumnName%IS%NOT%NULL%
  * This approach is required since the SEARCH_CONDITION column in the USER_CONSTRAINTS view has LONG datatype,
  *  and selecting LONG column in a PL/SQL automatically converts it to VARCHAR2, allowing checking its content.
  *
  * @param pTableName   Name of the table.
  * @param pColumnName  Name of the column.
  * @return             Name of the NOT NULL constraint if it exists; NULL otherwise.
  */
  FUNCTION GET_NOT_NULL_CONSTRAINT(pTableName IN VARCHAR2,
                                   pColumnName IN VARCHAR2) RETURN VARCHAR2;

  /**
  * Adds a PRIMARY KEY constraint with the given name on the pTableName table on the columns
  *  specified as a comma-separated list.
  *
  * If the table is partitioned, the index will be created with the USING INDEX LOCAL clause.
  *
  * Safe to call more than once - if the constraint already exists,
  *  it is assummed that it has already been added.
  *
  * @param pTableName          The table name.
  * @param pConstraintName     The constraint name.
  * @param pColumnsList        Comma-separated list of columns on which the PRIMARY KEY should be created.
  * @raises e_assertion_error  If the table does not exist or the name of the constraint is invalid.
  */
  PROCEDURE ADD_PRIMARY_KEY_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2);
                                       
  /**
  * Adds a FOREIGN KEY constraint with the given name on the pTableName table on the columns
  *  specified as a comma-separated list.
  *
  * If the table is partitioned, the index will be created with the USING INDEX LOCAL clause.
  *
  * Safe to call more than once - if the constraint already exists,
  *  it is assummed that it has already been added.
  *
  * @param pTableName          The table name.
  * @param pConstraintName     The constraint name.
  * @param pColumnsList        Comma-separated list of columns on which the FOREIGN KEY should be created.
  * @raises e_assertion_error  If the table does not exist or the name of the constraint is invalid.
  */
  PROCEDURE ADD_FOREIGN_KEY_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2,
                                       pReferenceTableName IN VARCHAR2,
                                       pReferenceColumnList IN VARCHAR2);
    
  /**
  * Adds a NOT NULL constraint with the given name on the pTableName table on the columns
  *  specified as a comma-separated list.
  *
  * If the table is partitioned, the index will be created with the USING INDEX LOCAL clause.
  *
  * Safe to call more than once - if the constraint already exists,
  *  it is assummed that it has already been added.
  *
  * @param pTableName          The table name.
  * @param pConstraintName     The constraint name.
  * @param pColumnsList        Comma-separated list of columns on which the NOT NULL constraint should be created.
  * @raises e_assertion_error  If the table does not exist or the name of the constraint is invalid.
  */
  PROCEDURE ADD_NOT_NULL_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2);

  /**
  * Adds a UNIQUE constraint with the given name on the pTableName table on the columns
  *  specified as a comma-separated list.
  *
  * Safe to call more than once - if the constraint already exists,
  *  it is assummed that it has already been added.
  *
  * @param pTableName          The table name.
  * @param pConstraintName     The constraint name.
  * @param pColumnsList        Comma-separated list of columns on which the UNIQUE constraint should be created.
  * @raises e_assertion_error  If the table does not exist or the name of the constraint is invalid.
  */
  PROCEDURE ADD_UNIQUE_CONSTRAINT(pTableName IN VARCHAR2,
                                  pConstraintName IN VARCHAR2,
                                  pColumnsList IN VARCHAR2);

 /**
  * Adds a CHECK constraint with the given name on the pTableName table with specified condition.
  *
  * Safe to call more than once - if the constraint already exists,
  *  it is assummed that it has already been added.
  *
  * @param pTableName          The table name.
  * @param pConstraintName     The constraint name.
  * @param pCheckCondition     The condition for the check.
  * @raises e_assertion_error  If the table does not exist or the name of the constraint is invalid.
  */
  PROCEDURE ADD_CHECK_CONSTRAINT(pTableName IN VARCHAR2,
                                 pConstraintName IN VARCHAR2,
                                 pCheckCondition IN VARCHAR2);

  /**
  * Returns TRUE if the given table has a constraint with the given name and type, FALSE otherwise.
  *
  * @param pTableName       The table name.
  * @param pConstraintName  The constraint name.
  * @param pConstraintType  The constraint type: R (ref constraint), U (unique), C (check), P (primary key)
  * @return                 TRUE if the constraint exists; FALSE otherwise.
  */
  FUNCTION CONSTRAINT_EXISTS(pTableName IN VARCHAR2,
                             pConstraintName IN VARCHAR2,
                             pConstraintType IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Removes specified constraint from the given table.
  *
  * If the constraint type is 'P' (PRIMARY KEY), then index with the same name
  *  will also be dropped.
  *
  * Safe to call more than once - if the constraint does not exist,
  *  it is assummed that is has already been dropped.
  *
  * @param pTableName       The table name.
  * @param pConstraintName  The constraint name.
  * @param pConstraintType  The constraint type: R (ref constraint), U (unique), C (check), P (primary key)
  *                         The type is needed to check if the constraint exists or not.
  */
  PROCEDURE DROP_CONSTRAINT(pTableName IN VARCHAR2,
                            pConstraintName IN VARCHAR2,
                            pConstraintType IN VARCHAR2);

  /**
  * Disables the given constraint on the specified table. Safe to call multiple times.
  * Will throw an Oracle-specific exception if either the table or the constraint does not exist.
  *
  * @param pTableName       The table name.
  * @param pConstraintName  The name of the constraint to be disabled.
  */
  PROCEDURE DISABLE_CONSTRAINT(pTableName IN VARCHAR2,
                               pConstraintName IN VARCHAR2);

  /**
  * Enables the given constraint on the specified table. Safe to call multiple times.
  * Will throw an Oracle-specific exception if either the table or the constraint does not exist.
  *
  * @param pTableName       The table name.
  * @param pConstraintName  The name of the constraint to be enabled.
  */
  PROCEDURE ENABLE_CONSTRAINT(pTableName IN VARCHAR2,
                              pConstraintName IN VARCHAR2);

  --------------------------------------------------------------------------------
  -- PRIVILEGES
  --------------------------------------------------------------------------------

  /**
  * Grants object privilege(s) on object in the invoker's schema
  *  to the user specified by the short Finevare name, for example, DSA or FIN.
  *
  * Safe to call more than once.
  *
  * @param  pObjectName   The name of the object on which the privilege should be granted.
  * @param  pGrantee      Short-name of the Finevare database user (for example, DSA or FIN)
  *                         which should receive the privilege.
  * @param  pPrivilege    The privilege (for example: INSERT, SELECT, EXECUTE).
  *                         A few privileges may be granted if separated by commas:
  *                           SELECT, INSERT, UPDATE
  * @param  pWithGrantOption Should the WITH GRANT OPTION be included.
  * @raises Oracle-specific exception if the object doesn't exist.
  */
  PROCEDURE GRANT_PRIVILEGE(pObjectName IN VARCHAR2,
                            pGrantee IN VARCHAR2,
                            pPrivilege IN VARCHAR2,
                            pWithGrantOption IN BOOLEAN := FALSE);

 /**
  * Revokes object privilege(s) on object in the invoker's schema
  *  from the user specified by the short Finevare name, for example, DSA or FIN.
  *
  * Safe to call more than once.
  *
  * @param  pObjectName   The name of the object on which the privilege should be revoked.
  * @param  pGrantee      Short-name of the Finevare database user (for example, DSA or FIN)
  *                         which should lose the privilege.
  * @param  pPrivilege    The privilege (for example: INSERT, SELECT, EXECUTE).
  *                         A few privileges may be revoked if separated by commas:
  *                           SELECT, INSERT, UPDATE
  * @raises Oracle-specific exception if the object doesn't exist.
  */
  PROCEDURE REVOKE_PRIVILEGE(pObjectName IN VARCHAR2,
                             pGrantee IN VARCHAR2,
                             pPrivilege IN VARCHAR2);
  ------------------------------------------------------------------------------
  -- SEQUENCE
  ------------------------------------------------------------------------------

  /**
  *
  * Safe to call more than once - if the sequence with given name already exists, it is assummed
  *  that the sequence has already been created.
  *
  *
  * @param pSeqName                  The sequence name.
  * @param pMinVal                   The sequence minimum value.
  * @param pMaxVal                   The sequence maximum value.
  * @param pStartWith                The sequence start value
  * @param pIncrementBy              The interval between sequence numbers
  * @param pCache                    Specify how many values of the sequence the database preallocates and keeps in memory for faster access
  * @param pOrder                    Specify pOrder=TRUE to guarantee that sequence numbers are generated in order of request
  *
  * @raises e_assertion_error   Assertion exception if the table name has more than 30 characters.
  * @raises other               Different Oracle-specific exceptions.
  */
  PROCEDURE CREATE_SEQUENCE(pSeqName IN VARCHAR2,
                            pMinVal IN INTEGER := NULL,
                            pMaxVal IN INTEGER := NULL,
                            pStartWith IN INTEGER := 1,
                            pIncrementBy IN INTEGER := 1,
                            pCache IN INTEGER := 100,
                            pOrder IN BOOLEAN := FALSE);

  FUNCTION OBJECT_EXISTS(pObjectName IN VARCHAR2,
                         pObjectType IN VARCHAR2) RETURN BOOLEAN;

  /**
  * Drops object of given name and type from the invoker's schema.
  * Safe to call more than once - if the object doesn't exist, it is assummed
  *  that it has already been dropped.
  *
  * Dropping CONSTRAINTs is not supported - use the DROP_CONSTRAINT procedure instead.
  *
  * You mustn't drop configuration tables, i. e. tables which have the ID_CONFIG_SET column:
  *  it will cause an exception to be thrown.
  *
  * @param pObjectName          The object name.
  * @param pObjectType          The object type.
  * @param pForce               Force drop operation also for config tables
  * @raises e_assertion_error   If you are trying to drop a configuration table.
  */
  PROCEDURE DROP_OBJECT(pObjectName IN VARCHAR2,
                        pObjectType IN VARCHAR2,
                        pForce      IN BOOLEAN DEFAULT FALSE);

  PROCEDURE COMPILE_INVALID_OBJECTS;

  /**
  * Compiles objects matching (using the LIKE operator) pObjectNamePattern natively.
  *
  * @param pObjectNamePattern Pattern against which objects' names will be matched.
  */
  PROCEDURE COMPILE_OBJECTS_NATIVELY(pObjectNamePattern VARCHAR2,pRaise IN BOOLEAN := TRUE,pPlsqlOptimizeLevel PLS_INTEGER := 2);

  PROCEDURE COMPILE_OBJECTS_NATIVELY;

  --------------------------------------------------------------------------------
  -- ASSERTIONS
  --------------------------------------------------------------------------------

  /**
  * Raises exception if pExpression is not TRUE.
  *
  * @param  pExpression       Boolean expression to be evaluated.
  * @param  pMessage          Message to be included in the thrown exception.
  * @raises e_assertion_error
  */
  PROCEDURE ASSERT(pExpression IN BOOLEAN,
                   pMessage IN VARCHAR2);

  /**
  * Raises exception if table pTableName does not exist in the invoker's schema.
  *
  * @param  pTableName          Name of the table to be checked.
  * @raises e_assertion_error
  */
  PROCEDURE ASSERT_TABLE_EXISTS(pTableName IN VARCHAR2);

  /**
  * Raises exception if column pColumnName does not exist in the table pTableName in the invoker's schema.
  *
  * @param  pTableName         Name of the table in which the column should exist.
  * @param  pColumnName        Name of the column which should exist in the table.
  * @raises e_assertion_error
  */
  PROCEDURE ASSERT_COLUMN_EXISTS(pTableName IN VARCHAR2,
                                 pColumnName IN VARCHAR2);

 /**
  * Raises exception if object pObjectName of pObjectType does not exist in the invoker's schema.
  *
  * Asserting that a constraint exists is not supported by this procedure.
  *
  * @param  pObjectName          Name of the table to be checked.
  * @param  pObjectType          The type of the object.
  * @raises e_assertion_error
  */
  PROCEDURE ASSERT_OBJECT_EXISTS(pObjectName IN VARCHAR2,
                                 pObjectType IN VARCHAR2);


END;
/
create or replace PACKAGE BODY "PCK_UTIL" IS

  PROCEDURE execute_immediate(pCode IN VARCHAR2)
  IS
  BEGIN
    EXECUTE IMMEDIATE pCode;
  END;

  FUNCTION upper_trim_validate(pName IN VARCHAR2) RETURN VARCHAR2
  IS
    vResultName VARCHAR2(4000);
  BEGIN
    vResultName := UPPER(TRIM(BOTH '"' FROM REPLACE(pName, ' ')));
    ASSERT(LENGTH(vResultName) <= 30, 'Names of objects can have at most 30 characters: ' ||
                                        pName || ' has ' || LENGTH(vResultName));

    RETURN vResultName;
  END;

  PROCEDURE raise_exception(pMessage IN VARCHAR2,
                            pKeepErrorStack IN BOOLEAN := FALSE)
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(CUSTOM_ERROR_NUMBER, pMessage, pKeepErrorStack);
  END;

  /**
  * Returns the LOB STORAGE clause with INITIAL extent size of 64K.
  *
  * @param  pColumnsList  List of columns separated by commas.
  * @return               INITIAL LOB STORAGE clause.
  */
  FUNCTION get_initial_lob_storage_clause(pColumnsList IN VARCHAR2) RETURN VARCHAR2
  IS
  BEGIN
    RETURN ' LOB (' || pColumnsList || ') STORE AS (STORAGE (INITIAL 64K))';
  END;

  FUNCTION get_initial_lob_storage_clause(pColumnName IN VARCHAR2,
                                          pDataType   IN VARCHAR2) RETURN VARCHAR2
  IS
    v_text VARCHAR2(200);
  BEGIN
    IF UPPER(TRIM(pDataType)) IN ('BLOB', 'CLOB') THEN
      v_text := ' LOB (' || pColumnName || ') STORE AS (STORAGE (INITIAL 64K))';
    ELSE
      FOR i IN (SELECT 1 FROM (
                  SELECT regexp_replace(
                           LISTAGG(UPPER(text), CHR(10)) WITHIN GROUP (ORDER BY line),
                           '[[:space:]]+',
                           CHR(32)) type_text
                    FROM user_source
                   WHERE TYPE = 'TYPE'
                     AND NAME = UPPER(TRIM(pDataType))
                     AND EXISTS (SELECT 1
                                   FROM user_types
                                  WHERE typecode  = 'COLLECTION'
                                    AND type_name = UPPER(TRIM(pDataType)))
                )
                WHERE INSTR(type_text, ' IS VARRAY') != 0)
      LOOP
        v_text := ' VARRAY ' || pColumnName || ' STORE AS LOB (STORAGE (INITIAL 64K))';
      END LOOP;
    END IF;
    RETURN v_text;
  END;

  ------------------------------------------------------------------------------
  -- TABLES
  ------------------------------------------------------------------------------

  /**
  * Returns TRUE if given table exists in the current user's schema; FALSE otherwise.
  *
  * @param pTableName Name of the table to be checked.
  * @return           TRUE if the table exists; FALSE otherwise.
  */
  FUNCTION TABLE_EXISTS(pTableName IN VARCHAR2) RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1) INTO vCnt FROM user_tables WHERE table_name = TRIM(UPPER(pTableName));
    RETURN vCnt > 0;
  END;

  /**
  * Returns TRUE if given view exists in the current user's schema; FALSE otherwise.
  *
  * @param pTableName Name of the view to be checked.
  * @return           TRUE if the view exists; FALSE otherwise.
  */
  FUNCTION VIEW_EXISTS(pViewName IN VARCHAR2) RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1) INTO vCnt FROM user_views WHERE view_name = TRIM(UPPER(pViewName));
    RETURN vCnt > 0;
  END;

  FUNCTION get_basic_create_table_ddl(pTableName IN VARCHAR2,
                                      pColumnsAndDatatypeList IN VARCHAR2,
                                      pClobColumnsListForInitStorage IN VARCHAR2 DEFAULT NULL,
                                      pIsIOT IN BOOLEAN DEFAULT FALSE,
                                      pCompress IN INTEGER DEFAULT 0)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN 'CREATE TABLE ' || pTableName ||
           '(' || pColumnsAndDatatypeList || ')' ||
           CASE WHEN pIsIOT THEN
             ' ORGANIZATION INDEX '
           END||
           CASE WHEN pIsIOT THEN
             CASE WHEN pCompress > 0 THEN
               ' COMPRESS '||pCompress||' '
             END
           ELSE
             CASE WHEN pCompress > 0 THEN
               ' COMPRESS '
             END
           END||
           CASE
             WHEN pClobColumnsListForInitStorage IS NOT NULL THEN
               get_initial_lob_storage_clause(pClobColumnsListForInitStorage)
             ELSE NULL
           END;
  END;

  PROCEDURE CREATE_TABLE(pTableName IN VARCHAR2,
                         pColumnsAndDatatypeList IN VARCHAR2,
                         pClobColumnsListForInitStorage IN VARCHAR2 DEFAULT NULL,
                         pIsIOT IN BOOLEAN DEFAULT FALSE,
                         pCompress IN INTEGER DEFAULT 0)
  IS
    vUpperTableName VARCHAR2(100);
  BEGIN
    vUpperTableName := upper_trim_validate(pTableName);

    IF TABLE_EXISTS(vUpperTableName) THEN
      RETURN;
    END IF;

    execute_immediate(
      get_basic_create_table_ddl(vUpperTableName,
                                 pColumnsAndDatatypeList,
                                 pClobColumnsListForInitStorage,
                                 pIsIOT,
                                 pCompress)
    );
  END;
  PROCEDURE CREATE_INDEX(pIndexName IN VARCHAR2,
                         pTableName IN VARCHAR2,
                         pColumnsList IN VARCHAR2,
                         pIndexType IN VARCHAR2 := NULL,
                         pLocalIdx IN BOOLEAN := FALSE,
                         pCompress IN INTEGER DEFAULT 0
                         )
  IS
    vUpperTableName VARCHAR2(100);
    vUpperIndexName VARCHAR2(100);
  BEGIN
    vUpperTableName := upper_trim_validate(pTableName);
    vUpperIndexName := upper_trim_validate(pTableName);

    IF OBJECT_EXISTS(pObjectName => pIndexName, pObjectType => 'INDEX') THEN
      RETURN;
    END IF;

    execute_immediate('CREATE '||pIndexType||' INDEX '||pIndexName||' ON '||pTableName||'('||pColumnsList||') '||
                      CASE WHEN pCompress > 0 THEN ' COMPRESS '||pCompress END||
                      CASE WHEN pLocalIdx THEN ' LOCAL' END);
  END;
  PROCEDURE CREATE_PARTITIONED_TABLE(pTableName IN VARCHAR2,
                                     pColumnsAndDatatypeList IN VARCHAR2,
                                     pPartitionSetKey IN VARCHAR2,
                                     pClobColumnsListForInitStorage IN VARCHAR2 DEFAULT NULL,
                                     pPartitionType IN VARCHAR2 DEFAULT 'LIST',
                                     pInterval INTEGER DEFAULT 1,
                                     pNoLogging INTEGER DEFAULT 0,
                                     pCompress INTEGER DEFAULT 0,
                                     pIsIOT IN BOOLEAN DEFAULT FALSE,
                                     pHashPartitionClause IN VARCHAR2 DEFAULT NULL)
  IS
    vUpperTableName VARCHAR2(100);
  BEGIN
    vUpperTableName := upper_trim_validate(pTableName);
    IF TABLE_EXISTS(vUpperTableName) THEN
      RETURN;
    END IF;

    execute immediate  get_basic_create_table_ddl(vUpperTableName,
                                 pColumnsAndDatatypeList,
                                 pClobColumnsListForInitStorage,
                                 pIsIOT,
                                 pCompress)
      || case when pNoLogging = 1 then 'NOLOGGING' ||chr(13)
              else chr(13)
         end
      ||' PARTITION BY ' ||
        case when pPartitionType = 'RANGE' then
          ' RANGE(' || pPartitionSetKey || ') INTERVAL('||pInterval||') ' || ' (PARTITION PART_1 VALUES LESS THAN (1)) '
            when pPartitionType = 'HASH' then
          ' HASH (' || pPartitionSetKey || ') ( '||pHashPartitionClause||' )'
           else
          ' LIST (' || pPartitionSetKey || ') (PARTITION PART_0 VALUES (0))'
        end;

  END;

  PROCEDURE RENAME_TABLE(pOldTableName VARCHAR2,
                         pNewTableName VARCHAR2)
  IS
    vUpperOldTableName VARCHAR2(100) := UPPER(pOldTableName);
    vUpperNewTableName VARCHAR2(100) := UPPER(pNewTableName);
    vOldTableExists BOOLEAN;
    vNewTableExists BOOLEAN;
  BEGIN
    vOldTableExists := TABLE_EXISTS(vUpperOldTableName);
    vNewTableExists := TABLE_EXISTS(vUpperNewTableName);

    ASSERT(NOT (vOldTableExists AND vNewTableExists),
          'Both the old (' || vUpperOldTableName || ') and the new (' || vUpperNewTableName || ') tables exist.');

    ASSERT(vOldTableExists OR vNewTableExists,
          'Neither the old (' || vUpperOldTableName || ') nor the new (' || vUpperNewTableName || ') table exist');

    IF vOldTableExists THEN
      execute_immediate('RENAME ' || vUpperOldTableName || ' TO ' || vUpperNewTableName);
    ELSIF vNewTableExists THEN
      NULL; -- nothing to do - it is assummed that the table has already been renamed
    END IF;
  END;

  PROCEDURE RENAME_VIEW(pOldViewName VARCHAR2,
                        pNewViewName VARCHAR2)
  IS
    vUpperOldViewName VARCHAR2(100) := UPPER(pOldViewName);
    vUpperNewViewName VARCHAR2(100) := UPPER(pNewViewName);
    vOldViewExists BOOLEAN;
    vNewViewExists BOOLEAN;
  BEGIN
    vOldViewExists := VIEW_EXISTS(vUpperOldViewName);
    vNewViewExists := VIEW_EXISTS(vUpperNewViewName);

    ASSERT(NOT (vOldViewExists AND vNewViewExists),
          'Both the old (' || vUpperOldViewName || ') and the new (' || vUpperNewViewName || ') Views exist.');

    ASSERT(vOldViewExists OR vNewViewExists,
          'Neither the old (' || vUpperOldViewName || ') nor the new (' || vUpperNewViewName || ') View exist');

    IF vOldViewExists THEN
      execute_immediate('RENAME ' || vUpperOldViewName || ' TO ' || vUpperNewViewName);
    ELSIF vNewViewExists THEN
      NULL; -- nothing to do - it is assummed that the table has already been renamed
    END IF;
  END;

  PROCEDURE SET_COMMENT_ON_TABLE(pTableName IN VARCHAR2,
                                 pComment IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);

    execute_immediate('COMMENT ON TABLE ' || vUpperTableName || ' IS ''' || pComment || '''');
  END;

  ------------------------------------------------------------------------------
  -- COLUMNS
  ------------------------------------------------------------------------------

  FUNCTION COLUMN_EXISTS(pTableName IN VARCHAR2,
                         pColumnName IN VARCHAR2) RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1)
      INTO vCnt
      FROM user_tab_columns
    WHERE table_name = TRIM(UPPER(pTableName))
      AND column_name = TRIM(UPPER(pColumnName));

    RETURN vCnt > 0;
  END;

  PROCEDURE decompress_table(pTableName IN VARCHAR2)
  IS
    vUpperTableName  VARCHAR2(100) := UPPER(pTableName);
    vPartitioned     VARCHAR2(3);
  BEGIN
    SELECT partitioned INTO vPartitioned FROM user_tables WHERE table_name = vUpperTableName;
    IF vPartitioned = 'YES' THEN
      FOR i IN (SELECT partition_name
                  FROM user_tab_partitions
                 WHERE table_name = vUpperTableName
                   AND subpartition_count = 0
                   AND compression = 'ENABLED'
              ORDER BY partition_name) LOOP
        execute_immediate('ALTER TABLE ' || vUpperTableName || ' MOVE PARTITION ' || i.partition_name || ' NOCOMPRESS');
      END LOOP;
      FOR i IN (SELECT ui.index_name, up.partition_name
                  FROM user_indexes ui
                       JOIN user_ind_partitions up ON (ui.index_name = up.index_name)
                 WHERE ui.table_name         = vUpperTableName
                   AND ui.partitioned        = 'YES'
                   AND up.subpartition_count = 0
                   AND up.status             = 'UNUSABLE'
              ORDER BY ui.index_name, up.partition_name) LOOP
        execute_immediate('ALTER INDEX ' || i.index_name || ' REBUILD PARTITION ' || i.partition_name);
      END LOOP;
      FOR i IN (SELECT subpartition_name
                  FROM user_tab_subpartitions
                 WHERE table_name = vUpperTableName
                   AND compression = 'ENABLED'
              ORDER BY partition_name) LOOP
        execute_immediate('ALTER TABLE ' || vUpperTableName || ' MOVE SUBPARTITION ' || i.subpartition_name || ' NOCOMPRESS');
      END LOOP;
      FOR i IN (SELECT ui.index_name, up.subpartition_name
                  FROM user_indexes ui
                       JOIN user_ind_subpartitions up ON (ui.index_name = up.index_name)
                 WHERE ui.table_name         = vUpperTableName
                   AND ui.partitioned        = 'YES'
                   AND up.status             = 'UNUSABLE'
              ORDER BY ui.index_name, up.subpartition_name) LOOP
        execute_immediate('ALTER INDEX ' || i.index_name || ' REBUILD SUBPARTITION ' || i.subpartition_name);
      END LOOP;
    ELSE
      execute_immediate('ALTER TABLE ' || vUpperTableName || ' MOVE NOCOMPRESS');
    END IF;
    FOR i IN (SELECT ui.index_name
                FROM user_indexes ui
               WHERE ui.table_name = vUpperTableName
                 AND ui.partitioned = 'NO'
                 AND ui.status      = 'UNUSABLE'
            ORDER BY ui.index_name) LOOP
      execute_immediate('ALTER INDEX ' || i.index_name || ' REBUILD');
    END LOOP;
    execute_immediate('ALTER TABLE ' || vUpperTableName || ' NOCOMPRESS');
  END;

  PROCEDURE ADD_COLUMN(pTableName IN VARCHAR2,
                       pColumnName IN VARCHAR2,
                       pDataType IN VARCHAR2)
  IS
    vUpperTableName   VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName  VARCHAR2(100) := UPPER(pColumnName);
    vUpperNewDatatype VARCHAR2(100) := UPPER(pDataType);
    vSql              VARCHAR2(4000) := 'ALTER TABLE ' || vUpperTableName ||
                        ' ADD ' || vUpperColumnName || ' ' || vUpperNewDatatype ||
                        get_initial_lob_storage_clause(vUpperColumnName, vUpperNewDatatype);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT(INSTR(vUpperNewDatatype, 'NULL') = 0,
          'The new specified datatype "' || vUpperNewDatatype || '" mustn''t contain the [NOT] NULL clause.');

    IF NOT COLUMN_EXISTS(vUpperTableName, vUpperColumnName) THEN
      BEGIN
        execute_immediate(vSql);       
              EXCEPTION
                WHEN OTHERS THEN
                  raise_exception('Error during adding column ' || pColumnName || ' to table: ' ||
                                   vUpperTableName, pKeepErrorStack => TRUE);
            END;
    ELSE
      NULL; -- nothing to do - it is assummed that the column has already been added
    END IF;
  END;

  PROCEDURE CHANGE_COLUMN_TYPE(pTableName  IN VARCHAR2,
                               pColumnName IN VARCHAR2,
                               pDataType   IN VARCHAR2)
  IS
    vTmpCol          VARCHAR2(30) := SUBSTR(pColumnName, 1, 26) || '$TMP';
  BEGIN
    ASSERT_TABLE_EXISTS(pTableName);
    ASSERT_COLUMN_EXISTS(pTableName,pColumnName);

    BEGIN
      execute_immediate('ALTER TABLE ' || pTableName || ' MODIFY ' || pColumnName || ' ' || pDataType );
    EXCEPTION WHEN OTHERS
    THEN
      DROP_COLUMN(pTableName,vTmpCol);
      ADD_COLUMN(pTableName,vTmpCol,pDataType);
      BEGIN
        execute_immediate('update '||pTableName||' set '||vTmpCol||'='||pColumnName);
        COMMIT;
      EXCEPTION WHEN OTHERS
      THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(CUSTOM_ERROR_NUMBER,'Def data conversion from ' ||
                                                    pTableName||'.'||vTmpCol||
                                                    ' to '||pTableName||'.'||pColumnName||
                                                    ' issue: '||SUBSTR(SQLERRM, 1, 100));
      END;
      DROP_COLUMN(pTableName,pColumnName);
      RENAME_COLUMN(pTableName,vTmpCol,pColumnName);
    END;
  END;

  PROCEDURE DROP_COLUMN(pTableName IN VARCHAR2,
                        pColumnName IN VARCHAR2)
  IS
    vUpperTableName  VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName VARCHAR2(100) := UPPER(pColumnName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);

    IF COLUMN_EXISTS(vUpperTableName, vUpperColumnName) THEN
      execute_immediate('ALTER TABLE ' || vUpperTableName || ' SET UNUSED (' || vUpperColumnName ||')');
    ELSE
      NULL; -- nothing to do - it is assummed that the column has already been dropped
    END IF;
  END;

  PROCEDURE RENAME_COLUMN(pTableName IN VARCHAR2,
                          pOldColumnName IN VARCHAR2,
                          pNewColumnName IN VARCHAR2)
  IS
    vUpperTableName     VARCHAR2(100) := UPPER(pTableName);
    vUpperOldColumnName VARCHAR2(100) := UPPER(pOldColumnName);
    vUpperNewColumnName VARCHAR2(100) := upper_trim_validate(pNewColumnName);
    vOldExists          BOOLEAN;
    vNewExists          BOOLEAN;
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);

    vOldExists := COLUMN_EXISTS(vUpperTableName, vUpperOldColumnName);
    vNewExists := COLUMN_EXISTS(vUpperTableName, vUpperNewColumnName);

    ASSERT(NOT (vOldExists AND vNewExists),
          'Both the old (' || vUpperOldColumnName || ') and the new (' || vUpperNewColumnName ||
            ') columns exist in the ' || vUpperTableName || ' table.');

    ASSERT(vOldExists OR vNewExists,
          'Neither the old (' || vUpperOldColumnName || ') nor the new (' || vUpperNewColumnName ||
            ') column exist in the ' || vUpperTableName || ' table.');

    IF vOldExists THEN
      execute_immediate('ALTER TABLE ' || vUpperTableName ||
                        ' RENAME COLUMN ' || vUpperOldColumnName || ' TO ' || vUpperNewColumnName);
    ELSIF vNewExists THEN
      NULL; -- nothing to do - it is assummed that the column has already been renamed
    END IF;
  END;

  PROCEDURE SET_COLUMN_DEFAULT_VALUE(pTableName IN VARCHAR2,
                                     pColumnName IN VARCHAR2,
                                     pDefaultValue IN VARCHAR2)
  IS
    vUpperTableName  VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName VARCHAR2(100) := UPPER(pColumnName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT_COLUMN_EXISTS(vUpperTableName, vUpperColumnName);

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' MODIFY ' || vUpperColumnName || ' DEFAULT ' || NVL(pDefaultValue, 'NULL'));
  END;

  PROCEDURE SET_COMMENT_ON_COLUMN(pTableName IN VARCHAR2,
                                  pColumnName IN VARCHAR2,
                                  pComment IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName VARCHAR2(100) := UPPER(pColumnName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT_COLUMN_EXISTS(vUpperTableName, vUpperColumnName);

    execute_immediate('COMMENT ON COLUMN ' || vUpperTableName || '.' || vUpperColumnName ||
                      ' IS ''' || pComment || '''');
  END;

  ------------------------------------------------------------------------------
  -- SYNONYMS
  ------------------------------------------------------------------------------
  PROCEDURE DROP_SYNONYM(pSynonymName IN VARCHAR2)
  IS
  BEGIN
    DROP_OBJECT(pSynonymName, 'SYNONYM');
  END;

  PROCEDURE CREATE_SYNONYM(pSynonymName IN VARCHAR2,
                           pOwnerShortName IN VARCHAR2,
                           pTargetName IN VARCHAR2)
  IS
  BEGIN

      NULL;
  END;

  PROCEDURE MOVE_SYNONYM(pSynonymName IN VARCHAR2,
                         pOwnerShortName IN VARCHAR2,
                         pTargetName IN VARCHAR2)
  IS
  BEGIN
    NULL;
  END;

  ------------------------------------------------------------------------------
  -- CONSTRAINTS
  ------------------------------------------------------------------------------
  FUNCTION IS_COLUMN_NULLABLE(pTableName  IN VARCHAR2,
                              pColumnName IN VARCHAR2) RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1)
      INTO vCnt
      FROM user_tab_columns
    WHERE table_name = TRIM(UPPER(pTableName))
      AND column_name = TRIM(UPPER(pColumnName))
      AND nullable = 'Y';

    RETURN vCnt > 0;
  END;

  PROCEDURE MAKE_COLUMN_NULLABLE(pTableName  IN VARCHAR2,
                                 pColumnName IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName VARCHAR2(100) := UPPER(pColumnName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT_COLUMN_EXISTS(vUpperTableName, vUpperColumnName);

    IF NOT IS_COLUMN_NULLABLE(vUpperTableName, vUpperColumnName) THEN
      execute_immediate('ALTER TABLE ' || vUpperTableName || ' MODIFY ' || vUpperColumnName || ' NULL');
    END IF;
  END;

  PROCEDURE MAKE_COLUMN_NOT_NULLABLE(pTableName  IN VARCHAR2,
                                     pColumnName IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
    vUpperColumnName VARCHAR2(100) := UPPER(pColumnName);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT_COLUMN_EXISTS(vUpperTableName, vUpperColumnName);

    IF IS_COLUMN_NULLABLE(vUpperTableName, vUpperColumnName) THEN
      execute_immediate('ALTER TABLE ' || vUpperTableName || ' MODIFY ' || vUpperColumnName || ' NOT NULL');
    END IF;
  END;

  FUNCTION GET_NOT_NULL_CONSTRAINT(pTableName IN VARCHAR2,
                                   pColumnName IN VARCHAR2) RETURN VARCHAR2
  IS
  BEGIN
    FOR r IN (SELECT uc.constraint_name, uc.search_condition
                FROM user_constraints uc
                  JOIN (
                    SELECT table_name, constraint_name
                      FROM user_cons_columns
                    WHERE table_name = UPPER(pTableName)
                    GROUP BY table_name, constraint_name
                    HAVING COUNT(1) = 1
                  ) con_col ON (uc.constraint_name = con_col.constraint_name
                            AND uc.table_name = con_col.table_name
                            AND uc.constraint_type = 'C')
    )
    LOOP
      IF UPPER(r.search_condition) LIKE '%' || UPPER(pColumnName) || '%IS%NOT%NULL%' THEN
        RETURN r.constraint_name;
      END IF;
    END LOOP;

    RETURN NULL;
  END;

  PROCEDURE ADD_PRIMARY_KEY_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := TRIM(UPPER(pTableName));
    vUpperConstraintName VARCHAR2(100);
    vIsPartitioned PLS_INTEGER;
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    vUpperConstraintName := upper_trim_validate(pConstraintName);

    IF CONSTRAINT_EXISTS(vUpperTableName, vUpperConstraintName, 'P') THEN
      RETURN; -- nothing to do - the constraint has already been added
    END IF;

    SELECT COUNT(1) INTO vIsPartitioned FROM user_tables WHERE table_name = vUpperTableName AND partitioned = 'YES';

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' ADD CONSTRAINT ' || vUpperConstraintName || ' PRIMARY KEY (' || pColumnsList || ')' ||
                      CASE
                        WHEN vIsPartitioned = 1 THEN ' USING INDEX LOCAL'
                        ELSE NULL
                      END);
  END;
  
    
  PROCEDURE ADD_FOREIGN_KEY_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2,
                                       pReferenceTableName IN VARCHAR2,
                                       pReferenceColumnList IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := TRIM(UPPER(pTableName));
    vReferenceTableName VARCHAR2(100) := TRIM(UPPER(pReferenceTableName));
    vUpperConstraintName VARCHAR2(100);
    vIsPartitioned PLS_INTEGER;
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    ASSERT_TABLE_EXISTS(vReferenceTableName);
    vUpperConstraintName := upper_trim_validate(pConstraintName);
    
    IF CONSTRAINT_EXISTS(vUpperTableName, vUpperConstraintName, 'R') THEN
      RETURN; -- nothing to do - the constraint has already been added
    END IF;

    SELECT COUNT(1) INTO vIsPartitioned FROM user_tables WHERE table_name = vUpperTableName AND partitioned = 'YES';

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' ADD CONSTRAINT ' || vUpperConstraintName || ' FOREIGN KEY (' || pColumnsList || ')' ||
                      ' REFERENCES ' || vReferenceTableName || ' (' || pReferenceColumnList || ') ENABLE ' ||
                      CASE
                        WHEN vIsPartitioned = 1 THEN ' USING INDEX LOCAL'
                        ELSE NULL
                      END);
  END;
  
  PROCEDURE ADD_NOT_NULL_CONSTRAINT(pTableName IN VARCHAR2,
                                       pConstraintName IN VARCHAR2,
                                       pColumnsList IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := TRIM(UPPER(pTableName));
    vUpperConstraintName VARCHAR2(100);
    vIsPartitioned PLS_INTEGER;
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    vUpperConstraintName := upper_trim_validate(pConstraintName);

    IF CONSTRAINT_EXISTS(vUpperTableName, vUpperConstraintName, 'R') THEN
      RETURN; -- nothing to do - the constraint has already been added
    END IF;

    SELECT COUNT(1) INTO vIsPartitioned FROM user_tables WHERE table_name = vUpperTableName AND partitioned = 'YES';

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' MODIFY (' || pColumnsList || ' CONSTRAINT ' || pColumnsList || ' NOT NULL ENABLE) ' ||
                      CASE
                        WHEN vIsPartitioned = 1 THEN ' USING INDEX LOCAL'
                        ELSE NULL
                      END);
  END;

  PROCEDURE ADD_UNIQUE_CONSTRAINT(pTableName IN VARCHAR2,
                                  pConstraintName IN VARCHAR2,
                                  pColumnsList IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
    vUpperConstraintName VARCHAR2(100);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    vUpperConstraintName := upper_trim_validate(pConstraintName);

    IF CONSTRAINT_EXISTS(vUpperTableName, vUpperConstraintName, 'U') THEN
      RETURN; -- nothing to do - the constraint has already been added
    END IF;

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' ADD CONSTRAINT ' || vUpperConstraintName || ' UNIQUE (' || pColumnsList || ')');
  END;

  PROCEDURE ADD_CHECK_CONSTRAINT(pTableName IN VARCHAR2,
                                 pConstraintName IN VARCHAR2,
                                 pCheckCondition IN VARCHAR2)
  IS
    vUpperTableName VARCHAR2(100) := UPPER(pTableName);
    vUpperConstraintName VARCHAR2(100);
  BEGIN
    ASSERT_TABLE_EXISTS(vUpperTableName);
    vUpperConstraintName := upper_trim_validate(pConstraintName);

    IF CONSTRAINT_EXISTS(vUpperTableName, vUpperConstraintName, 'C') THEN
      RETURN; -- nothing to do - the constraint has already been added
    END IF;

    execute_immediate('ALTER TABLE ' || vUpperTableName ||
                      ' ADD CONSTRAINT ' || vUpperConstraintName || ' CHECK (' || pCheckCondition || ')');
  END;

  FUNCTION CONSTRAINT_EXISTS(pTableName IN VARCHAR2,
                             pConstraintName IN VARCHAR2,
                             pConstraintType IN VARCHAR2)
    RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1)
      INTO vCnt
      FROM user_constraints
    WHERE table_name = TRIM(UPPER(pTableName))
      AND constraint_name = TRIM(UPPER(pConstraintName))
      AND constraint_type = TRIM(UPPER(pConstraintType));

    RETURN vCnt > 0;
  END;

  PROCEDURE DROP_CONSTRAINT(pTableName IN VARCHAR2,
                            pConstraintName IN VARCHAR2,
                            pConstraintType IN VARCHAR2)
  IS
  BEGIN
    IF CONSTRAINT_EXISTS(pTableName, pConstraintName, pConstraintType) THEN
      execute_immediate('ALTER TABLE ' || pTableName || ' DROP CONSTRAINT ' || pConstraintName);
    END IF;

    IF TRIM(UPPER(pConstraintType)) = 'P' THEN
      DROP_OBJECT(pConstraintName, 'INDEX');
    END IF;
  END;

  PROCEDURE DISABLE_CONSTRAINT(pTableName IN VARCHAR2,
                               pConstraintName IN VARCHAR2)
  IS
  BEGIN
    execute_immediate('ALTER TABLE ' || pTableName || ' MODIFY CONSTRAINT ' || pConstraintName || ' DISABLE');
  END;
PROCEDURE ENABLE_CONSTRAINT(pTableName IN VARCHAR2,
                              pConstraintName IN VARCHAR2)
  IS
  BEGIN
    execute_immediate('ALTER TABLE ' || pTableName || ' MODIFY CONSTRAINT ' || pConstraintName || ' ENABLE');
  END;

  --------------------------------------------------------------------------------
  -- PRIVILEGES
  --------------------------------------------------------------------------------

  PROCEDURE GRANT_PRIVILEGE(pObjectName IN VARCHAR2,
                            pGrantee IN VARCHAR2,
                            pPrivilege IN VARCHAR2,
                            pWithGrantOption IN BOOLEAN := FALSE)
  IS
  BEGIN
  NULL;
  END;

  PROCEDURE REVOKE_PRIVILEGE(pObjectName IN VARCHAR2,
                             pGrantee IN VARCHAR2,
                             pPrivilege IN VARCHAR2)
  IS
  BEGIN
   NULL;
  END;
  ------------------------------------------------------------------------------
  -- SEQUENCE
  ------------------------------------------------------------------------------

  PROCEDURE CREATE_SEQUENCE(pSeqName IN VARCHAR2,
                            pMinVal IN INTEGER := NULL,
                            pMaxVal IN INTEGER := NULL,
                            pStartWith IN INTEGER := 1,
                            pIncrementBy IN INTEGER := 1,
                            pCache IN INTEGER := 100,
                            pOrder IN BOOLEAN := FALSE) IS
  BEGIN
    IF NOT OBJECT_EXISTS(pSeqName, 'SEQUENCE') THEN
      execute_immediate('CREATE SEQUENCE ' || pSeqName ||
                        CASE WHEN pMinVal IS NOT NULL THEN ' MINVALUE '||pMinVal END||
                        CASE WHEN pMaxVal IS NOT NULL THEN ' MAXVALUE '||pMaxVal END||
                        CASE WHEN pStartWith IS NOT NULL THEN ' START WITH '||pStartWith END||
                        CASE WHEN pIncrementBy IS NOT NULL THEN ' INCREMENT BY '||pIncrementBy END||
                        CASE WHEN pCache IS NOT NULL THEN ' CACHE '||pCache END||
                        CASE WHEN pOrder THEN ' ORDER ' END
                        );
    ELSE
      NULL; -- nothing to do - it is assummed that the SEQUENCE has already been created
    END IF;
  END;
  ------------------------------------------------------------------------------
  -- COMMON OPERATIONS
  ------------------------------------------------------------------------------

  FUNCTION OBJECT_EXISTS(pObjectName IN VARCHAR2,
                         pObjectType IN VARCHAR2) RETURN BOOLEAN
  IS
    vCnt PLS_INTEGER;
  BEGIN
    SELECT COUNT(1)
      INTO vCnt
      FROM user_objects
    WHERE object_name = TRIM(UPPER(pObjectName))
      AND object_type = TRIM(UPPER(pObjectType));

    RETURN vCnt > 0;
  END;

  PROCEDURE DROP_OBJECT(pObjectName IN VARCHAR2,
                        pObjectType IN VARCHAR2,
                        pForce      IN BOOLEAN DEFAULT FALSE)
  IS
    vObjectType VARCHAR2(30) := upper_trim_validate(pObjectType);
  BEGIN
    IF OBJECT_EXISTS(pObjectName, pObjectType) THEN
      IF pForce then
        execute_immediate('DROP ' || pObjectType || ' ' || pObjectName);
    ELSE
      NULL; -- nothing to do - it is assummed that the object has already been dropped
    END IF;
        END IF;
  END;

  PROCEDURE COMPILE_INVALID_OBJECTS IS
    MAX_ATTEMPTS# CONSTANT NUMBER := 5;

    vOwner                    VARCHAR2(100);
    vAttemptsCounter          NUMBER := 1;
    vInvalidObjectsCount      NUMBER;
    vInvalidObjectsWithErrCnt NUMBER;
    vMutexHandle              VARCHAR2(128);
    vLockingResult            NUMBER;
  BEGIN
    vOwner := sys_context('userenv', 'current_schema');

    ASSERT(vOwner NOT IN ('SYS', 'SYSTEM'), 'Cannot recompile SYS and SYSTEM schemas!');

    dbms_output.put_line('Recompiling schema ' || vOwner);

    COMPILE_OBJECTS_NATIVELY('%',FALSE);

    WHILE TRUE LOOP
      dbms_output.put_line('Iteration #' || vAttemptsCounter);

      FOR iCur IN (SELECT OWNER,OBJECT_TYPE,OBJECT_NAME
                    FROM ALL_OBJECTS
                      WHERE OBJECT_TYPE IN ('TYPE','PACKAGE','VIEW','TRIGGER','MATERIALIZED VIEW','PROCEDURE','FUNCTION','PACKAGE BODY','TYPE BODY','SYNONYM')
                        AND STATUS = 'INVALID'
                        AND OWNER = vOwner
                        ORDER BY DECODE(OBJECT_TYPE,'TYPE',1,'PACKAGE',1,'VIEW',2,'TRIGGER',2,'MATERIALIZED VIEW',2,'PROCEDURE',3,'FUNCTION',3,'SYNONYM',3,'PACKAGE BODY',4,'TYPE BODY',4)) LOOP
          BEGIN
            IF iCur.OBJECT_TYPE IN ('TYPE','PACKAGE') THEN
              EXECUTE IMMEDIATE 'ALTER '||iCur.OBJECT_TYPE||' '||iCur.OWNER||'.'||iCur.OBJECT_NAME||' COMPILE SPECIFICATION REUSE SETTINGS' ;
            ELSIF iCur.OBJECT_TYPE IN ('PACKAGE BODY') THEN
              EXECUTE IMMEDIATE 'ALTER PACKAGE '||iCur.OWNER||'.'||iCur.OBJECT_NAME||' COMPILE BODY REUSE SETTINGS';
            ELSIF iCur.OBJECT_TYPE IN ('TYPE BODY') THEN
              EXECUTE IMMEDIATE 'ALTER TYPE '||iCur.OWNER||'.'||iCur.OBJECT_NAME||' COMPILE BODY REUSE SETTINGS';
            ELSIF iCur.OBJECT_TYPE IN ('VIEW','TRIGGER','MATERIALIZED VIEW','PROCEDURE','FUNCTION','SYNONYM') THEN
              EXECUTE IMMEDIATE 'ALTER '||iCur.OBJECT_TYPE||' '||iCur.OWNER||'.'||iCur.OBJECT_NAME||' COMPILE';
            END IF;
          EXCEPTION
              WHEN OTHERS THEN
                  NULL;
          END;
      END LOOP;

      SELECT COUNT(1) INTO vInvalidObjectsCount FROM all_objects WHERE status = 'INVALID' AND owner = vOwner;

      vAttemptsCounter := vAttemptsCounter + 1;
      EXIT WHEN vInvalidObjectsCount = 0 OR vAttemptsCounter > MAX_ATTEMPTS#;
    END LOOP;

    SELECT COUNT(1) INTO vInvalidObjectsCount FROM all_objects WHERE status = 'INVALID' AND owner = vOwner;

    IF vInvalidObjectsCount > 0 THEN
      BEGIN
        dbms_output.put_line('Recompiling schema by DBMS_UTILITY.COMPILE_SCHEMA');
      EXCEPTION
        WHEN OTHERS THEN
         RAISE;
      END;
    END IF;

    SELECT COUNT(1) INTO vInvalidObjectsCount FROM all_objects WHERE status = 'INVALID' AND owner = vOwner;

    SELECT COUNT(1)
      INTO vInvalidObjectsWithErrCnt
      FROM all_objects o
    WHERE status = 'INVALID'
      AND owner = vOwner
      AND EXISTS (SELECT 1 FROM all_errors WHERE NAME = o.object_name AND owner = o.owner AND attribute != 'WARNING');

    dbms_output.put_line('Final # of invalid objects: ' || vInvalidObjectsCount || ', ' ||
                          vInvalidObjectsWithErrCnt || ' with compilation errors.');

    IF vInvalidObjectsWithErrCnt > 0 THEN
      dbms_output.put_line('List of errors for user ' || vOwner || ':');

      FOR vError IN (SELECT ' ' || type || ' ' || name || ' [' || line || ':' || position || ']: ' || text AS msg
                       FROM all_errors
                     WHERE text NOT LIKE '%Statement ignored%'
                       AND owner = vOwner
                       AND attribute != 'WARNING'
                     ORDER BY type, name, sequence)
      LOOP
        dbms_output.put_line(vError.msg);
      END LOOP;
    END IF;
    dbms_output.new_line();
  END;

  PROCEDURE COMPILE_OBJECTS_NATIVELY(pObjectNamePattern VARCHAR2,pRaise IN BOOLEAN := TRUE,pPlsqlOptimizeLevel PLS_INTEGER := 2)
  IS
    CANNOT_COMPILE_TYPE_DEPENDENTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(CANNOT_COMPILE_TYPE_DEPENDENTS, -2311);
  BEGIN
     FOR iCur IN ( SELECT NAME,TYPE, USER OWNER
                    FROM USER_PLSQL_OBJECT_SETTINGS
                      WHERE TYPE IN ('TYPE','PACKAGE','TRIGGER','PROCEDURE','FUNCTION','PACKAGE BODY','TYPE BODY')
                        AND (PLSQL_CODE_TYPE <> 'NATIVE' OR PLSQL_DEBUG = 'TRUE' OR PLSQL_OPTIMIZE_LEVEL <> pPlsqlOptimizeLevel)
                        AND NAME <> $$PLSQL_UNIT -- YOU CANNOT COMPILE YOURSELF
                        AND NAME LIKE pObjectNamePattern
                          ORDER BY DECODE(TYPE,'TYPE',1,'PACKAGE',1,'TRIGGER',2,'PROCEDURE',3,'FUNCTION',3,'PACKAGE BODY',4,'TYPE BODY',4)) LOOP
      BEGIN
        IF iCur.TYPE IN ('TYPE','PACKAGE') THEN
          BEGIN
            EXECUTE IMMEDIATE 'ALTER '||iCur.TYPE||' "'||iCur.OWNER||'"."'||iCur.NAME||'" COMPILE SPECIFICATION PLSQL_CODE_TYPE=NATIVE PLSQL_DEBUG=FALSE PLSQL_OPTIMIZE_LEVEL='||pPlsqlOptimizeLevel||' REUSE SETTINGS' ;
          EXCEPTION
            WHEN CANNOT_COMPILE_TYPE_DEPENDENTS THEN
              NULL;
          END;
        ELSIF iCur.TYPE IN ('PACKAGE BODY') THEN
          EXECUTE IMMEDIATE 'ALTER PACKAGE "'||iCur.OWNER||'"."'||iCur.NAME||'" COMPILE BODY PLSQL_CODE_TYPE=NATIVE PLSQL_DEBUG=FALSE PLSQL_OPTIMIZE_LEVEL='||pPlsqlOptimizeLevel||' REUSE SETTINGS';
        ELSIF iCur.TYPE IN ('TYPE BODY') THEN
          EXECUTE IMMEDIATE 'ALTER TYPE "'||iCur.OWNER||'"."'||iCur.NAME||'" COMPILE BODY PLSQL_CODE_TYPE=NATIVE PLSQL_DEBUG=FALSE PLSQL_OPTIMIZE_LEVEL='||pPlsqlOptimizeLevel||' REUSE SETTINGS';
        ELSIF iCur.TYPE IN ('TRIGGER','PROCEDURE','FUNCTION') THEN
          EXECUTE IMMEDIATE 'ALTER '||iCur.TYPE||' "'||iCur.OWNER||'"."'||iCur.NAME||'" COMPILE PLSQL_CODE_TYPE=NATIVE PLSQL_DEBUG=FALSE PLSQL_OPTIMIZE_LEVEL='||pPlsqlOptimizeLevel;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          IF pRaise THEN
            RAISE;
          END IF;
      END;
    END LOOP;
  END;

  PROCEDURE COMPILE_OBJECTS_NATIVELY
  IS
  BEGIN
    COMPILE_OBJECTS_NATIVELY('%');
  END;

  --------------------------------------------------------------------------------
  -- ASSERTIONS
  --------------------------------------------------------------------------------

  PROCEDURE ASSERT(pExpression IN BOOLEAN,
                   pMessage IN VARCHAR2)
  IS
  BEGIN
    IF pExpression THEN
      RETURN;
    END IF;

    RAISE_APPLICATION_ERROR(ASSERTION_ERROR_NUMBER, 'Assertion failed: ' || pMessage);
  END;

  PROCEDURE ASSERT_TABLE_EXISTS(pTableName IN VARCHAR2)
  IS
  BEGIN
    ASSERT(TABLE_EXISTS(pTableName), 'Table ' || UPPER(pTableName) || ' should exist!');
  END;

  PROCEDURE ASSERT_COLUMN_EXISTS(pTableName IN VARCHAR2,
                                 pColumnName IN VARCHAR2)
  IS
  BEGIN
    ASSERT(COLUMN_EXISTS(pTableName, pColumnName),
           'Column ' || pColumnName || ' should exist in the ' || UPPER(pTableName) || ' table!');
  END;

  PROCEDURE ASSERT_OBJECT_EXISTS(pObjectName IN VARCHAR2,
                                 pObjectType IN VARCHAR2)
  IS
  BEGIN
    ASSERT(OBJECT_EXISTS(pObjectName, pObjectType), pObjectType || ' ' || UPPER(pObjectName) || ' should exist!');
  END;
END;
/