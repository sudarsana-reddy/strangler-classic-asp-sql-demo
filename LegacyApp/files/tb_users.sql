USE [learnasp]
GO

IF OBJECT_ID(N'dbo.tb_users', N'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[tb_users](
    [user_id] [int] IDENTITY(1,1) NOT NULL,
    [username] [nvarchar](100) NOT NULL,
    [password_salt] [varbinary](16) NOT NULL,
    [password_hash] [varbinary](64) NOT NULL,
    [is_active] [bit] NOT NULL CONSTRAINT [DF_tb_users_is_active] DEFAULT (1),
    [created_at] [datetime2](0) NOT NULL CONSTRAINT [DF_tb_users_created_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_tb_users] PRIMARY KEY CLUSTERED ([user_id] ASC),
    CONSTRAINT [UQ_tb_users_username] UNIQUE ([username])
  )
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_users] WHERE [username] = N'demo')
BEGIN
  DECLARE @DemoPassword NVARCHAR(256) = N'ClassicAsp!2026'
  DECLARE @DemoSalt VARBINARY(16) = CRYPT_GEN_RANDOM(16)

  INSERT INTO [dbo].[tb_users] ([username], [password_salt], [password_hash])
  VALUES (
    N'demo',
    @DemoSalt,
    HASHBYTES('SHA2_512', @DemoSalt + CONVERT(varbinary(512), @DemoPassword))
  )
END
GO
