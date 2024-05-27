USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
GO

CREATE LOGIN housewife WITH PASSWORD = 'admin';

ALTER LOGIN housewife WITH DEFAULT_DATABASE=[housewife], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

USE housewife;

CREATE USER housewife FOR LOGIN housewife;

ALTER ROLE db_owner ADD MEMBER housewife;

ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [housewife]
