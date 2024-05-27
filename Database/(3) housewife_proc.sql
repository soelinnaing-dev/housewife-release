USE housewife;
GO

CREATE PROCEDURE CheckBudgetAndBalance
    @Description VARCHAR(255),
    @FromToFlow VARCHAR(255),
    @CashFlow VARCHAR(25),
    @Amount DECIMAL(10,2),
    @Date DATE,
    @StatusCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DescriptionId INT;
    DECLARE @FromToFlowId INT;
    DECLARE @CashFlowId INT;
    DECLARE @ExpenseMonth DATE;
    DECLARE @BudgetAmount DECIMAL(10,2);
    DECLARE @TotalExpenses DECIMAL(10,2);

    SET @StatusCode = 0;

    SELECT @DescriptionId = id FROM descriptions WHERE description = @Description;
    SELECT @FromToFlowId = id FROM from_to_flow WHERE text = @FromToFlow;
    SELECT @CashFlowId = id FROM cash_flow WHERE text = @CashFlow;

    SET @ExpenseMonth = DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1);
    SELECT @BudgetAmount = amount FROM expenditure_budgets WHERE month = @ExpenseMonth;

    IF @BudgetAmount IS NULL
    BEGIN
        SET @StatusCode = 1;
        RETURN;
    END

    SELECT @TotalExpenses = ISNULL(SUM(amount), 0)
    FROM expenses
    WHERE
    MONTH(date) = MONTH(@Date)
    AND YEAR(date) = YEAR(@Date);

    SET @TotalExpenses = @TotalExpenses + @Amount;

    IF @TotalExpenses > @BudgetAmount
    BEGIN
        SET @StatusCode = 2;
        RETURN;
    END
END;

GO

CREATE PROCEDURE AddNewIncome
    @Description VARCHAR(255),
    @FromToFlow VARCHAR(255),
    @User VARCHAR(25),
    @CashFlow VARCHAR(25),
    @Amount DECIMAL(10,2),
    @Date DATE,
    @InsertedId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DescriptionId INT;
    DECLARE @FromToFlowId INT;
    DECLARE @UserId INT;
    DECLARE @CashFlowId INT;

    SELECT @DescriptionId = id FROM descriptions WHERE description = @Description;
    SELECT @FromToFlowId = id FROM from_to_flow WHERE text = @FromToFlow;
    SELECT @UserId = id FROM users WHERE name = @User;
    SELECT @CashFlowId = id FROM cash_flow WHERE text = @CashFlow;

    INSERT INTO incomes (description_id, from_to_flow_id, user_id, amount, cash_flow_id, date)
    VALUES (@DescriptionId, @FromToFlowId, @UserId, @Amount, @CashFlowId, @Date);

    SET @InsertedId = SCOPE_IDENTITY();

    SELECT @InsertedId AS InsertedId;
END;


GO

CREATE PROCEDURE AddNewExpense
    @Description VARCHAR(255),
    @FromToFlow VARCHAR(255),
    @User VARCHAR(25),
    @CashFlow VARCHAR(25),
    @Amount DECIMAL(10,2),
    @Date DATE,
    @InsertedId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DescriptionId INT;
    DECLARE @FromToFlowId INT;
    DECLARE @UserId INT;
    DECLARE @CashFlowId INT;

    SELECT @DescriptionId = id FROM descriptions WHERE description = @Description;
    SELECT @FromToFlowId = id FROM from_to_flow WHERE text = @FromToFlow;
    SELECT @UserId = id FROM users WHERE name = @User;
    SELECT @CashFlowId = id FROM cash_flow WHERE text = @CashFlow;

    INSERT INTO expenses (description_id, from_to_flow_id, user_id, amount, cash_flow_id, date)
    VALUES (@DescriptionId, @FromToFlowId, @UserId, @Amount, @CashFlowId, @Date);

    SET @InsertedId = SCOPE_IDENTITY();

    SELECT @InsertedId AS InsertedId;
END;

GO 

CREATE PROCEDURE AddNewSaving
    @Username VARCHAR(25),
    @Amount DECIMAL(10,2),
    @SavingMonth DATE,
    @StatusCode INT OUTPUT,
	@InsertedId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ExistingBalance DECIMAL(10,2);
	DECLARE @UserId INT ;

    SELECT @UserId = id FROM users WHERE username = @Username;

	SELECT @ExistingBalance = COALESCE((SELECT TOP 1 amount FROM balance), 0.00);

    IF @Amount > @ExistingBalance
    BEGIN
        SET @StatusCode = 2;
		RETURN;
    END
    ELSE
    BEGIN
		SET @StatusCode = 0;
		
        INSERT INTO saving (user_id, amount, saving_month)
        VALUES (@UserId, @Amount, @SavingMonth);
		
		SET @InsertedId = SCOPE_IDENTITY();    
    END
END;

GO

CREATE PROCEDURE Login
@username VARCHAR(25),
@password VARCHAR(50)
AS
BEGIN
	SELECT name,username,password FROM users WHERE username = @username AND password = HASHBYTES('sha2_256',@password);
END;

GO

CREATE PROCEDURE LoadUsers
AS
BEGIN
	SELECT username  from users;
END;

GO

CREATE PROCEDURE GetIncome -- Version 1.0.0
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [From], users.name AS Name, cash_flow.text AS Payment,incomes.amount AS Amount, incomes.date AS Date
	FROM incomes
	INNER JOIN descriptions ON incomes.description_id = descriptions.id
	INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON incomes.user_id = users.id
	INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
	WHERE MONTH(incomes.date) = MONTH(GETDATE()) AND YEAR(incomes.date) = YEAR(GETDATE());
END;

GO

CREATE PROCEDURE GetExpense -- Version 1.0.0
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [To], users.name AS Name, cash_flow.text AS Payment,expenses.amount AS Amount, expenses.date AS Date
	FROM expenses
	INNER JOIN descriptions ON expenses.description_id = descriptions.id
	INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON expenses.user_id = users.id
	INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
	WHERE MONTH(expenses.date) = MONTH(GETDATE()) AND YEAR(expenses.date) = YEAR(GETDATE());
END;

GO

CREATE PROCEDURE GetIncomeByMonth -- Version 1.0.0
@Year INT,
@Month INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [From], users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount, incomes.date AS Date
	FROM incomes
	INNER JOIN descriptions ON incomes.description_id = descriptions.id
	INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON incomes.user_id = users.id
	INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
	WHERE YEAR(incomes.date) = @Year AND MONTH(incomes.date) = @Month;

END;

GO

CREATE PROCEDURE GetExpenseByMonth -- Version 1.0.0
@Year INT,
@Month INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [To], users.name AS Name, cash_flow.text AS Payment, expenses.amount AS Amount, expenses.date AS Date
	FROM expenses
	INNER JOIN descriptions ON expenses.description_id = descriptions.id
	INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON expenses.user_id = users.id
	INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
	WHERE YEAR(expenses.date) = @Year AND MONTH(expenses.date) = @Month;

END;

GO

CREATE PROCEDURE GetIncomeByUser -- Version 1.0.0
    @Username VARCHAR(25)
AS
BEGIN
    SELECT descriptions.description AS Description, from_to_flow.text AS [From], users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount,  incomes.date AS Date
    FROM incomes
    INNER JOIN descriptions ON incomes.description_id = descriptions.id
    INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON incomes.user_id = users.id
    INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
    WHERE users.username LIKE '%' + @Username + '%';
END;

GO

CREATE PROCEDURE GetExpenseByUser -- Version 1.0.0
    @Username VARCHAR(25)
AS
BEGIN
    SELECT descriptions.description AS Description, from_to_flow.text AS [To], users.name AS Name, cash_flow.text AS Payment, expenses.amount AS Amount,  expenses.date AS Date
    FROM expenses
    INNER JOIN descriptions ON expenses.description_id = descriptions.id
    INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON expenses.user_id = users.id
    INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
    WHERE users.username LIKE '%' + @Username + '%';
END;

GO

CREATE PROCEDURE ExpenseFormLoading -- Version 1.0.0
AS
BEGIN
	SELECT description FROM descriptions;
	SELECT text AS [To] FROM from_to_flow;
	SELECT text AS Payment FROM cash_flow;
END;

GO

CREATE PROCEDURE InsertDescription
@name VARCHAR(255)
AS
BEGIN
	INSERT INTO descriptions(description) values(@name);
END;

GO

CREATE PROCEDURE InsertFromToFlow
@name VARCHAR(255)
AS
BEGIN
	INSERT INTO from_to_flow(text) values(@name);
END;

GO

CREATE PROCEDURE InsertCashFlow
@name VARCHAR(255)
AS
BEGIN
	INSERT INTO cash_flow(text) values(@name);
END;

GO

CREATE PROCEDURE LoadBalance
AS
BEGIN
	SELECT amount FROM balance;
END;

GO

CREATE PROCEDURE AddExpenditureBudget    
    @month DATE,
	@amount DECIMAL(10, 2),
    @insertedId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @balance DECIMAL(10, 2);
    SELECT @balance = amount FROM balance;
    IF @balance >= @amount
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM expenditure_budgets
            WHERE month = DATEFROMPARTS(YEAR(@month), MONTH(@month), 1)
        )
        BEGIN
            INSERT INTO expenditure_budgets (month, amount)
            VALUES (DATEFROMPARTS(YEAR(@month), MONTH(@month), 1), @amount);
            SET @insertedId = SCOPE_IDENTITY();

            SELECT id, month, amount
            FROM expenditure_budgets
            WHERE id = @insertedId;

            RETURN;
        END
        ELSE
        BEGIN
            THROW 51001, 'A budget record already exists for the inputted year and month.', 1;
        END
    END
    ELSE
    BEGIN
        THROW 51000, 'Your balance is not enough for the budget amount.', 1;
    END
END;

GO

CREATE PROCEDURE GetBudgetByYear
    @yearPattern VARCHAR(5) 
AS
BEGIN
    SET NOCOUNT ON;

    IF @yearPattern IS NULL
    BEGIN
        THROW 50000, 'Year pattern parameter cannot be null.', 1;
        RETURN;
    END

    SELECT 
        CAST(YEAR(month) AS VARCHAR(4)) + '-' + LEFT(DATENAME(MONTH, month), 3) AS [YearMonth],
        amount 
    FROM expenditure_budgets 
    WHERE CAST(YEAR(month) AS VARCHAR(4)) LIKE @yearPattern + '%'; -- Use the LIKE operator with the parameter
END;

GO

CREATE PROCEDURE GetBudgetByMonthOfCurrentYear
    @monthName VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @currentYear INT;
    SET @currentYear = YEAR(GETDATE());
    
    SELECT 
        CAST(@currentYear AS VARCHAR(4)) + '-' + LEFT(DATENAME(MONTH, month), 3) AS [YearMonth],
        amount 
    FROM expenditure_budgets 
    WHERE DATENAME(MONTH, month) LIKE @monthName + '%' AND YEAR(month) = @currentYear;
END;

GO

CREATE PROCEDURE LoadAllBudgets
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT FORMAT(month, 'yyyy-MMM') AS [Year-Month], amount AS Amount
    FROM expenditure_budgets
    ORDER BY month
    OFFSET 0 ROWS
    FETCH NEXT 50 ROWS ONLY;
END;


GO

CREATE PROCEDURE SavingLoad
@username VARCHAR(25)
AS
BEGIN
	DECLARE @user_id INT;
	SELECT @user_id = id FROM users WHERE username = @username;
	SELECT users.name AS [User], saving_month AS [Saving Month], amount AS Amount FROM saving
	INNER JOIN users on saving.user_id = users.id;
	SELECT ISNULL(amount,0) FROM total_saving;
END;

GO

CREATE PROCEDURE WithdrawSaving
    @username VARCHAR(25),
    @date DATE,
    @Amount DECIMAL(10,2)
AS
BEGIN
    DECLARE @user_id INT;
    DECLARE @existingSavingAmount DECIMAL(10,2);

    SELECT @user_id = id FROM users WHERE username = @username;

    SELECT @existingSavingAmount = amount FROM total_saving;

    IF @Amount <= @existingSavingAmount
    BEGIN
        INSERT INTO withdraw_saving (user_id, date, amount)
        VALUES (@user_id, @date, @Amount);
    END
    ELSE
    BEGIN
        THROW 52000, 'Your withdrawal amount exceeds the existing total saving.', 1;
    END
END;

GO

CREATE PROCEDURE GetSavingByInsertedID
@InsertedId INT
AS
BEGIN
	SELECT users.name AS [User], saving_month AS [Saving Date], amount AS Amount FROM saving
	INNER JOIN users on saving.user_id = users.id
	WHERE saving.id = @InsertedId;
END;

GO

CREATE PROCEDURE GetSavingByYearly
@yearPattern VARCHAR(5)
AS
BEGIN
	SELECT users.name AS [User], CAST(YEAR(saving_month) AS VARCHAR(4)) + '-' + LEFT(DATENAME(MONTH, saving_month), 3) AS [YearAndMonth], amount AS Amount FROM saving
	INNER JOIN users ON saving.user_id = users.id
	WHERE CAST(YEAR(saving_month) AS VARCHAR(4)) LIKE @yearPattern + '%';
END;

GO

CREATE PROCEDURE GetSavingByMonthsOfCurrentYear
@monthName VARCHAR(20)
AS
BEGIN
	DECLARE @currentYear INT;
	SET @currentYear = YEAR(GETDATE());
	SELECT users.name AS [User], FORMAT(saving_month, 'yyyy-MMM-dd') AS [YearAndMonth], amount AS Amount FROM saving
	INNER JOIN users ON saving.user_id = users.id
	WHERE DATENAME(MONTH, saving_month) LIKE @monthName + '%' AND YEAR(saving_month) = @currentYear;
END; 

GO

CREATE PROCEDURE GetTotalSaving
AS
BEGIN
    DECLARE @total DECIMAL(10, 2)

    SELECT @total = ISNULL(amount, 0.00) FROM total_saving;

    SELECT @total AS TotalSaving;
END;


GO

CREATE PROCEDURE GetwithdrawalByUser
@Name VARCHAR(25)
AS

BEGIN
	SELECT users.name AS [User], CAST(YEAR(date) AS VARCHAR(4)) + '-' + LEFT(DATENAME(MONTH, date), 3) AS [YearAndMonth],
	'-' + CAST(amount AS VARCHAR(20)) AS WithdrawalAmount FROM withdraw_saving
	INNER JOIN users ON withdraw_saving.user_id = users.id
	WHERE users.name LIKE @Name + '%';
END;

GO

CREATE PROCEDURE GetwithdrawByYearly
@withdrawyearPattern VARCHAR(4)
AS
BEGIN
	
	SELECT users.name AS [User], CAST(Year(date) AS VARCHAR(4)) + '-' + LEFT(DATENAME(MONTH,date),3) AS [YearAndMonth],
	'-' + CAST(amount AS VARCHAR(20)) AS WithdrawalAmount FROM withdraw_saving
	INNER JOIN users ON withdraw_saving.user_id = users.id
	WHERE CAST(YEAR(date) AS VARCHAR(4)) LIKE @withdrawyearPattern + '%';
END;

GO

CREATE PROCEDURE GetWithdrawByCurrentYear
@withdrawMonth VARCHAR(20)
AS
BEGIN
    DECLARE @currentYear INT;
    SET @currentYear = YEAR(GETDATE());

    SELECT 
        users.name AS [User], 
        FORMAT(date, 'yyyy-MMM-dd') AS [WithdrawalDate], 
        '-' + CAST(amount AS VARCHAR(20)) AS Amount 
    FROM 
        withdraw_saving
    INNER JOIN 
        users ON withdraw_saving.user_id = users.id
    WHERE 
        DATENAME(MONTH, date) LIKE @withdrawMonth + '%' 
        AND YEAR(date) = @currentYear;
END;

GO


CREATE PROCEDURE AddNewWithdrawSaving
@userName VARCHAR(25),
@Amount DECIMAL(10,2),
@InsertedId INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TotalSaving DECIMAL(10, 2);
    DECLARE @WithdrawAmount DECIMAL(10, 2);

    SELECT @TotalSaving = amount FROM total_saving;
    SET @WithdrawAmount = @Amount;

    IF @TotalSaving < @WithdrawAmount
    BEGIN
        RAISERROR ('Insufficient balance for withdrawal.', 16, 1);
		RETURN;
    END
	ELSE
	BEGIN
	DECLARE @user_id INT;
	DECLARE @date DATE;
	SELECT @user_id = id FROM users WHERE name = @userName;
	SET @date = CONVERT(DATE,GETDATE());
	
	INSERT INTO withdraw_saving(user_id, date, amount) VALUES(@user_id, @date,@Amount);
	SET @InsertedId = SCOPE_IDENTITY();
	END;
END;
-- Reporting Procedures
GO

CREATE PROCEDURE GetIncomeTypeAverageByYearly -- Version 1.0.0
AS
BEGIN
    DECLARE @TopIncomeType INT;

    WITH TopIncomeTypes AS (
        SELECT TOP 1 WITH TIES
            I.description_id,
            COUNT(*) AS IncomeTypeCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) -- Select data from the last 5 years
        GROUP BY
            I.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopIncomeType = description_id
    FROM
        TopIncomeTypes;

    WITH YearlyIncomeCounts AS (
        SELECT
            YEAR(I.date) AS Year,
            COUNT(*) AS IncomeCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) -- Select data from the last 5 years
            AND I.description_id = @TopIncomeType
        GROUP BY
            YEAR(I.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year -- Get the year 5 years ago
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE()) -- Generate years from 5 years ago to the current year
    )
    SELECT
        AllYears.Year,
        (SELECT description FROM descriptions WHERE id = @TopIncomeType) AS TopIncomeType,
        ISNULL(IncomeCount, 0) AS IncomeCount
    FROM
        AllYears
    LEFT JOIN
        YearlyIncomeCounts ON AllYears.Year = YearlyIncomeCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetIncomeTypeAverageByMonthly -- Version 1.0.0 not used;
AS
BEGIN
    DECLARE @TopIncomeType INT;

    WITH TopIncomeTypes AS (
        SELECT TOP 1 WITH TIES
            I.description_id,
            COUNT(*) AS IncomeTypeCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            I.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopIncomeType = description_id
    FROM
        TopIncomeTypes;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyIncomeCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(I.id) AS IncomeCount
        FROM
            Months
        LEFT JOIN
            incomes I ON MONTH(I.date) = MonthNumber AND YEAR(I.date) = YEAR(GETDATE())
                       AND I.description_id = @TopIncomeType
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyIncomeCounts.MonthName,
        (SELECT description FROM descriptions WHERE id = @TopIncomeType) AS TopIncomeType,
        COALESCE(MonthlyIncomeCounts.IncomeCount, 0) AS IncomeCount
    FROM
        MonthlyIncomeCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetIncomeSourceAverageByYearly -- Version 1.0.0 ,not used
AS
BEGIN
    DECLARE @TopIncomeType INT;

    ;WITH TopIncomeTypes AS (
        SELECT TOP 1 WITH TIES
            I.description_id,
            COUNT(*) AS IncomeTypeCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            I.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopIncomeType = description_id
    FROM
        TopIncomeTypes;

    IF NOT EXISTS (SELECT 1 FROM from_to_flow WHERE [text] = (SELECT description FROM descriptions WHERE id = @TopIncomeType))
    BEGIN
        INSERT INTO from_to_flow ([text])
        SELECT description FROM descriptions WHERE id = @TopIncomeType;
    END

    ;WITH YearlyIncomeCounts AS (
        SELECT
            YEAR(I.date) AS Year,
            COUNT(*) AS IncomeCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
            AND I.description_id = @TopIncomeType
        GROUP BY
            YEAR(I.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE())
    )
    SELECT
        AllYears.Year,
        (SELECT [text] FROM from_to_flow WHERE id = @TopIncomeType) AS TopIncomeSource,
        ISNULL(IncomeCount, 0) AS IncomeCount
    FROM
        AllYears
    LEFT JOIN
        YearlyIncomeCounts ON AllYears.Year = YearlyIncomeCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetIncomeSourceAverageByMonthly
AS
BEGIN
    DECLARE @TopIncomeSource INT;

    WITH TopIncomeSources AS (
        SELECT TOP 1 WITH TIES
            I.from_to_flow_id,
            COUNT(*) AS IncomeSourceCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            I.from_to_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopIncomeSource = from_to_flow_id
    FROM
        TopIncomeSources;

    IF NOT EXISTS (SELECT 1 FROM from_to_flow WHERE id = @TopIncomeSource)
    BEGIN
        DECLARE @IncomeSourceText VARCHAR(255);
        SELECT @IncomeSourceText = [text] FROM from_to_flow WHERE id = @TopIncomeSource;
        INSERT INTO from_to_flow ([text]) VALUES (@IncomeSourceText);
    END

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyIncomeSourceCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(I.id) AS IncomeCount
        FROM
            Months
        LEFT JOIN
            incomes I ON MONTH(I.date) = MonthNumber AND YEAR(I.date) = YEAR(GETDATE())
                       AND I.from_to_flow_id = @TopIncomeSource
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyIncomeSourceCounts.MonthName,
        (SELECT [text] FROM from_to_flow WHERE id = @TopIncomeSource) AS TopIncomeSource,
        COALESCE(MonthlyIncomeSourceCounts.IncomeCount, 0) AS IncomeCount
    FROM
        MonthlyIncomeSourceCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetPaymentMethodAverageByYearly -- Version 1.0.0 not used
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH TopPaymentMethods AS (
        SELECT TOP 1 WITH TIES
            I.cash_flow_id,
            COUNT(*) AS PaymentMethodCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            I.cash_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopPaymentMethod = cash_flow_id
    FROM
        TopPaymentMethods;

    IF NOT EXISTS (SELECT 1 FROM cash_flow WHERE id = @TopPaymentMethod)
    BEGIN
        INSERT INTO cash_flow ([text])
        SELECT text FROM from_to_flow WHERE id = @TopPaymentMethod;
    END

    ;WITH YearlyPaymentCounts AS (
        SELECT
            YEAR(I.date) AS Year,
            COUNT(*) AS PaymentCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
            AND I.cash_flow_id = @TopPaymentMethod
        GROUP BY
            YEAR(I.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year 
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE()) 
    )
    SELECT
        AllYears.Year,
        (SELECT [text] FROM cash_flow WHERE id = @TopPaymentMethod) AS TopPaymentMethod,
        ISNULL(PaymentCount, 0) AS PaymentCount
    FROM
        AllYears
    LEFT JOIN
        YearlyPaymentCounts ON AllYears.Year = YearlyPaymentCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetPaymentMethodAverageByMonthly -- Version 1.0.0 not used
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    WITH TopPaymentMethods AS (
        SELECT TOP 1 WITH TIES
            I.cash_flow_id,
            COUNT(*) AS PaymentMethodCount
        FROM
            incomes I
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            I.cash_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopPaymentMethod = cash_flow_id
    FROM
        TopPaymentMethods;

    IF NOT EXISTS (SELECT 1 FROM cash_flow WHERE id = @TopPaymentMethod)
    BEGIN
        DECLARE @PaymentMethodText VARCHAR(25);
        SELECT @PaymentMethodText = [text] FROM cash_flow WHERE id = @TopPaymentMethod;
        INSERT INTO cash_flow ([text]) VALUES (@PaymentMethodText);
    END

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyPaymentMethodCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(I.id) AS PaymentCount
        FROM
            Months
        LEFT JOIN
            incomes I ON MONTH(I.date) = MonthNumber AND YEAR(I.date) = YEAR(GETDATE())
                       AND I.cash_flow_id = @TopPaymentMethod
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyPaymentMethodCounts.MonthName,
        (SELECT [text] FROM cash_flow WHERE id = @TopPaymentMethod) AS TopPaymentMethod,
        COALESCE(MonthlyPaymentMethodCounts.PaymentCount, 0) AS PaymentCount
    FROM
        MonthlyPaymentMethodCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetExpenseTypeAverageByYearly
AS
BEGIN
    DECLARE @TopExpenseType INT;

    WITH TopExpenseTypes AS (
        SELECT TOP 1 WITH TIES
            E.description_id,
            COUNT(*) AS ExpenseTypeCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            E.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopExpenseType = description_id
    FROM
        TopExpenseTypes;

    WITH YearlyExpenseCounts AS (
        SELECT
            YEAR(E.date) AS Year,
            COUNT(*) AS ExpenseCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
            AND E.description_id = @TopExpenseType
        GROUP BY
            YEAR(E.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year 
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE()) 
    )
    SELECT
        AllYears.Year,
        (SELECT description FROM descriptions WHERE id = @TopExpenseType) AS TopExpenseType,
        ISNULL(ExpenseCount, 0) AS ExpenseCount
    FROM
        AllYears
    LEFT JOIN
        YearlyExpenseCounts ON AllYears.Year = YearlyExpenseCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetExpenseTypeAverageByMonthly
AS
BEGIN  
    DECLARE @TopExpenseType INT;

    WITH TopExpenseTypes AS (
        SELECT TOP 1 WITH TIES
            E.description_id,
            COUNT(*) AS ExpenseTypeCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) = YEAR(GETDATE())
        GROUP BY
            E.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopExpenseType = description_id
    FROM
        TopExpenseTypes;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyExpenseCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(E.id) AS ExpenseCount
        FROM
            Months
        LEFT JOIN
            expenses E ON MONTH(E.date) = MonthNumber AND YEAR(E.date) = YEAR(GETDATE())
                       AND E.description_id = @TopExpenseType
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyExpenseCounts.MonthName,
        (SELECT description FROM descriptions WHERE id = @TopExpenseType) AS TopExpenseType,
        COALESCE(MonthlyExpenseCounts.ExpenseCount, 0) AS ExpenseCount
    FROM
        MonthlyExpenseCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetExpenseDestinationAverageByYearly
AS
BEGIN
    DECLARE @TopExpenseType INT;

    ;WITH TopExpenseTypes AS (
        SELECT TOP 1 WITH TIES
            E.description_id,
            COUNT(*) AS ExpenseTypeCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            E.description_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopExpenseType = description_id
    FROM
        TopExpenseTypes;

    IF NOT EXISTS (SELECT 1 FROM from_to_flow WHERE [text] = (SELECT description FROM descriptions WHERE id = @TopExpenseType))
    BEGIN
        INSERT INTO from_to_flow ([text])
        SELECT description FROM descriptions WHERE id = @TopExpenseType;
    END

    ;WITH YearlyExpenseCounts AS (
        SELECT
            YEAR(E.date) AS Year,
            COUNT(*) AS ExpenseCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
            AND E.description_id = @TopExpenseType
        GROUP BY
            YEAR(E.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year 
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE()) 
    )
    SELECT
        AllYears.Year,
        (SELECT [text] FROM from_to_flow WHERE id = @TopExpenseType) AS TopExpenseDestination,
        ISNULL(ExpenseCount, 0) AS ExpenseCount
    FROM
        AllYears
    LEFT JOIN
        YearlyExpenseCounts ON AllYears.Year = YearlyExpenseCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetExpenseDestinationAverageByMonthly
AS
BEGIN
    DECLARE @TopExpenseDestination INT;

    WITH TopExpenseDestinations AS (
        SELECT TOP 1 WITH TIES
            E.from_to_flow_id,
            COUNT(*) AS ExpenseDestinationCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) = YEAR(GETDATE()) 
        GROUP BY
            E.from_to_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopExpenseDestination = from_to_flow_id
    FROM
        TopExpenseDestinations;

    IF NOT EXISTS (SELECT 1 FROM from_to_flow WHERE id = @TopExpenseDestination)
    BEGIN
        DECLARE @ExpenseDestinationText VARCHAR(255);
        SELECT @ExpenseDestinationText = [text] FROM from_to_flow WHERE id = @TopExpenseDestination;
        INSERT INTO from_to_flow ([text]) VALUES (@ExpenseDestinationText);
    END

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyExpenseDestinationCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(E.id) AS ExpenseCount
        FROM
            Months
        LEFT JOIN
            expenses E ON MONTH(E.date) = MonthNumber AND YEAR(E.date) = YEAR(GETDATE())
                       AND E.from_to_flow_id = @TopExpenseDestination
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyExpenseDestinationCounts.MonthName,
        (SELECT [text] FROM from_to_flow WHERE id = @TopExpenseDestination) AS TopExpenseDestination,
        COALESCE(MonthlyExpenseDestinationCounts.ExpenseCount, 0) AS ExpenseCount
    FROM
        MonthlyExpenseDestinationCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetExpensePaymentMethodAverageByYearly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH TopPaymentMethods AS (
        SELECT TOP 1 WITH TIES
            E.cash_flow_id,
            COUNT(*) AS PaymentMethodCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            E.cash_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopPaymentMethod = cash_flow_id
    FROM
        TopPaymentMethods;

    IF NOT EXISTS (SELECT 1 FROM cash_flow WHERE id = @TopPaymentMethod)
    BEGIN
        INSERT INTO cash_flow ([text])
        SELECT text FROM from_to_flow WHERE id = @TopPaymentMethod;
    END

    ;WITH YearlyPaymentCounts AS (
        SELECT
            YEAR(E.date) AS Year,
            COUNT(*) AS PaymentCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
            AND E.cash_flow_id = @TopPaymentMethod
        GROUP BY
            YEAR(E.date)
    ),
    AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year 
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE()) 
    )
    SELECT
        AllYears.Year,
        (SELECT [text] FROM cash_flow WHERE id = @TopPaymentMethod) AS TopPaymentMethod,
        ISNULL(PaymentCount, 0) AS PaymentCount
    FROM
        AllYears
    LEFT JOIN
        YearlyPaymentCounts ON AllYears.Year = YearlyPaymentCounts.Year
    ORDER BY
        AllYears.Year;
END;

GO

CREATE PROCEDURE GetExpensePaymentMethodAverageByMonthly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    WITH TopPaymentMethods AS (
        SELECT TOP 1 WITH TIES
            E.cash_flow_id,
            COUNT(*) AS PaymentMethodCount
        FROM
            expenses E
        WHERE
            YEAR(E.date) = YEAR(GETDATE()) 
        GROUP BY
            E.cash_flow_id
        ORDER BY
            COUNT(*) DESC
    )
    SELECT TOP 1
        @TopPaymentMethod = cash_flow_id
    FROM
        TopPaymentMethods;

    IF NOT EXISTS (SELECT 1 FROM cash_flow WHERE id = @TopPaymentMethod)
    BEGIN
        DECLARE @PaymentMethodText VARCHAR(25);
        SELECT @PaymentMethodText = [text] FROM cash_flow WHERE id = @TopPaymentMethod;
        INSERT INTO cash_flow ([text]) VALUES (@PaymentMethodText);
    END

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyPaymentMethodCounts AS (
        SELECT
            MonthNumber,
            DATENAME(MONTH, DATEADD(MONTH, MonthNumber - 1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))) AS MonthName,
            COUNT(E.id) AS PaymentCount
        FROM
            Months
        LEFT JOIN
            expenses E ON MONTH(E.date) = MonthNumber AND YEAR(E.date) = YEAR(GETDATE())
                       AND E.cash_flow_id = @TopPaymentMethod
        GROUP BY
            MonthNumber
    )
    SELECT
        MonthlyPaymentMethodCounts.MonthName,
        (SELECT [text] FROM cash_flow WHERE id = @TopPaymentMethod) AS TopPaymentMethod,
        COALESCE(MonthlyPaymentMethodCounts.PaymentCount, 0) AS PaymentCount
    FROM
        MonthlyPaymentMethodCounts
    ORDER BY
        MONTH(DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1));
END;

GO

CREATE PROCEDURE GetExceedingBudgetMonthsByYearly
AS
BEGIN
    DECLARE @CurrentYear INT = YEAR(GETDATE());
    DECLARE @LoopYear INT = @CurrentYear - 5;

    CREATE TABLE #ExceedingBudgetMonths (
        Year INT,
        Month VARCHAR(3),
        Budget DECIMAL(10, 2),
        TotalExpense DECIMAL(10, 2)
    );

    WHILE @LoopYear <= @CurrentYear
    BEGIN
        DECLARE @LoopMonth INT = 1;
        WHILE @LoopMonth <= 12
        BEGIN
            INSERT INTO #ExceedingBudgetMonths (Year, Month, Budget, TotalExpense)
            SELECT 
                YEAR(E.date) AS Year,
                LEFT(DATENAME(MONTH, DATEFROMPARTS(YEAR(E.date), @LoopMonth, 1)), 3) AS Month,
                B.amount AS Budget,
                COALESCE(SUM(E.amount), 0) AS TotalExpense
            FROM 
                expenditure_budgets B
            LEFT JOIN 
                expenses E ON YEAR(E.date) = @LoopYear AND MONTH(E.date) = @LoopMonth
            WHERE 
                YEAR(B.month) = @LoopYear AND MONTH(B.month) = @LoopMonth
            GROUP BY 
                YEAR(E.date), MONTH(E.date), B.amount
            HAVING 
                COALESCE(SUM(E.amount), 0) > B.amount;

            SET @LoopMonth = @LoopMonth + 1;
        END

        SET @LoopYear = @LoopYear + 1;
    END

    SELECT * FROM #ExceedingBudgetMonths;

    DROP TABLE #ExceedingBudgetMonths;
END;

GO

CREATE PROCEDURE GetCurrentYearExceedingBudgetMonths
AS
BEGIN
    CREATE TABLE #ExceedingBudgetMonths (
        Month VARCHAR(3),
        Budget DECIMAL(10, 2),
        TotalExpense DECIMAL(10, 2)
    );

    DECLARE @LoopMonth INT = 1;
    WHILE @LoopMonth <= 12
    BEGIN
        INSERT INTO #ExceedingBudgetMonths (Month, Budget, TotalExpense)
        SELECT 
            LEFT(DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), @LoopMonth, 1)), 3) AS Month,
            B.amount AS Budget,
            COALESCE(SUM(E.amount), 0) AS TotalExpense
        FROM 
            expenditure_budgets B
        LEFT JOIN 
            expenses E ON YEAR(E.date) = YEAR(GETDATE()) AND MONTH(E.date) = @LoopMonth
        WHERE 
            YEAR(B.month) = YEAR(GETDATE()) AND MONTH(B.month) = @LoopMonth
        GROUP BY 
            MONTH(E.date), B.amount
        HAVING 
            COALESCE(SUM(E.amount), 0) > B.amount;

        SET @LoopMonth = @LoopMonth + 1;
    END

    SELECT * FROM #ExceedingBudgetMonths;

    DROP TABLE #ExceedingBudgetMonths;
END;

GO

CREATE PROCEDURE GetIncomeByInsertedId -- Version 1.0.0
@InsertedId INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [From],
    users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount, incomes.date AS Date
    FROM incomes
    INNER JOIN descriptions ON incomes.description_id = descriptions.id
    INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON incomes.user_id = users.id
    INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
    WHERE incomes.id = @InsertedId;
END;

GO
CREATE PROCEDURE GetExpenseByInsertedId -- Version 1.0.0
@InsertedId INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [To], cash_flow.text AS Payment, expenses.amount AS Amount, expenses.date AS Date FROM expenses INNER JOIN descriptions ON expenses.description_id = descriptions.id INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id INNER JOIN users ON expenses.user_id = users.id INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id WHERE expenses.id = @InsertedId;
END;

GO

CREATE PROCEDURE GetBudgetByInsertedId
@InsertedId INT
AS
BEGIN
	SELECT month AS Date, amount AS BudgetAmount FROM expenditure_budgets WHERE id = @InsertedId;
END;

GO

CREATE PROCEDURE GetUserInfo
@username VARCHAR(25)
AS
BEGIN
	SELECT name, username FROM users WHERE username = @username;
END;

GO

CREATE PROCEDURE UpdateUserInfo
    @Name VARCHAR(25),
    @userName VARCHAR(25),
    @password VARCHAR(50),
    @defUserName VARCHAR(25)
AS
BEGIN
    UPDATE users 
    SET 
        name = @Name, 
        username = @userName, 
        password = HASHBYTES('sha2_256', @password) 
    OUTPUT 
        inserted.name, inserted.username
    WHERE 
        username = @defUserName;
END;

GO

CREATE PROCEDURE CheckPassword
    @defUserName VARCHAR(25),
    @password VARCHAR(50),
    @message VARCHAR(255) OUTPUT
AS
BEGIN
    IF EXISTS(SELECT username, password
    FROM users
    WHERE username = @defUserName AND password = HASHBYTES('sha2_256',@password))
    BEGIN
		SET @message = 'Password Correct';
	END
	ELSE
	BEGIN
		SET @message = 'Your Old Password Incorrect!';
	END;
END;

GO

CREATE PROCEDURE AddNewUser
@Name VARCHAR(25),
@userName VARCHAR(25),
@password VARCHAR(50),
@message VARCHAR(255) OUTPUT
AS
BEGIN
	IF EXISTS(SELECT user FROM users WHERE username = @userName)
	BEGIN
		SET @message = 'User already exists.';
		RETURN;
	END
	ELSE
	BEGIN
	INSERT INTO users(name,username,password) VALUES(@Name,@userName,HASHBYTES('sha2_256',@password));
		SET @message = 'User registration successful!';
	END;
END;
-- Version 1.1.0 new Procedures

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeByUser
    @Year INT,
    @MonthName VARCHAR(50),
    @UserName VARCHAR(50)
AS
BEGIN
    DECLARE @MonthNumber INT;
    DECLARE @RowCount INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @MonthNumber = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT @RowCount = COUNT(*), @TotalAmount = SUM(i.amount)
    FROM incomes i
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND u.username = @UserName;

    SELECT d.description AS Description, ft.text AS Customer, u.name AS [User], cf.text AS Payment, 
           i.amount AS Amount, FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND u.username = @UserName;

    SELECT @RowCount AS [Total Count], @TotalAmount AS [Total Amount];
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseByUser
    @Year INT,
    @MonthName VARCHAR(50),
    @UserName VARCHAR(50)
AS
BEGIN
    DECLARE @MonthNumber INT = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT 
        d.description AS Description, 
        ft.text AS Supplier, 
        u.name AS [User], 
        cf.text AS Payment, 
        '- ' + FORMAT(i.amount, '0.00') AS Amount, 
        FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND u.username = @UserName;

    SELECT 
        COUNT(*) AS [Total Count],
        '- ' + FORMAT(SUM(i.amount), '0.00') AS [Total Amount] -- Add minus sign to total amount
    FROM 
        expenses i
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND u.username = @UserName;

END;


GO

CREATE OR ALTER PROCEDURE DRptGetIncomeByDescription
    @Year INT,
    @MonthName VARCHAR(50),
    @Description VARCHAR(255)
AS
BEGIN
    DECLARE @MonthNumber INT;
    DECLARE @RowCount INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @MonthNumber = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT @RowCount = COUNT(*), @TotalAmount = SUM(i.amount)
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND d.description = @Description;

    SELECT d.description AS Description, ft.text AS Customer, u.name AS [User], cf.text AS Payment, 
           i.amount AS Amount, FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND d.description = @Description;

    SELECT @RowCount AS [Total Count], @TotalAmount AS [Total Amount];
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseByDescription
    @Year INT,
    @MonthName VARCHAR(50),
    @Description VARCHAR(255)
AS
BEGIN
    DECLARE @MonthNumber INT = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT 
        d.description AS Description, 
        ft.text AS Supplier, 
        u.name AS [User], 
        cf.text AS Payment, 
        '- ' + FORMAT(i.amount, '0.00') AS Amount, 
        FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND d.description = @Description;

    SELECT 
        COUNT(*) AS [Total Count],
        '- ' + FORMAT(SUM(i.amount), '0.00') AS [Total Amount] 
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND d.description = @Description;

END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeByPayment
    @Year INT,
    @MonthName VARCHAR(50),
    @Payment VARCHAR(25)
AS
BEGIN
    DECLARE @MonthNumber INT;
    DECLARE @RowCount INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @MonthNumber = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT @RowCount = COUNT(*), @TotalAmount = SUM(i.amount)
    FROM incomes i
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND cf.text = @Payment;

    SELECT d.description AS Description, ft.text AS Customer, u.name AS [User], cf.text AS Payment, 
           i.amount AS Amount, FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND cf.text = @Payment;

    SELECT @RowCount AS [Total Count], @TotalAmount AS [Total Amount];
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseByPayment
    @Year INT,
    @MonthName VARCHAR(50),
    @Payment VARCHAR(25)
AS
BEGIN
    DECLARE @MonthNumber INT = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT 
        d.description AS Description, 
        ft.text AS Supplier, 
        u.name AS [User], 
        cf.text AS Payment, 
        '- ' + FORMAT(i.amount, '0.00') AS Amount,
        FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND cf.text = @Payment;

    SELECT 
        COUNT(*) AS [Total Count],
        '- ' + FORMAT(SUM(i.amount), '0.00') AS [Total Amount]
    FROM 
        expenses i
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND cf.text = @Payment;

END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeByIncomeSource
    @Year INT,
    @MonthName VARCHAR(50),
    @SourceDest VARCHAR(255)
AS
BEGIN
    DECLARE @MonthNumber INT;
    DECLARE @RowCount INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @MonthNumber = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT @RowCount = COUNT(*), @TotalAmount = SUM(i.amount)
    FROM incomes i
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND ft.text = @SourceDest;

    SELECT d.description AS Description, ft.text AS Customer, u.name AS [User], cf.text AS Payment, 
           i.amount AS Amount, FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber
    AND ft.text = @SourceDest;

    SELECT @RowCount AS [Total Count], @TotalAmount AS [Total Amount];
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseBySourceDest
    @Year INT,
    @MonthName VARCHAR(50),
    @SourceDest VARCHAR(255)
AS
BEGIN
    DECLARE @MonthNumber INT = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT 
        d.description AS Description, 
        ft.text AS Supplier, 
        u.name AS [User], 
        cf.text AS Payment, 
        '- ' + FORMAT(i.amount, '0.00') AS Amount, 
        FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND ft.text = @SourceDest;

    SELECT 
        COUNT(*) AS [Total Count],
        '- ' + FORMAT(SUM(i.amount), '0.00') AS [Total Amount]
    FROM 
        expenses i
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber
        AND ft.text = @SourceDest;

END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseByMonth
    @Year INT,
    @MonthName VARCHAR(50)
AS
BEGIN
    DECLARE @MonthNumber INT = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT 
        d.description AS Description, 
        ft.text AS Supplier, 
        u.name AS [User], 
        cf.text AS Payment, 
        '- ' + FORMAT(i.amount, '0.00') AS Amount,
        FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM 
        expenses i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN 
        cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN 
        users u ON i.user_id = u.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber;

    SELECT 
        COUNT(*) AS [Total Count],
        '- ' + FORMAT(SUM(i.amount), '0.00') AS [Total Amount] 
    FROM 
        expenses i
    INNER JOIN 
        from_to_flow ft ON i.from_to_flow_id = ft.id
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = @MonthNumber;

END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeSummaryByDescription
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        d.description AS DescriptionName,
        COUNT(i.id) AS DescriptionCount,
        SUM(i.amount) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        incomes i
    INNER JOIN 
        descriptions d ON i.description_id = d.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = MONTH(@StartDate)
    GROUP BY 
        d.description, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT description_id) AS TotalDescriptionCount,
        SUM(amount) AS DescriptionsTotalAmount
    FROM 
        incomes
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseSummaryByDescription
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        d.description AS DescriptionName,
        COUNT(e.id) AS DescriptionCount,
        CONCAT('-', ' ', SUM(e.amount)) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        expenses e
    INNER JOIN 
        descriptions d ON e.description_id = d.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(e.date) = @Year
        AND MONTH(e.date) = MONTH(@StartDate)
    GROUP BY 
        d.description, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT description_id) AS TotalDescriptionCount,
        CONCAT('-', ' ', SUM(amount)) AS DescriptionsTotalAmount
    FROM 
        expenses
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeSummaryByPayment
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        c.text AS PaymentName,
        COUNT(i.id) AS PaymentCount,
        SUM(i.amount) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        incomes i
    INNER JOIN 
        cash_flow c ON i.cash_flow_id = c.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = MONTH(@StartDate)
    GROUP BY 
        c.text, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT cash_flow_id) AS TotalPaymentCount,
        SUM(amount) AS PaymentTotalAmount
    FROM 
        incomes
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseSummaryByPayment
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        c.text AS PaymentName,
        COUNT(e.id) AS PaymentCount,
        CONCAT('-', ' ', SUM(e.amount)) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        expenses e
    INNER JOIN 
        cash_flow c ON e.cash_flow_id = c.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(e.date) = @Year
        AND MONTH(e.date) = MONTH(@StartDate)
    GROUP BY 
        c.text, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT cash_flow_id) AS TotalPaymentCount,
        CONCAT('-', ' ', SUM(amount)) AS PaymentTotalAmount
    FROM 
        expenses
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeSummaryBySource
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        f.text AS Customer,
        COUNT(i.id) AS CustomerCount,
        SUM(i.amount) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        incomes i
    INNER JOIN 
        from_to_flow f ON i.from_to_flow_id = f.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(i.date) = @Year
        AND MONTH(i.date) = MONTH(@StartDate)
    GROUP BY 
        f.text, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT from_to_flow_id) AS TotalMainCount, -- main mean source
        SUM(amount) AS MainTotalAmount -- main mean source
    FROM 
        incomes
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE DRptGetExpenseSummaryByDestination
    @Year INT,
    @Month VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, MONTH(@Month + ' 1, 2000'), 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);
    DECLARE @MonthYear VARCHAR(20) = CONCAT(DATENAME(MONTH, @StartDate), '-', @Year);

    SELECT 
        f.text AS SupplierName,
        COUNT(e.id) AS SupplierCount,
        CONCAT('-', ' ', SUM(e.amount)) AS TotalAmount,
        m.[Month Of Year]
    FROM 
        expenses e
    INNER JOIN 
        from_to_flow f ON e.from_to_flow_id = f.id
    CROSS JOIN 
        (SELECT @MonthYear AS [Month Of Year]) AS m
    WHERE 
        YEAR(e.date) = @Year
        AND MONTH(e.date) = MONTH(@StartDate)
    GROUP BY 
        f.text, m.[Month Of Year]
    ORDER BY 
        TotalAmount DESC;

    SELECT 
        COUNT(DISTINCT from_to_flow_id) AS TotalMainCount, -- main mean destination
        CONCAT('-', ' ', SUM(amount)) AS MainTotalAmount -- main mean destination
    FROM 
        expenses
    WHERE 
        YEAR(date) = @Year
        AND MONTH(date) = MONTH(@StartDate);
END;

GO

CREATE OR ALTER PROCEDURE GetUserName
AS
BEGIN
	SELECT name FROM users;
END;

GO

CREATE OR ALTER PROCEDURE GetDescriptionName
AS
BEGIN
	SELECT description FROM descriptions;
END;

GO

CREATE OR ALTER PROCEDURE GetPayment
AS
BEGIN
	SELECT text FROM cash_flow;
END;

GO

CREATE OR ALTER PROCEDURE GetSourceDestName
AS
BEGIN
	SELECT text FROM from_to_flow;
END;

GO

CREATE OR ALTER PROCEDURE IncomeFormLoading -- Version 1.1.0
AS
BEGIN
	SELECT description FROM descriptions;
	SELECT text AS [Customer] FROM from_to_flow;
	SELECT text AS Payment FROM cash_flow;
END;

GO

CREATE OR ALTER PROCEDURE GetIncome -- Version 1.1.0
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS [Customer], users.name AS Name, cash_flow.text AS Payment,incomes.amount AS Amount, incomes.date AS Date
	FROM incomes
	INNER JOIN descriptions ON incomes.description_id = descriptions.id
	INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON incomes.user_id = users.id
	INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
	WHERE MONTH(incomes.date) = MONTH(GETDATE()) AND YEAR(incomes.date) = YEAR(GETDATE());
END;

GO

CREATE OR ALTER PROCEDURE DRptGetIncomeByMonth
    @Year INT,
    @MonthName VARCHAR(50)
AS
BEGIN
    DECLARE @MonthNumber INT;
    DECLARE @RowCount INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @MonthNumber = MONTH(DATEFROMPARTS(@Year, 
                        CASE @MonthName
                            WHEN 'January' THEN 1
                            WHEN 'February' THEN 2
                            WHEN 'March' THEN 3
                            WHEN 'April' THEN 4
                            WHEN 'May' THEN 5
                            WHEN 'June' THEN 6
                            WHEN 'July' THEN 7
                            WHEN 'August' THEN 8
                            WHEN 'September' THEN 9
                            WHEN 'October' THEN 10
                            WHEN 'November' THEN 11
                            WHEN 'December' THEN 12
                        END, 1));

    SELECT @RowCount = COUNT(*), @TotalAmount = SUM(i.amount)
    FROM incomes i
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber;

    SELECT d.description AS Description, ft.text AS Customer, u.name AS [User], cf.text AS Payment, 
           i.amount AS Amount, FORMAT(i.date, 'dd-MMM-yyyy') AS [Date]
    FROM incomes i
    INNER JOIN descriptions d ON i.description_id = d.id
    INNER JOIN from_to_flow ft ON i.from_to_flow_id = ft.id
    INNER JOIN cash_flow cf ON i.cash_flow_id = cf.id
    INNER JOIN users u ON i.user_id = u.id
    WHERE YEAR(i.date) = @Year
    AND MONTH(i.date) = @MonthNumber;

    SELECT @RowCount AS [Total Count], @TotalAmount AS [Total Amount];
END;

GO

CREATE OR ALTER PROCEDURE GetIncomeByUser -- Version 1.1.0
    @Username VARCHAR(25)
AS
BEGIN
    SELECT descriptions.description AS Description, from_to_flow.text AS Customer, users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount,  incomes.date AS Date
    FROM incomes
    INNER JOIN descriptions ON incomes.description_id = descriptions.id
    INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON incomes.user_id = users.id
    INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
    WHERE users.username LIKE '%' + @Username + '%';
END;

GO

CREATE OR ALTER PROCEDURE GetIncomeByInsertedId -- Version 1.1.0
@InsertedId INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS Customer,
    users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount, incomes.date AS Date
    FROM incomes
    INNER JOIN descriptions ON incomes.description_id = descriptions.id
    INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON incomes.user_id = users.id
    INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
    WHERE incomes.id = @InsertedId;
END;

GO

CREATE OR ALTER PROCEDURE GetIncomeByMonth -- Version 1.1.0
@Year INT,
@Month INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS Customer, users.name AS Name, cash_flow.text AS Payment, incomes.amount AS Amount, incomes.date AS Date
	FROM incomes
	INNER JOIN descriptions ON incomes.description_id = descriptions.id
	INNER JOIN from_to_flow ON incomes.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON incomes.user_id = users.id
	INNER JOIN cash_flow ON incomes.cash_flow_id = cash_flow.id
	WHERE YEAR(incomes.date) = @Year AND MONTH(incomes.date) = @Month;

END;

GO

CREATE OR ALTER PROCEDURE GetExpenseByInsertedId -- Version 1.1.0
@InsertedId INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS Supplier, cash_flow.text AS Payment, expenses.amount AS Amount, expenses.date AS Date FROM expenses INNER JOIN descriptions ON expenses.description_id = descriptions.id INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id INNER JOIN users ON expenses.user_id = users.id INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id WHERE expenses.id = @InsertedId;
END;

GO

CREATE OR ALTER PROCEDURE GetExpenseByUser -- Version 1.1.0
    @Username VARCHAR(25)
AS
BEGIN
    SELECT descriptions.description AS Description, from_to_flow.text AS Supplier, users.name AS Name, cash_flow.text AS Payment, expenses.amount AS Amount,  expenses.date AS Date
    FROM expenses
    INNER JOIN descriptions ON expenses.description_id = descriptions.id
    INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
    INNER JOIN users ON expenses.user_id = users.id
    INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
    WHERE users.username LIKE '%' + @Username + '%';
END;

GO

CREATE OR ALTER PROCEDURE GetExpenseByMonth -- Version 1.1.0
@Year INT,
@Month INT
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS Supplier, users.name AS Name, cash_flow.text AS Payment, expenses.amount AS Amount, expenses.date AS Date
	FROM expenses
	INNER JOIN descriptions ON expenses.description_id = descriptions.id
	INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON expenses.user_id = users.id
	INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
	WHERE YEAR(expenses.date) = @Year AND MONTH(expenses.date) = @Month;

END;

GO

CREATE OR ALTER PROCEDURE GetExpense -- Version 1.1.0
AS
BEGIN
	SELECT descriptions.description AS Description, from_to_flow.text AS Supplier, users.name AS Name, cash_flow.text AS Payment,expenses.amount AS Amount, expenses.date AS Date
	FROM expenses
	INNER JOIN descriptions ON expenses.description_id = descriptions.id
	INNER JOIN from_to_flow ON expenses.from_to_flow_id = from_to_flow.id
	INNER JOIN users ON expenses.user_id = users.id
	INNER JOIN cash_flow ON expenses.cash_flow_id = cash_flow.id
	WHERE MONTH(expenses.date) = MONTH(GETDATE()) AND YEAR(expenses.date) = YEAR(GETDATE());
END;

GO

CREATE OR ALTER PROCEDURE ExpenseFormLoading -- Version 1.1.0
AS
BEGIN
	SELECT description FROM descriptions;
	SELECT text AS Supplier FROM from_to_flow;
	SELECT text AS Payment FROM cash_flow;
END;

GO

CREATE OR ALTER PROCEDURE GetTopDescriptionForEachYear -- Version 1.1.0
AS
BEGIN
    WITH AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE())
    ),
    YearlyTopDescriptions AS (
        SELECT 
            YEAR(I.date) AS Year,
            I.description_id,
            D.description,
            COUNT(*) AS DescriptionCount,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            incomes I
        INNER JOIN
            descriptions D ON I.description_id = D.id
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE()))
        GROUP BY
            YEAR(I.date), I.description_id, D.description
    )
    SELECT
        Y.Year,
        ISNULL(YT.description, 'No Data') AS TopDescription,
        ISNULL(YT.DescriptionCount, 0) AS DescriptionCount
    FROM
        AllYears Y
    LEFT JOIN
        YearlyTopDescriptions YT ON Y.Year = YT.Year AND YT.RowNum = 1
    ORDER BY
        Y.Year;
END;

GO

CREATE PROCEDURE GetTopCustomerByYearly
AS
BEGIN
    ;WITH YearlyTopCustomers AS (
        SELECT 
            YEAR(I.date) AS Year,
            FT.[text] AS TopCustomer,
            COUNT(*) AS Count,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            incomes I
        INNER JOIN
            from_to_flow FT ON I.from_to_flow_id = FT.id
        GROUP BY
            YEAR(I.date), FT.[text]
    )
    SELECT
        Year,
        TopCustomer,
        Count
    FROM
        YearlyTopCustomers
    WHERE
        RowNum = 1; 
END;

GO

CREATE PROCEDURE GetTopIncomePaymentMethodByYearly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH YearlyTopPaymentMethods AS (
        SELECT 
            YEAR(I.date) AS Year,
            CF.[text] AS TopPaymentMethod,
            COUNT(*) AS PaymentCount,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            incomes I
        INNER JOIN
            cash_flow CF ON I.cash_flow_id = CF.id
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            YEAR(I.date), CF.[text]
    )
    SELECT
        Year,
        TopPaymentMethod,
        PaymentCount
    FROM
        YearlyTopPaymentMethods
    WHERE
        RowNum = 1; 
END;

GO

CREATE PROCEDURE GetTopIncomeDescriptionByMonthly
AS
BEGIN

    DECLARE @TopDescription INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopDescriptions AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            D.description AS TopDescription,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            incomes I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            descriptions D ON I.description_id = D.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), D.description
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS [Month],
        TopDescription,
        [Count]
    FROM
        MonthlyTopDescriptions
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE PROCEDURE GetTopIncomeCustomerByMonthly
AS
BEGIN
    DECLARE @TopCustomer INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopCustomers AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            FTF.[text] AS TopCustomer,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            incomes I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            from_to_flow FTF ON I.from_to_flow_id = FTF.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), FTF.[text]
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS Month,
        TopCustomer,
        [Count]
    FROM
        MonthlyTopCustomers
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE PROCEDURE GetTopIncomePaymentMethodByMonthly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopPaymentMethods AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            CF.[text] AS TopPaymentMethod,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            incomes I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            cash_flow CF ON I.cash_flow_id = CF.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), CF.[text]
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS Month,
        TopPaymentMethod,
        [Count]
    FROM
        MonthlyTopPaymentMethods
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE PROCEDURE GetTopExpenseDescriptionByMonthly
AS
BEGIN
    DECLARE @TopDescription INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopDescriptions AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            D.description AS TopDescription,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            expenses I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            descriptions D ON I.description_id = D.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), D.description
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS [Month],
        TopDescription,
        [Count]
    FROM
        MonthlyTopDescriptions
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE OR ALTER PROCEDURE GetTopExpenseDescriptionForEachYear -- Version 1.1.0
AS
BEGIN
    WITH AllYears AS (
        SELECT YEAR(GETDATE()) - 4 AS Year
        UNION ALL
        SELECT Year + 1 FROM AllYears WHERE Year < YEAR(GETDATE())
    ),
    YearlyTopDescriptions AS (
        SELECT 
            YEAR(I.date) AS Year,
            I.description_id,
            D.description,
            COUNT(*) AS DescriptionCount,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            expenses I
        INNER JOIN
            descriptions D ON I.description_id = D.id
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE()))
        GROUP BY
            YEAR(I.date), I.description_id, D.description
    )
    SELECT
        Y.Year,
        ISNULL(YT.description, 'No Data') AS TopDescription,
        ISNULL(YT.DescriptionCount, 0) AS DescriptionCount
    FROM
        AllYears Y
    LEFT JOIN
        YearlyTopDescriptions YT ON Y.Year = YT.Year AND YT.RowNum = 1
    ORDER BY
        Y.Year;
END;

GO

CREATE PROCEDURE GetTopExpenseSupplierByYearly
AS
BEGIN
    ;WITH YearlyTopSuppliers AS (
        SELECT 
            YEAR(I.date) AS Year,
            FT.[text] AS TopSupplier,
            COUNT(*) AS Count,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            expenses I
        INNER JOIN
            from_to_flow FT ON I.from_to_flow_id = FT.id
        GROUP BY
            YEAR(I.date), FT.[text]
    )
    SELECT
        Year,
        TopSupplier,
        Count
    FROM
        YearlyTopSuppliers
    WHERE
        RowNum = 1; 
END;

GO

CREATE PROCEDURE GetTopExpensePaymentMethodByYearly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH YearlyTopPaymentMethods AS (
        SELECT 
            YEAR(I.date) AS Year,
            CF.[text] AS TopPaymentMethod,
            COUNT(*) AS PaymentCount,
            ROW_NUMBER() OVER (PARTITION BY YEAR(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            expenses I
        INNER JOIN
            cash_flow CF ON I.cash_flow_id = CF.id
        WHERE
            YEAR(I.date) >= YEAR(DATEADD(YEAR, -5, GETDATE())) 
        GROUP BY
            YEAR(I.date), CF.[text]
    )
    SELECT
        Year,
        TopPaymentMethod,
        PaymentCount
    FROM
        YearlyTopPaymentMethods
    WHERE
        RowNum = 1; 
END;

GO

CREATE PROCEDURE GetTopExpenseSupplierByMonthly
AS
BEGIN
    DECLARE @TopSupplier INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopSuppliers AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            FTF.[text] AS TopSupplier,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            expenses I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            from_to_flow FTF ON I.from_to_flow_id = FTF.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), FTF.[text]
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS Month,
        TopSupplier,
        [Count]
    FROM
        MonthlyTopSuppliers
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE PROCEDURE GetTopExpensePaymentMethodByMonthly
AS
BEGIN
    DECLARE @TopPaymentMethod INT;

    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    ),
    MonthlyTopPaymentMethods AS (
        SELECT 
            MONTH(I.date) AS MonthNumber,
            CF.[text] AS TopPaymentMethod,
            COUNT(*) AS [Count],
            ROW_NUMBER() OVER (PARTITION BY MONTH(I.date) ORDER BY COUNT(*) DESC) AS RowNum
        FROM
            Months M
        LEFT JOIN
            expenses I ON MONTH(I.date) = M.MonthNumber
        LEFT JOIN
            cash_flow CF ON I.cash_flow_id = CF.id
        WHERE
            YEAR(I.date) = YEAR(GETDATE()) 
        GROUP BY
            MONTH(I.date), CF.[text]
    )
    SELECT
        DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS Month,
        TopPaymentMethod,
        [Count]
    FROM
        MonthlyTopPaymentMethods
    WHERE
        RowNum = 1 
    ORDER BY
        MonthNumber;
END;

GO

CREATE PROCEDURE UpdateUsernameAndName
    @name VARCHAR(25),
    @username VARCHAR(25),
    @currentUserName VARCHAR(25)
AS
BEGIN
    UPDATE users
    SET 
        name = CASE WHEN @name IS NULL OR @name = '' THEN name ELSE @name END,
        username = CASE WHEN @username IS NULL OR @username = '' THEN username ELSE @username END
    WHERE username = @currentUserName;

    SELECT *
    FROM users
    WHERE username = CASE WHEN @username IS NULL OR @username = '' THEN @currentUserName ELSE @username END;
END;

