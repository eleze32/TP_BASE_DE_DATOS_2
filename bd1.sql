USE [Bd1]
GO
/****** Object:  Table [dbo].[Tabla1]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tabla1](
	[Tabla1Id] [int] IDENTITY(1,1) NOT NULL,
	[Campo1] [varchar](20) NULL,
	[campo2] [datetime] NOT NULL,
	[Campo3] [decimal](2, 2) NULL,
 CONSTRAINT [PK_Tabla1] PRIMARY KEY CLUSTERED 
(
	[Tabla1Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tabla1ConTabla2]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tabla1ConTabla2](
	[Tabla1Id] [int] NOT NULL,
	[Tabla2Id] [int] NOT NULL,
 CONSTRAINT [PK_Tabla1ConTabla2] PRIMARY KEY CLUSTERED 
(
	[Tabla1Id] ASC,
	[Tabla2Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tabla2]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tabla2](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Campo1] [int] NULL,
	[campo2] [varchar](10) NULL,
	[Campo3] [decimal](2, 2) NOT NULL,
 CONSTRAINT [pk_id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tabla3]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tabla3](
	[Tabla3Id] [varchar](20) NOT NULL,
	[Campo1] [int] NULL,
	[Campo2] [varchar](10) NULL,
	[Campo3] [decimal](2, 2) NOT NULL,
 CONSTRAINT [pk_tabla3] PRIMARY KEY CLUSTERED 
(
	[Tabla3Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_Campo2] UNIQUE NONCLUSTERED 
(
	[Campo2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tabla4]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tabla4](
	[Tabla4Id] [int] IDENTITY(1,1) NOT NULL,
	[Campo1] [int] NULL,
	[Campo2] [varchar](10) NULL,
	[Campo3] [decimal](2, 2) NOT NULL,
	[Campo4] [int] NULL,
 CONSTRAINT [PK_Tabla4] PRIMARY KEY CLUSTERED 
(
	[Tabla4Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Tabla1ConTabla2]  WITH CHECK ADD  CONSTRAINT [FK_Tabla1ConTabla2_Tabla1] FOREIGN KEY([Tabla1Id])
REFERENCES [dbo].[Tabla1] ([Tabla1Id])
GO
ALTER TABLE [dbo].[Tabla1ConTabla2] CHECK CONSTRAINT [FK_Tabla1ConTabla2_Tabla1]
GO
ALTER TABLE [dbo].[Tabla1ConTabla2]  WITH CHECK ADD  CONSTRAINT [FK_Tabla1ConTabla2_Tabla2] FOREIGN KEY([Tabla2Id])
REFERENCES [dbo].[tabla2] ([Id])
GO
ALTER TABLE [dbo].[Tabla1ConTabla2] CHECK CONSTRAINT [FK_Tabla1ConTabla2_Tabla2]
GO
ALTER TABLE [dbo].[Tabla4]  WITH CHECK ADD  CONSTRAINT [FK_Tabla4_Tabla1] FOREIGN KEY([Campo4])
REFERENCES [dbo].[Tabla1] ([Tabla1Id])
GO
ALTER TABLE [dbo].[Tabla4] CHECK CONSTRAINT [FK_Tabla4_Tabla1]
GO
ALTER TABLE [dbo].[Tabla3]  WITH CHECK ADD  CONSTRAINT [CHK_Campo1] CHECK  (([Campo1]>(5)))
GO
ALTER TABLE [dbo].[Tabla3] CHECK CONSTRAINT [CHK_Campo1]
GO
/****** Object:  StoredProcedure [dbo].[sp_CrearTabla]    Script Date: 18/7/2019 01:11:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CrearTabla] 
@BD1 VARCHAR(50),@BD2 VARCHAR(50),@Tabla VARCHAR(50),@Esquema VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON
		DECLARE @SqlDinamico NVARCHAR(MAX),@Columna VARCHAR(100),@Tipo VARCHAR(100),@EsNull VARCHAR(20),
		@Querry NVARCHAR(MAX), @iden CHAR(2)
		
		SET @Querry = 'CREATE TABLE '+@EsNull+'.'+@Tabla+'('
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
				FROM '+@BD1+'.INFORMATION_SCHEMA.COLUMNS C'
		EXECUTE sp_executesql @SqlDinamico
		OPEN Tabla
		FETCH NEXT FROM Tabla INTO @Columna,@Tipo,@EsNull
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @Querry = @Querry +CHAR(10)+@Columna+' '+@Tipo+' '+@EsNull

			FETCH NEXT FROM Tabla INTO @Columna,@Tipo,@EsNull

			IF @@FETCH_STATUS = 0
			BEGIN
				SET @Querry = @Querry +','
			END
		END

		SET @Querry = @Querry + ');'+ CHAR(10)

		CLOSE Tabla
		DEALLOCATE Tabla

		Print @Querry
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLine INT,@ErrorNumber INT, @SYSUSER NVARCHAR(200), @FECHA DATETIME, @ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT, @ErrorState INT;
		
		SELECT @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE(),@ErrorNumber = ERROR_NUMBER(),@SysUser = SYSTEM_USER,@Fecha = GETDATE();

		INSERT INTO DB_Compare.dbo.Log_Errores(Descripcion,Linea_Excepcion, Numero_Error, Severidad, Estado, Fecha, Usuario)
		VALUES(@ErrorMessage,@ErrorLine, @ErrorNumber, @ErrorSeverity, @ErrorState, @Fecha, @SysUser)
		
		PRINT 'ERROR: Revise la tabla Log_Errores. INFORMACION: ' + ERROR_MESSAGE()
	END CATCH
END	
GO
