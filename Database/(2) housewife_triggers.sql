USE housewife;
GO
CREATE TRIGGER TR_AfterIncomeInsert
ON incomes
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InsertedMonth DATE;
    SELECT @InsertedMonth = DATEFROMPARTS(YEAR(i.date), MONTH(i.date), 1)
    FROM inserted i;

    IF EXISTS (
        SELECT 1
        FROM monthly_net_amount
        WHERE month = @InsertedMonth
    )
    BEGIN
        UPDATE m
        SET m.amount = m.amount + i.amount
        FROM monthly_net_amount m
        INNER JOIN inserted i ON m.month = @InsertedMonth;
    END
    ELSE
    BEGIN
        INSERT INTO monthly_net_amount (amount, month)
        SELECT i.amount, @InsertedMonth
        FROM inserted i;
    END
END;

GO

CREATE TRIGGER TR_AfterMonthlyNetAmountChange
ON monthly_net_amount
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldTotalAmount DECIMAL(10,2);
    DECLARE @NewTotalAmount DECIMAL(10,2);

    -- Calculate the old total amount
    SELECT @OldTotalAmount = ISNULL(SUM(amount), 0) FROM deleted;

    -- Calculate the new total amount
    SELECT @NewTotalAmount = ISNULL(SUM(amount), 0) FROM inserted;

    -- Calculate the difference between old and new total amounts
    DECLARE @AmountDifference DECIMAL(10,2);
    SET @AmountDifference = @NewTotalAmount - @OldTotalAmount;

    -- Update the balance table
    IF EXISTS (SELECT 1 FROM balance)
    BEGIN
        -- Update the existing row by adding the amount difference
        UPDATE balance SET amount = amount + @AmountDifference;
    END
    ELSE
    BEGIN
        -- Insert a new row with the new total amount
        INSERT INTO balance (amount) VALUES (@NewTotalAmount);
    END
END;


GO

CREATE TRIGGER CheckBalanceAndInsertExpense
ON expenses
AFTER INSERT
AS
BEGIN
    DECLARE @ExpenseAmount DECIMAL(10, 2);
    DECLARE @Balance DECIMAL(10, 2);

    -- Get the amount of the newly inserted expense
    SELECT @ExpenseAmount = amount FROM inserted;

    -- Get the current balance
    SELECT @Balance = amount FROM balance;

    -- Check if the balance is enough for the expense
    IF @ExpenseAmount <= @Balance
    BEGIN
        -- Subtract the expense amount from the balance
        UPDATE balance SET amount = @Balance - @ExpenseAmount;
    END
    ELSE
    BEGIN
        -- If the balance is not enough, rollback the transaction
        RAISERROR ('Insufficient balance for current expense.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

Go

CREATE TRIGGER UpdateBalanceAndTotalSavingAfterSaving
ON saving
AFTER INSERT, UPDATE
AS
BEGIN
    -- Declare variables
    DECLARE @Amount DECIMAL(10, 2);
    DECLARE @TotalSavingId INT;

    -- Get the inserted or updated saving amount
    SELECT @Amount = amount
    FROM inserted;

    -- Update the balance table by subtracting the current inputted amount
    UPDATE balance
    SET amount = amount - @Amount;

    -- Check if total_saving table has a record
    SELECT @TotalSavingId = id
    FROM total_saving;

    -- If total_saving table has a record, add the inserted amount to the existing amount
    IF @TotalSavingId IS NOT NULL
    BEGIN
        UPDATE total_saving
        SET amount = amount + @Amount;
    END
    ELSE
    BEGIN
        -- If total_saving table doesn't have a record, insert a new record with the inserted amount
        INSERT INTO total_saving (amount)
        VALUES (@Amount);
    END
END;

GO

CREATE TRIGGER UpdateTotalSavingAndBalanceAfterWithdrawal
ON withdraw_saving
AFTER INSERT
AS
BEGIN
    -- Declare variables
    DECLARE @WithdrawalAmount DECIMAL(10, 2);
    DECLARE @TotalSaving DECIMAL(10, 2);

    -- Get the inserted withdrawal amount from the inserted table
    SELECT @WithdrawalAmount = amount
    FROM inserted;

    -- Get the current total saving amount
    SELECT @TotalSaving = amount
    FROM total_saving;

    -- Check if the withdrawal amount doesn't exceed the total saving
    IF @WithdrawalAmount <= @TotalSaving
    BEGIN
        -- Subtract the withdrawal amount from total_saving
        UPDATE total_saving
        SET amount = amount - @WithdrawalAmount;

        -- Add the withdrawal amount to the balance
        UPDATE balance
        SET amount = amount + @WithdrawalAmount;
    END
    ELSE
    BEGIN
        -- Raise an error if withdrawal amount exceeds total saving
        RAISERROR ('Insufficient balance for withdrawal.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;








