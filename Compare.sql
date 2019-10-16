USE Master
GO

IF EXISTS (
	SELECT 1 
	FROM sys.databases 
	WHERE name = 'DB_Compare'
	)
	BEGIN
		DROP DATABASE DB_Compare
	END
GO

CREATE DATABASE DB_Compare
GO

USE DB_Compare
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE Log_Errores(
	LogErroresId INT IDENTITY(1,1) NOT NULL,
	IdComparacion NUMERIC(18,0) NULL,
	Descripcion VARCHAR(MAX) NULL,
	Linea_Excepcion INT NULL,
	Numero_Error INT NULL,
	Severidad TINYINT NULL,
	Estado TINYINT NULL,
	Fecha DATETIME NULL,
	Usuario VARCHAR(MAX) NULL,
	CONSTRAINT PK_LogErrores PRIMARY KEY (LogErroresId)
); 

CREATE TABLE ComparacionDb(
	ComparacionDbId NUMERIC (18, 0) IDENTITY (1, 1) NOT NULL,
	BD1 VARCHAR (MAX) NOT NULL,
	BD2 VARCHAR (MAX) NOT NULL,
	ExisteBD1 CHAR (2) NOT NULL,
	ExisteBD2 CHAR (2) NOT NULL,
	CONSTRAINT PK_ComparacionDb PRIMARY KEY (ComparacionDbId)
)

CREATE TABLE ComparacionTabla(
	ComparacionTablaId NUMERIC (18, 0) IDENTITY (1, 1) NOT NULL,
	ComparacionDbsId NUMERIC (18, 0) NOT NULL,
	EsquemaBD2 VARCHAR (MAX) NOT NULL,
	ExisteEsquemaBD2 VARCHAR (MAX),
	TablaBD2 VARCHAR (MAX) NOT NULL,
	ExisteTablaBD2 VARCHAR (MAX),
	PkBD1 VARCHAR (MAX),
	PkBD2 VARCHAR (MAX),
	FkBD1 VARCHAR (MAX),
	FkBD2 VARCHAR (MAX),
	UniqueBD1 VARCHAR (MAX),
	UniqueBD2 VARCHAR (MAX),
	CheckBD1 VARCHAR (MAX),
	CheckBD2 VARCHAR (MAX),
	CONSTRAINT PK_ComparacionTabla PRIMARY KEY (ComparacionTablaId),
	CONSTRAINT FK_ComparacionTabla_ComparacionDb FOREIGN KEY (ComparacionDbsId) REFERENCES ComparacionDb (ComparacionDbId)	
)
GO
CREATE TABLE ComparacionColumna(
	ComparacionColumnaId NUMERIC (18, 0) IDENTITY (1, 1) NOT NULL,
	ComparacionTablaId NUMERIC (18, 0) NOT NULL,
	AutoIncremental VARCHAR(MAX) NULL,
	NombreColumna VARCHAR(MAX) NULL,
	TipoDato VARCHAR(MAX) NULL,
	EsNull CHAR(2),
	CONSTRAINT PK_CompareColumna PRIMARY KEY (ComparacionColumnaId),
	CONSTRAINT FK_CompareColumna_ComparacionTabla FOREIGN KEY (ComparacionTablaId) REFERENCES ComparacionTabla (ComparacionTablaId)
)

GO
--funcion que valida que el nombre de la base de datos empiece con 'BD_'
CREATE PROCEDURE sp_validate_DB_name (@DBNAme varchar (250))
AS
if (LEFT(@DBName,3) = 'DB_')
	RETURN 1
ELSE
	INSERT INTO ##validacion_origen 
	values(''+@DBName+'', 'El nombre de la base de datos debe comenzar con "DB_"')
	RETURN 0
GO

--Valido nombre de tabla. Debe comenzar con mayuscula y estar en singular
CREATE PROCEDURE sp_validate_table_name (@TableName varchar (250))
AS
declare @v1 varchar(50) = (LEFT(@TableName,1))
declare @v2 varchar(50) = UPPER(LEFT(@TableName,1)) 

if(@v1 = @v2 COLLATE SQL_Latin1_General_CP1_CS_AS and RIGHT(@TableName,1) not in ('s'))
	RETURN 1
ELSE
INSERT INTO ##validacion_origen 
	VALUES(''+@TableName+'', 'El nombre de la tabla debe comenzar con mayúscula y estar en singular')
	RETURN 0
GO


--valido nombre de la PK
CREATE PROCEDURE sp_validate_table_PK (@TableName VARCHAR (250), @DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				WHERE (CONSTRAINT_TYPE = ''PRIMARY KEY'')
				AND (TABLE_NAME ='''+@TableName+''')
				AND (CONSTRAINT_NAME NOT LIKE ''PK_%'')'
	
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@TableName+'','Error en nombre de PK')
	RETURN 0

GO

--valido nombre de la UQ
CREATE PROCEDURE sp_validate_table_UQ (@TableName VARCHAR (250), @DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				WHERE (CONSTRAINT_TYPE = ''UNIQUE'')
				AND (TABLE_NAME ='''+@TableName+''')
				AND (CONSTRAINT_NAME NOT LIKE ''UQ_%'')'
	
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@TableName+'','Error en nombre de UQ')
	RETURN 0

GO

--valido nombre de la CK
CREATE PROCEDURE sp_validate_table_CK (@TableName VARCHAR (250), @DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				WHERE (CONSTRAINT_TYPE = ''CHECK'')
				AND (TABLE_NAME ='''+@TableName+''')
				AND (CONSTRAINT_NAME NOT LIKE ''CK_%'')'
	
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@TableName+'','Error en nombre de CK')
	RETURN 0
GO


--valido nombre de la FK
CREATE PROCEDURE sp_validate_table_FK (@TableName VARCHAR (250), @DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				WHERE (CONSTRAINT_TYPE = ''FOREIGN KEY'')
				AND (TABLE_NAME ='''+@TableName+''')
				AND (CONSTRAINT_NAME NOT LIKE ''FK_%'')'
	
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@TableName+'','Error en nombre de FK')
	RETURN 0

GO


--valido nombres de SP
CREATE PROCEDURE sp_validate_Database_sp (@DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.sys.procedures
				where name not like ''%usp%'' and name not like ''sp_%'''
					
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@DBName+'','Error en nombre de PK')
	RETURN 0

GO

--valido nombre de las vistas
CREATE PROCEDURE sp_validate_Database_View (@DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.sys.views
				where name not like ''v%'' and type = ''V'''
					
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@DBName+'','Error en nombre de vista')
	RETURN 0

GO

--test de funcion nombre de Vista

CREATE PROCEDURE sp_validate_Table_Triggers (@DBName VARCHAR(250))
AS
	DECLARE @sql NVARCHAR(max)
	DECLARE @CANTIDAD INT
	SET @sql =	'SELECT @CANT = count(*) FROM '+@DBName+'.sys.triggers
				where left(name,4) not in (''TGI_'', ''TGD_'', ''TGU_'')'
					
	Declare @r int
	EXEC @r = SP_EXECUTESQL @sql,N'@CANT INT OUTPUT',@CANT=@CANTIDAD OUTPUT

	IF (@CANTIDAD = 0)
	RETURN 1
	ELSE 
	INSERT INTO ##validacion_origen VALUES(''+@DBName+'','Error en nombre de trigger')
	RETURN 0

GO

CREATE PROCEDURE sp_ExisteBD
@BD1 VARCHAR(50), @BD2 VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		DECLARE @NoExisteBD VARCHAR(100)
		-- verifica que existan las bases de datos pasadas
		IF (@BD1 IS NOT NULL AND EXISTS(SELECT 1 FROM sys.databases WHERE name = @BD1)) 
		BEGIN
			IF (@BD2 IS NOT NULL AND EXISTS(SELECT 1 FROM sys.databases WHERE name = @BD2))
			BEGIN
				INSERT INTO ComparacionDb (BD1, BD2, ExisteBD1, ExisteBD2) VALUES (@BD1, @BD2, 'Si', 'Si') 
			END
			ELSE
			BEGIN
				INSERT INTO ComparacionDb (BD1, BD2, ExisteBD1, ExisteBD2) VALUES (@BD1, @BD2, 'Si', 'No')
				SET @NoExisteBD = 'La base de datos Destino' + @BD2 + ' no existe. Elija una base de datos de destino
							   existente'
				RAISERROR(@NoExisteBD,1,16)
			END					
		END
		ELSE --Si la BD Origen si es nula, entra por acá (ELSE)
		BEGIN
			IF (@BD2 IS NOT NULL AND EXISTS(SELECT 1 FROM sys.databases WHERE name = @BD2))
			BEGIN
				INSERT INTO ComparacionDb (BD1, BD2, ExisteBD1, ExisteBD2) VALUES (@BD1, @BD2, 'No', 'Si') 
				SET @NoExisteBD = 'La base de datos origen' + @BD1 + ' no existe. Elija una base de datos de origen
							   existente'
				RAISERROR(@NoExisteBD,1,16)
			END
			ELSE
			BEGIN
				INSERT INTO ComparacionDb (BD1, BD2, ExisteBD1, ExisteBD2) VALUES (@BD1, @BD2, 'No', 'No')
				SET @NoExisteBD = 'Niguna de las dos Bases de Datos existe.' 
				RAISERROR(@NoExisteBD, 16, 1)
			END
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR-sp_ExisteBd: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END

GO

CREATE Procedure sp_ExisteTabla
@BD VARCHAR(50),@NombreTabla VARCHAR(50),@NombreEsquema VARCHAR(50)
AS
BEGIN
	DECLARE @Existe INT, @SqlDinamico NVARCHAR(MAX),@Error VARCHAR(100)

	SET @SqlDinamico = 'SELECT @ExisteTabla = COUNT (*)
						FROM ' + @BD +'.INFORMATION_SCHEMA.TABLES
						WHERE TABLE_NAME = ''' + @NombreTabla + ''' AND TABLE_SCHEMA = '''+@NombreEsquema+''''

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@ExisteTabla INT OUTPUT', @ExisteTabla = @Existe OUTPUT

	IF @Existe IS NULL
	BEGIN 
		SET @Existe = 0
	END

	RETURN @Existe
END

go

CREATE PROCEDURE sp_ExisteEsquema
@BD VARCHAR(50),@NombreEsquema VARCHAR(50)
AS
BEGIN
	DECLARE @Existe INT, @SqlDinamico NVARCHAR(MAX),@Error VARCHAR(100)

	SET @SqlDinamico = 'SELECT @ExisteEsquema = COUNT (*)
						FROM ' + @BD +'.INFORMATION_SCHEMA.TABLES
						WHERE TABLE_SCHEMA = '''+@NombreEsquema+''''

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@ExisteEsquema INT OUTPUT', @ExisteEsquema = @Existe OUTPUT
	
	IF @Existe IS NULL
	BEGIN 
		SET @Existe = 0
	END

	RETURN @Existe
END
GO

CREATE PROCEDURE sp_EliminarPK
@BD1 VARCHAR(50), @BD2 VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		DECLARE @SqlDinamico NVARCHAR(MAX), @DropColumnaPk VARCHAR(100), @Querry NVARCHAR(MAX)

		SET @Querry = ' ' 
		-- Indica que Pk estan en Bd2 y no en Bd1, las que existan es para hacer drop
		SET @SqlDinamico = 'SELECT @DropPk = COL.CONSTRAINT_NAME
					FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
					JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
					ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
					WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY''
					AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+''' 
					AND (COL.COLUMN_NAME NOT IN 
					( SELECT COL.COLUMN_NAME
					FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
					JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
					ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
					WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY'' AND COL.TABLE_NAME = '''+@Tabla+'''
					AND COL.TABLE_SCHEMA = '''+@Esquema+''') OR 
					COL.CONSTRAINT_NAME NOT IN 
					( SELECT COL.CONSTRAINT_NAME
					FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
					JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
					ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
					WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY'' AND COL.TABLE_NAME = '''+@Tabla+'''
					AND COL.TABLE_SCHEMA = '''+@Esquema+'''))'
		
		EXECUTE SP_EXECUTESQL @SqlDinamico,N'@DropPk VARCHAR(100) OUTPUT',@DropPk = @DropColumnaPk OUTPUT

		IF @DropColumnaPk IS NOT NULL
		BEGIN
			SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' DROP CONSTRAINT '+@DropColumnaPk
			
			INSERT INTO ##Querrys VALUES (@Querry)
		END
		
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp_eliminarpk: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END

GO

CREATE PROCEDURE sp_CantidadPk
@BD VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX),@CantPkDb1 INT

	SET @SqlDinamico = 'SELECT @PK = COUNT (*)
						FROM ' + @BD + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS T
						JOIN ' + @BD + '.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS C ON T.CONSTRAINT_NAME = C.CONSTRAINT_NAME
						AND T.TABLE_NAME = C.TABLE_NAME
						WHERE C.TABLE_NAME = ''' + @Tabla + '''
						AND C.TABLE_SCHEMA = ''' + @Esquema + '''
						AND T.CONSTRAINT_TYPE = ''PRIMARY KEY''
						GROUP BY C.TABLE_NAME'

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@PK INT OUTPUT', @PK = @CantPkDb1 OUTPUT

	RETURN @CantPkDb1
END

GO

CREATE PROCEDURE sp_AgregarPK
@BD1 VARCHAR(50), @BD2 VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		DECLARE @SqlDinamico NVARCHAR(MAX),  @CantPkDb1 INT, @CantPkDb2 INT,@TienePkDb1 VARCHAR(50),
		@TienePkDb2 VARCHAR(50),@DropColumnaPk VARCHAR(100), @Querry NVARCHAR(MAX),@ID INT
		
		SET @Querry = ' '; 
		Execute @CantPkDb1 = sp_CantidadPk @BD1,@Tabla,@Esquema
		Execute @CantPkDb2 = sp_CantidadPk @BD2,@Tabla,@Esquema

		IF @CantPkDb1 = 1 
		BEGIN 
			SET @TienePkDb1 = 'La PRIMARY KEY es simple' 
		END
		ELSE
		BEGIN 
			IF (@CantPkDb1 >= 2)
			BEGIN 
				SET @TienePkDb1 = 'La PRIMARY KEY es compuesta' 
			END
			ELSE
			BEGIN 
				SET @TienePkDb1 = 'Sin PRIMARY KEY' 
			END
		END

		IF(@CantPkDb2 >= 1) --Tiene PK 
		BEGIN 	
			SET @TienePkDb2 = 'La PRIMARY KEY es simple' 

			IF (@CantPkDb2 >= 2)
			BEGIN 
				SET @TienePkDb2 = 'La PRIMARY KEY es compuesta'
			END
		END
		ELSE
		BEGIN 
			SET @TienePkDb2 = 'Sin PRIMARY KEY' 
		END
		
		IF @CantPkDb1 >=1
		BEGIN
			SET @SqlDinamico = 'DECLARE PKFaltantes CURSOR FOR SELECT COL.COLUMN_NAME,COL.CONSTRAINT_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY''AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			AND (COL.COLUMN_NAME NOT IN ( SELECT COL.COLUMN_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			) OR COL.CONSTRAINT_NAME NOT IN ( SELECT COL.CONSTRAINT_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''PRIMARY KEY'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			))'
			 
			EXECUTE SP_EXECUTESQL @SqlDinamico

			-- Indica cuales son las pks de la tabla que estan en bd1 y no en la bd2, luego se agregaran
			DECLARE @PrimaryCompuesta NVARCHAR(MAX),@ColumnaPrimaryKey VARCHAR(100),@NombreDePK VARCHAR(100), @Flag INT,
			@ColumnaPkSimple VARCHAR(100),@NombrePKFinal VARCHAR(100), @PkIguales INT
			
			SET @PkIguales = 0

			IF @CantPkDb1 >=2
			BEGIN
				SET @PrimaryCompuesta = ' ('
				SET @Flag = 0
			END

			OPEN PKFaltantes
			FETCH NEXT FROM PKFaltantes INTO @ColumnaPrimaryKey,@NombreDePK
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @PkIguales = 1

				IF (@CantPkDb1 >= 2)
				BEGIN 
					SET @Flag = @Flag + 1			
					SET @PrimaryCompuesta = @PrimaryCompuesta + @ColumnaPrimaryKey 
					SET @NombrePKFinal = @NombreDePK

					IF @Flag < @CantPkDb2
					BEGIN
						SET @PrimaryCompuesta = @PrimaryCompuesta + ','	
					END
				END
				ELSE
				BEGIN
					SET @ColumnaPkSimple = @ColumnaPrimaryKey
					SET @NombrePKFinal = @NombreDePK
				END

				FETCH NEXT FROM PKFaltantes INTO @ColumnaPrimaryKey,@NombreDePK
			END	
			
			CLOSE PKFaltantes
			DEALLOCATE PKFaltantes
 
			IF @PkIguales = 1
			BEGIN
				IF(@CantPkDb1 >=2)
				BEGIN
					SET @PrimaryCompuesta = @PrimaryCompuesta + ') '
					SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' ADD CONSTRAINT '+ 
					+@NombrePKFinal+' PRIMARY KEY CLUSTERED '+@PrimaryCompuesta

					INSERT INTO ##Querrys VALUES (@Querry)
				END
				ELSE
				BEGIN
					SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' ADD CONSTRAINT '+ 
					+@NombrePKFinal+' PRIMARY KEY CLUSTERED ('+@ColumnaPkSimple+')'
					
					INSERT INTO ##Querrys VALUES (@Querry)
				END
			END
		END
		
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp-agergarpk: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()

	END CATCH
END

GO

CREATE PROCEDURE sp_CantidadFks
@BD VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX), @CantFks INT;

	SET @SqlDinamico = 'SELECT @FK = COUNT(*) 
						FROM ' + @BD + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS T 
						JOIN ' + @BD + '.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS C 
						ON T.CONSTRAINT_NAME = C.CONSTRAINT_NAME AND T.TABLE_NAME = C.TABLE_NAME 
						WHERE C.TABLE_NAME = ''' + @Tabla + ''' AND C.TABLE_SCHEMA = ''' + @Esquema + ''' 
						AND T.CONSTRAINT_TYPE = ''FOREIGN KEY''
						GROUP BY C.TABLE_NAME';

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@FK INT OUTPUT', @FK = @CantFks OUTPUT;

	IF(@CantFks IS NULL)
	 SET @CantFks = 0;

	RETURN @CantFks;
END

GO

CREATE PROCEDURE sp_EliminarFK
@BD1 VARCHAR(50), @BD2 VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON

		DECLARE @SqlDinamico NVARCHAR(MAX), @NombreFk VARCHAR(100), @Querry NVARCHAR(MAX)

		SET @Querry = ' '
		SET @SqlDinamico = 'DECLARE DropFK CURSOR FOR SELECT rc.CONSTRAINT_NAME
			FROM '+@BD2+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+'''
			AND (ccu.COLUMN_NAME NOT IN( SELECT ccu.COLUMN_NAME
			FROM '+@BD1+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+''') 
			OR rc.CONSTRAINT_NAME NOT IN ( SELECT rc.CONSTRAINT_NAME
			FROM '+@BD1+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+''') 
			)'

			EXECUTE sp_executesql @SqlDinamico
			OPEN DropFK
			FETCH NEXT FROM DropFK INTO @NombreFk

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' DROP CONSTRAINT '+ 
				+@NombreFk
				
				INSERT INTO ##Querrys VALUES (@Querry)

				FETCH NEXT FROM DropFK INTO @NombreFk	
			END

			CLOSE DropFK
			DEALLOCATE DropFK

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp_eliminarfk: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()

	END CATCH
END

GO

CREATE PROCEDURE sp_AgregarFKs
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @CantFKBd1 INT,@CantFKBd2 INT, @SqlDinamico NVARCHAR(MAX), @NombreFk VARCHAR(50),@TablaFK VARCHAR(50),
		@CampoFK VARCHAR(50), @CampoReferenciado VARCHAR(50),@TablaReferenciada VARCHAR(50),@FkBD1 VARCHAR(100),
		@FkBD2 VARCHAR(100),@Querry NVARCHAR(MAX),@ID INT

		EXECUTE  @CantFKBd1 = sp_CantidadFks @Bd1,@Tabla,@Esquema-- a cantidad fks
		EXECUTE  @CantFKBd2 = sp_CantidadFks @Bd2,@Tabla,@Esquema-- a cantidad fks

		SET @FkBD1 = CONVERT(NVARCHAR,@CantFKBd1)+' FOREIGN KEYS'
		SET @FkBD2 = CONVERT(NVARCHAR,@CantFKBd2)+' FOREIGN KEYS'
		SET @Querry = ' '
	 
		IF @CantFKBd1 > 0-- si es mayor a 0 es porque hay fk
		BEGIN
			-- Campo de la tabla que tiene foreing key
			SET @SqlDinamico='DECLARE FK CURSOR FOR SELECT rc.CONSTRAINT_NAME,ccu.TABLE_NAME, ccu.COLUMN_NAME, ccu2.table_name,
			ccu2.COLUMN_NAME
			FROM '+@BD1+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD1+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+'''
			AND (ccu.COLUMN_NAME NOT IN( SELECT ccu.COLUMN_NAME
			FROM '+@BD2+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+''') 
			OR rc.CONSTRAINT_NAME NOT IN ( SELECT rc.CONSTRAINT_NAME
			FROM '+@BD2+'.information_schema.REFERENTIAL_CONSTRAINTS as rc
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu
			ON rc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
			INNER JOIN '+@BD2+'.information_schema.CONSTRAINT_COLUMN_USAGE as ccu2
			ON rc.unique_constraint_name = ccu2.CONSTRAINT_NAME 
			WHERE ccu.TABLE_NAME = '''+@Tabla+''' AND ccu.TABLE_SCHEMA = '''+@Esquema+''') 
			)' 

			EXECUTE sp_executesql @SqlDinamico
			OPEN FK
			FETCH NEXT FROM FK INTO @NombreFk,@TablaFK,@CampoFK,@TablaReferenciada,@CampoReferenciado
		
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@TablaFK+' ADD CONSTRAINT '+ 
				+@NombreFk+' FOREIGN KEY  ('+@CampoFK+') REFERENCES '+@TablaReferenciada+'('+@CampoReferenciado+')'

				INSERT INTO ##Querrys VALUES (@Querry)

				FETCH NEXT FROM FK INTO @NombreFk,@TablaFK,@CampoFK,@CampoReferenciado,@TablaReferenciada	
			END

			CLOSE FK
			DEALLOCATE FK

			
		END
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp_agregarfk: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END

GO

CREATE PROCEDURE sp_CantidadCheck
@BD VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX), @CantCheck INT

	SET @SqlDinamico = 'SELECT @Check = COUNT (*)
						FROM ' + @BD + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS T
						JOIN ' + @BD + '.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS C
						ON T.CONSTRAINT_NAME = C.CONSTRAINT_NAME AND T.TABLE_NAME = C.TABLE_NAME
						WHERE C.TABLE_NAME = ''' + @Tabla + ''' AND C.TABLE_SCHEMA = ''' + @Esquema + '''
						AND T.CONSTRAINT_TYPE = ''Check''
						GROUP BY C.TABLE_NAME'

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@Check INT OUTPUT', @Check = @CantCheck OUTPUT

	IF(@CantCheck IS NULL)
	BEGIN
		 SET @CantCheck = 0
	END

	RETURN @CantCheck
END
GO

CREATE PROCEDURE sp_AgregarCHKs
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @CantCHKBd1 INT,@CantCHKBd2 INT, @SqlDinamico NVARCHAR(MAX), @NombreCHK VARCHAR(50),@Clausula VARCHAR(MAX),
		@CampoCHK VARCHAR(50),@CHKBD1 VARCHAR(100),@CHKBD2 VARCHAR(100),@Querry NVARCHAR(MAX),@ID INT;

		EXECUTE  @CantCHKBd1 = sp_CantidadCheck @Bd1,@Tabla,@Esquema-- a cantidad fks
		EXECUTE  @CantCHKBd2 = sp_CantidadCheck @Bd2,@Tabla,@Esquema-- a cantidad fks

		SET @CHKBD1 = CONVERT(NVARCHAR,@CantCHKBd1)+' CHECKS'
		SET @CHKBD2 = CONVERT(NVARCHAR,@CantCHKBd2)+' CHECKS'
		SET @Querry = ' '
	 
		IF @CantCHKBd1 > 0-- si es mayor a 0 es porque hay chk
		BEGIN
			-- Campo de la tabla que tiene foreing key

			SET @SqlDinamico = 'DECLARE CHK CURSOR FOR SELECT COL.COLUMN_NAME,COL.CONSTRAINT_NAME,CC.CHECK_CLAUSE
			FROM '+@BD1+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			AND (COL.COLUMN_NAME NOT IN ( SELECT COL.COLUMN_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME 
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			) OR COL.CONSTRAINT_NAME NOT IN ( SELECT COL.CONSTRAINT_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			)OR CC.CHECK_CLAUSE NOT IN ( SELECT CC.CHECK_CLAUSE 
			FROM '+@BD2+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			))'
			 
			EXECUTE SP_EXECUTESQL @SqlDinamico

			OPEN CHK
			FETCH NEXT FROM CHK INTO @CampoCHK,@NombreCHK,@Clausula
		
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Querry ='ALTER TABLE '+@Esquema+'.'+@Tabla+' ADD CONSTRAINT '+ 
				+@NombreCHK+' CHECK  ('+@Clausula+')'+CHAR(10)+CHAR(10)

				INSERT INTO ##Querrys VALUES (@Querry)

				FETCH NEXT FROM CHK INTO @CampoCHK,@NombreCHK,@Clausula	
			END

			CLOSE CHK
			DEALLOCATE CHK

		END
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR agregarchks: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_EliminarCHK
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX), @NombreCHK VARCHAR(50),@Querry NVARCHAR(MAX)
		
		SET @Querry = ' '
		SET @SqlDinamico = 'DECLARE DropCHK CURSOR FOR SELECT COL.CONSTRAINT_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			AND (COL.COLUMN_NAME NOT IN ( SELECT COL.COLUMN_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME 
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			) OR COL.CONSTRAINT_NAME NOT IN ( SELECT COL.CONSTRAINT_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			)OR CC.CHECK_CLAUSE NOT IN ( SELECT CC.CHECK_CLAUSE 
			FROM '+@BD1+'.INFORMATION_SCHEMA.CHECK_CONSTRAINTS CC
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
			WHERE COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			))'
			 
			EXECUTE SP_EXECUTESQL @SqlDinamico

			OPEN DropCHK
			FETCH NEXT FROM DropCHK INTO @NombreCHK
		
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' DROP CONSTRAINT '+ 
				+@NombreCHK

				INSERT INTO ##Querrys VALUES (@Querry)

				FETCH NEXT FROM DropCHK INTO @NombreCHK	
			END

			CLOSE DropCHK
			DEALLOCATE DropCHK
		
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp_eliminarchk: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_CantidadUQ
@BD VARCHAR(50), @Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX), @CantUQ INT

	SET @SqlDinamico = 'SELECT @Unique = COUNT (*)
						FROM ' + @BD + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS T
						JOIN ' + @BD + '.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS C 
						ON T.CONSTRAINT_NAME = C.CONSTRAINT_NAME AND T.TABLE_NAME = C.TABLE_NAME
						WHERE C.TABLE_NAME = ''' + @Tabla + ''' AND C.TABLE_SCHEMA = ''' + @Esquema + '''
						AND T.CONSTRAINT_TYPE = ''UNIQUE''
						GROUP BY C.TABLE_NAME'

	EXECUTE SP_EXECUTESQL @SqlDinamico, N'@Unique INT OUTPUT', @Unique = @CantUQ OUTPUT

	IF(@CantUQ IS NULL)
	 SET @CantUQ = 0

	RETURN @CantUQ
END

GO

CREATE PROCEDURE sp_AgregarUQ
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX), @ColumnaUQ VARCHAR(50),@NombreUQ VARCHAR(50),@CantUQDb1 INT,@CantUQDb2 INT,
		@Querry NVARCHAR(MAX),@UQDB1 VARCHAR(20),@UQDB2 VARCHAR(20),@ID INT
		
		SET @Querry = ' '
		EXECUTE @CantUQDb1 = sp_CantidadUQ @BD1,@Tabla,@Esquema
		EXECUTE @CantUQDb2 = sp_CantidadUQ @BD2,@Tabla,@Esquema

		SET @UQDB1 = CONVERT(NVARCHAR,@CantUQDb1)+' UNIQUE'
		SET @UQDB2 = CONVERT(NVARCHAR,@CantUQDb2)+' UNIQUE'
		
		IF @CantUQDb1 > 0
		BEGIN
			SET @SqlDinamico = 'DECLARE UQ CURSOR FOR SELECT COL.COLUMN_NAME,COL.CONSTRAINT_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE''AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			AND (COL.COLUMN_NAME NOT IN ( SELECT COL.COLUMN_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			) OR COL.CONSTRAINT_NAME NOT IN ( SELECT COL.CONSTRAINT_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			))'

			EXECUTE SP_EXECUTESQL @SqlDinamico

			OPEN UQ
			FETCH NEXT FROM UQ INTO @ColumnaUQ,@NombreUQ
		
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' ADD CONSTRAINT '+ 
				+@NombreUQ+' UNIQUE('+@ColumnaUQ+')'

				INSERT INTO ##Querrys VALUES (@Querry)

				FETCH NEXT FROM UQ INTO @ColumnaUQ,@NombreUQ	
			END

			CLOSE UQ
			DEALLOCATE UQ
		END

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR agregaruq: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_EliminarUQ
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@NombreUQ VARCHAR(50),@Querry NVARCHAR(MAX)
		
		SET @Querry = ' '
		
		SET @SqlDinamico = 'DECLARE DropUQ CURSOR FOR SELECT COL.CONSTRAINT_NAME
			FROM '+@BD2+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD2+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE''AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			AND (COL.COLUMN_NAME NOT IN ( SELECT COL.COLUMN_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			) OR COL.CONSTRAINT_NAME NOT IN ( SELECT COL.CONSTRAINT_NAME
			FROM '+@BD1+'.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TAB
			JOIN '+@BD1+'.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE COL
			ON COL.CONSTRAINT_NAME = TAB.CONSTRAINT_NAME AND COL.TABLE_NAME = TAB.TABLE_NAME
			WHERE TAB.CONSTRAINT_TYPE = ''UNIQUE'' AND COL.TABLE_NAME = '''+@Tabla+''' AND COL.TABLE_SCHEMA = '''+@Esquema+'''
			))'

		EXECUTE SP_EXECUTESQL @SqlDinamico
		OPEN DropUQ
		FETCH NEXT FROM DropUQ INTO @NombreUQ
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @Querry ='ALTER TABLE '+@Esquema+'.'+@Tabla+' DROP CONSTRAINT '+ 
				+@NombreUQ
			
			INSERT INTO ##Querrys VALUES (@Querry)

			FETCH NEXT FROM DropUQ INTO @NombreUQ	
		END

		CLOSE DropUQ
		DEALLOCATE DropUQ

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR eliminaruq: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_AgregarColumnas 
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@Columna VARCHAR(100),@Tipo VARCHAR(100),@EsNull VARCHAR(20),@ID INT,
		@Querry NVARCHAR(MAX)
		
		SET @Querry = ' '
		
		SET @SqlDinamico = '
				DECLARE ADDColumna CURSOR FOR SELECT COLUMN1,DATA_TYPE1,IS_NULLABLE1
				FROM (
				SELECT TABLE_NAME TABLE1, 
				COLUMN_NAME COLUMN1,
				CASE WHEN DATA_TYPE=''VARCHAR'' THEN ''VARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''NVARCHAR'' THEN ''NVARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''VARBINARY'' THEN ''VARBINARY(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''CHAR'' THEN ''CHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''DECIMAL'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				WHEN DATA_TYPE=''NUMERIC'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				ELSE UPPER(DATA_TYPE)
				END DATA_TYPE1,
				CASE WHEN IS_NULLABLE=''NO'' THEN ''NOT NULL''
				ELSE ''NULL'' 
				END IS_NULLABLE1
				FROM '+@BD1+'.INFORMATION_SCHEMA.COLUMNS C
				WHERE Table_Name='''+@Tabla+''' and Table_Schema = '''+@Esquema+'''
				) T1
				LEFT OUTER JOIN
				( SELECT TABLE_NAME TABLE2, COLUMN_NAME COLUMN2,
				  CASE WHEN DATA_TYPE=''VARCHAR'' THEN ''VARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''NVARCHAR'' THEN ''NVARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''VARBINARY'' THEN ''VARBINARY(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''CHAR'' THEN ''CHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''DECIMAL'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				  WHEN DATA_TYPE=''NUMERIC'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				  ELSE DATA_TYPE
				  END DATA_TYPE2,
				  CASE WHEN IS_NULLABLE=''NO'' THEN ''NOT NULL''
				  ELSE ''NULL'' 
				  END IS_NULLABLE2
				  FROM '+@BD2+'.INFORMATION_SCHEMA.COLUMNS C
				  WHERE Table_Name='''+@Tabla+''' and Table_Schema = '''+@Esquema+'''
				  ) T2
			      ON T1.COLUMN1 = T2.COLUMN2
				  WHERE ( T2.COLUMN2 IS NULL OR T2.DATA_TYPE2 <> T1.DATA_TYPE1 OR T2.IS_NULLABLE2 <>T1.IS_NULLABLE1
				  )'

		EXECUTE sp_executesql @SqlDinamico
		OPEN ADDColumna
		FETCH NEXT FROM ADDColumna INTO @Columna,@Tipo,@EsNull
		SET @ID = SCOPE_IDENTITY()

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' ADD '+ 
				+@Columna+' '+@Tipo+' '+@EsNull
			
			INSERT INTO ##Querrys VALUES (@Querry)
		
			FETCH NEXT FROM ADDColumna INTO @Columna,@Tipo,@EsNull	
		END

		CLOSE ADDColumna
		DEALLOCATE ADDColumna

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR agregarcolumnas: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_EliminarColumnas 
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@Columna VARCHAR(100),@Querry NVARCHAR(MAX)
		
		SET @Querry = ' '
		
		SET @SqlDinamico = '
				DECLARE DropColumna CURSOR FOR SELECT COLUMN1
				FROM (
				SELECT TABLE_NAME TABLE1, 
				COLUMN_NAME COLUMN1,
				CASE WHEN DATA_TYPE=''VARCHAR'' THEN ''VARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''NVARCHAR'' THEN ''NVARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''VARBINARY'' THEN ''VARBINARY(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''CHAR'' THEN ''CHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN DATA_TYPE=''DECIMAL'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				WHEN DATA_TYPE=''NUMERIC'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				ELSE UPPER(DATA_TYPE)
				END DATA_TYPE1,
				CASE WHEN IS_NULLABLE=''NO'' THEN ''NOT NULL''
				ELSE ''NULL'' 
				END IS_NULLABLE1
				FROM '+@BD2+'.INFORMATION_SCHEMA.COLUMNS C
				WHERE Table_Name='''+@Tabla+''' and Table_Schema = '''+@Esquema+'''
				) T1
				LEFT OUTER JOIN
				( SELECT TABLE_NAME TABLE2, COLUMN_NAME COLUMN2,
				  CASE WHEN DATA_TYPE=''VARCHAR'' THEN ''VARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''NVARCHAR'' THEN ''NVARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''VARBINARY'' THEN ''VARBINARY(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''CHAR'' THEN ''CHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				  WHEN DATA_TYPE=''DECIMAL'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				  WHEN DATA_TYPE=''NUMERIC'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				  ELSE DATA_TYPE
				  END DATA_TYPE2,
				  CASE WHEN IS_NULLABLE=''NO'' THEN ''NOT NULL''
				  ELSE ''NULL'' 
				  END IS_NULLABLE2
				  FROM '+@BD1+'.INFORMATION_SCHEMA.COLUMNS C
				  WHERE Table_Name='''+@Tabla+''' and Table_Schema = '''+@Esquema+'''
				  ) T2
			      ON T1.COLUMN1 = T2.COLUMN2
				  WHERE ( T2.COLUMN2 IS NULL OR T2.DATA_TYPE2 <> T1.DATA_TYPE1 OR T2.IS_NULLABLE2 <>T1.IS_NULLABLE1
				  )'

		EXECUTE sp_executesql @SqlDinamico
		OPEN DropColumna
		FETCH NEXT FROM DropColumna INTO @Columna

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @Querry = 'ALTER TABLE '+@Esquema+'.'+@Tabla+' DROP COLUMN '+ 
				+@Columna
			INSERT INTO ##Querrys VALUES (@Querry)

			FETCH NEXT FROM DropColumna INTO @Columna	
		END

		CLOSE DropColumna
		DEALLOCATE DropColumna

		
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR eliminarcolumnas: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO	

CREATE PROCEDURE sp_CrearTabla 
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	DECLARE @Error VARCHAR(MAX)
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@Columna VARCHAR(100),@Tipo VARCHAR(100),@EsNull VARCHAR(20),
		@Querry NVARCHAR(MAX), @iden INT
		
		SET @Querry = 'CREATE TABLE '+@Esquema+'.'+@Tabla+'('
		SET @SqlDinamico = ' DECLARE Tabla CURSOR FOR SELECT C.COLUMN_NAME COLUMN1,
				CASE WHEN C.DATA_TYPE=''VARCHAR'' THEN ''VARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN C.DATA_TYPE=''NVARCHAR'' THEN ''NVARCHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN C.DATA_TYPE=''VARBINARY'' THEN ''VARBINARY(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN C.DATA_TYPE=''CHAR'' THEN ''CHAR(''+Convert(VARCHAR(10),CHARacter_maximum_length)+'')''
				WHEN C.DATA_TYPE=''DECIMAL'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				WHEN C.DATA_TYPE=''NUMERIC'' THEN ''DECIMAL(''+Convert(VARCHAR(10),NUMERIC_Precision)+'',''+Convert(VARCHAR(10),NUMERIC_Scale)+'')''
				ELSE UPPER(C.DATA_TYPE)
				END DATA_TYPE1,
				CASE WHEN C.IS_NULLABLE=''NO'' THEN ''NOT NULL''
				ELSE ''NULL'' 
				END IS_NULLABLE1
				FROM '+@BD1+'.INFORMATION_SCHEMA.COLUMNS C
				WHERE Table_Name='''+@Tabla+''' and Table_Schema = '''+@Esquema+''''

		EXECUTE sp_executesql @SqlDinamico
		OPEN Tabla
		FETCH NEXT FROM Tabla INTO @Columna,@Tipo,@EsNull
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SqlDinamico = 'SELECT DISTINCT @isIdentitySQL = C.is_identity
								FROM '+@BD1+'.SYS.COLUMNS AS C
								JOIN '+@BD1+'.INFORMATION_SCHEMA.COLUMNS AS I ON C.name = I.COLUMN_NAME
								WHERE I.TABLE_NAME = '''+@Tabla+'''
								AND I.TABLE_SCHEMA = '''+@Esquema+'''
								AND I.COLUMN_NAME = '''+@Columna+''''

			EXECUTE SP_EXECUTESQL @SqlDinamico, N'@isIdentitySQL INT OUTPUT', @isIdentitySQL = @iden OUTPUT

			IF @iden = 1
			BEGIN
				DECLARE @SEED INT, @INC INT

				SELECT @SEED= IDENT_SEED(@BD1+'.'+@Esquema+'.'+@Tabla),@INC = IDENT_INCR(@BD1+'.'+@Esquema+'.'+@Tabla);

				SET @Querry = @Querry +CHAR(10)+@Columna+' '+@Tipo+' IDENTITY('+Convert(VARCHAR(5),@SEED)+','+Convert(VARCHAR(10),@INC)+') '+@EsNull
			END
			ELSE
			BEGIN
				SET @Querry = @Querry +CHAR(10)+@Columna+' '+@Tipo+' '+@EsNull
			END
			
			FETCH NEXT FROM Tabla INTO @Columna,@Tipo,@EsNull

			IF @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = @Querry +','
			END
		END

		SET @Querry = @Querry + ');'

		INSERT INTO ##Querrys VALUES (@Querry)
		
		CLOSE Tabla
		DEALLOCATE Tabla

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR creartabla: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_EliminarTabla 
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@Tabla VARCHAR(100),@Querry NVARCHAR(MAX), @iden INT
		
		SET @Querry = ' ';
		SET @SqlDinamico = 'DECLARE DropTable CURSOR FOR SELECT TABLA1 
							FROM( SELECT TABLE_NAME AS TABLA1 FROM '+@BD2+'.INFORMATION_SCHEMA.TABLES
							WHERE TABLE_TYPE = ''BASE TABLE'' AND TABLE_SCHEMA = '''+@Esquema+''') T1
							LEFT OUTER JOIN(
							SELECT TABLE_NAME AS TABLA2 FROM '+@BD1+'.INFORMATION_SCHEMA.TABLES
							WHERE TABLE_TYPE = ''BASE TABLE'' AND TABLE_SCHEMA = '''+@Esquema+'''
							)T2
							ON T1.TABLA1 = T2.TABLA2
							WHERE (T2.TABLA2 IS NULL )'

		EXECUTE sp_executesql @SqlDinamico

		OPEN DropTable
		
		FETCH NEXT FROM DropTable INTO @Tabla
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @Querry = 'DROP TABLE '+@Esquema+'.'+@Tabla
			INSERT INTO ##Querrys VALUES (@Querry)
			FETCH NEXT FROM DropTable INTO @Tabla		
		END

		CLOSE DropTable
		DEALLOCATE DropTable

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR eliminar tabla: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END		

GO

CREATE PROCEDURE sp_Compare
@BD1 VARCHAR(50),@BD2 VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		DECLARE @NombreTabla VARCHAR(50),@ExisteTabla INT,@NombreEsquema VARCHAR(50),@SqlDinamico NVARCHAR(MAX),
		@ExisteEsquema INT,@Esquema VARCHAR(50),@Querry NVARCHAR(MAX),@Objeto VARCHAR(250),@Validacion VARCHAR(250),
		@ID INT

		BEGIN TRAN
			
			CREATE TABLE ##Querrys
			(	IdQuerry INT NOT NULL identity(1,1) primary key,
			Querry NVARCHAR(MAx)
			);

			CREATE TABLE ##validacion_origen (
				id INT IDENTITY PRIMARY KEY,
				objeto VARCHAR (250),
				validacion VARCHAR (250))

			INSERT INTO ##Querrys VALUES ('USE '+@BD2+';')
			-- verifica que existan las bds
			EXECUTE sp_ExisteBD @BD1,@BD2
			
			EXEc sp_validate_Database_sp @BD1
			EXEC sp_validate_Database_View @BD1
			EXEC sp_validate_DB_name @BD1
			EXEC sp_validate_Table_Triggers @BD1

			-- Verificamos tabla por tabla
			SET @SqlDinamico = 'DECLARE TablasBD CURSOR FOR SELECT TABLE_NAME,TABLE_SCHEMA FROM '+ @BD1+'.INFORMATION_SCHEMA.TABLES'

			Execute sp_executesql @SqlDinamico

			OPEN TablasBD

			FETCH NEXT FROM TablasBD INTO @NombreTabla,@NombreEsquema

			WHILE @@FETCH_STATUS = 0
			BEGIN
				
				EXEC sp_validate_table_name @NombreTabla
				EXEC sp_validate_table_CK @NombreTabla, @BD1
				EXEC sp_validate_table_FK @NombreTabla, @BD1
				EXEC sp_validate_table_PK @NombreTabla, @BD1
				EXEC sp_validate_table_UQ @NombreTabla, @BD1
				
				EXEC @ExisteEsquema = sp_ExisteEsquema @BD2,@NombreEsquema

				IF @ExisteEsquema <> 0
				BEGIN
					SET @Esquema = @NombreEsquema
					EXEC @ExisteTabla = sp_ExisteTabla @BD2,@NombreTabla,@NombreEsquema
				
					IF @ExisteTabla = 0 -- No existe tabla
					BEGIN
						--Creamos Tabla
						EXEC sp_CrearTabla @BD1,@BD2,@NombreTabla,@NombreEsquema
						--Agregamos las Constraint
						EXEC sp_AgregarPK @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarFKs @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarCHKs @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarUQ @BD1,@BD2,@NombreTabla,@NombreEsquema											
					END
					ELSE -- Existe tabla
					BEGIN
						--Eliminamos las contraints que esten demas en la tabla de la bd2
						EXEC sp_EliminarFK @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_EliminarPK @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_EliminarCHK @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_EliminarUQ @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_EliminarColumnas @BD1,@BD2,@NombreTabla,@NombreEsquema
						--Agremos las constraint y columnas faltantes
						EXEC sp_AgregarColumnas @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarPK @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarFKs @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarCHKs @BD1,@BD2,@NombreTabla,@NombreEsquema
						EXEC sp_AgregarUQ @BD1,@BD2,@NombreTabla,@NombreEsquema

					END
				END
				
				FETCH NEXT FROM TablasBD INTO @NombreTabla,@NombreEsquema
			END

			CLOSE TablasBD
			DEALLOCATE TablasBD
			EXEC sp_EliminarTabla @BD1,@BD2,@Esquema

			SET @SqlDinamico = 'DECLARE querrys CURSOR FOR SELECT Querry FROM ##Querrys'


			Execute sp_executesql @SqlDinamico

			OPEN querrys

			FETCH NEXT FROM querrys INTO @Querry

			PRINT '**************** SENTENCIAS PARA COMPARAR IGUALAR TABLA ***************************'

			WHILE @@FETCH_STATUS = 0
			BEGIN
				PRINT @Querry
				FETCH NEXT FROM querrys INTO @Querry
			END
			
			PRINT '***********************************************************************************'
			
			CLOSE querrys
			DEALLOCATE querrys 

			DROP TABLE ##Querrys
			
			SET @SqlDinamico = 'DECLARE validaciones CURSOR FOR SELECT objeto,validacion FROM ##validacion_origen'


			Execute sp_executesql @SqlDinamico

			OPEN validaciones

			FETCH NEXT FROM validaciones INTO @Objeto,@Validacion
			PRINT '******************************** Validaciones ***********************************'
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				PRINT @Objeto+' --> '+@Validacion
				FETCH NEXT FROM validaciones INTO @Objeto,@Validacion
			END
			PRINT '***********************************************************************************'
			
			CLOSE validaciones
			DEALLOCATE validaciones

			DROP TABLE ##validacion_origen
			
			COMMIT TRAN
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorLine INT;
		DECLARE @ErrorNumber INT;
		DECLARE @SYSUSER NVARCHAR(200);
		DECLARE @FECHA DATETIME;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE(),
			@ErrorLine = ERROR_LINE(),
			@ErrorNumber = ERROR_NUMBER(),
			@SysUser = SYSTEM_USER,
			@Fecha = GETDATE();
		
		
		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR sp_compare: Revise la tabla Log_Errores. INFORMACION: ' 
	END CATCH
END

--USE DB_Compare

--Execute sp_ExisteBD 'Bdx','Bd2' -- Falta verificar si entra al catch

