:setvar Table "Foo"

IF OBJECT_ID('$(Table)') > 0
BEGIN
    DROP TABLE $(Table)
END