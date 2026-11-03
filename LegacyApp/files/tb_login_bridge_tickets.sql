USE [learnasp]
GO

IF OBJECT_ID(N'dbo.tb_login_bridge_tickets', N'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[tb_login_bridge_tickets](
    [ticket_hash] [varbinary](32) NOT NULL,
    [user_id] [int] NOT NULL,
    [username] [nvarchar](100) NOT NULL,
    [expires_at] [datetime2](0) NOT NULL,
    CONSTRAINT [PK_tb_login_bridge_tickets] PRIMARY KEY CLUSTERED ([ticket_hash] ASC),
    CONSTRAINT [FK_tb_login_bridge_tickets_tb_users]
      FOREIGN KEY ([user_id]) REFERENCES [dbo].[tb_users]([user_id])
      ON DELETE CASCADE
  )
END
GO
